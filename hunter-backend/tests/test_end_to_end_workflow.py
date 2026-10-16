from unittest.mock import MagicMock, patch

from sqlalchemy import select

from app.main import app as fastapi_app
from app.models.job import Job, JobSource
from app.models.notification import Notification
from app.models.resume import Resume, ResumeVersion
from app.services.ai import get_ai_provider
from app.services.ai.schemas import AITailoringResponse


def _register_and_login(client, email: str) -> dict[str, str]:
    registration = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "password123",
            "full_name": "Workflow User",
        },
    )
    assert registration.status_code == 201
    login = client.post(
        "/auth/login",
        json={"email": email, "password": "password123"},
    )
    assert login.status_code == 200
    return {"Authorization": f"Bearer {login.json()['access_token']}"}


@patch("pypdf.PdfReader")
def test_complete_mock_search_matching_and_notification_workflow(
    mock_pdf_reader, client
):
    """Exercise only real routes and persisted records using deterministic providers."""
    page = MagicMock()
    page.extract_text.return_value = "Python FastAPI PostgreSQL Git developer"
    mock_pdf_reader.return_value = MagicMock(pages=[page])

    headers = _register_and_login(client, "workflow@example.com")

    sources_response = client.get("/job-sources")
    assert sources_response.status_code == 200
    sources = sources_response.json()
    selected_source_id = next(
        source["id"] for source in sources if source["name"] == "Mock Job Source"
    )
    saved_sources = client.put(
        "/job-sources/selected",
        headers=headers,
        json={"source_ids": [selected_source_id]},
    )
    assert saved_sources.status_code == 200
    assert saved_sources.json()["selected_source_ids"] == [selected_source_id]

    preferences = client.put(
        "/preferences",
        headers=headers,
        json={
            "preferred_roles": ["Backend Developer"],
            "job_type": "Full-time",
            "work_mode": "Remote",
            "min_salary": 30000,
            "preferred_locations": ["Remote, India"],
            "min_match_threshold": 60,
        },
    )
    assert preferences.status_code == 200
    assert preferences.json()["min_match_threshold"] == 60

    upload = client.post(
        "/resumes",
        headers=headers,
        files={"file": ("resume.pdf", b"%PDF-1.4 test", "application/pdf")},
    )
    assert upload.status_code == 201
    resume = upload.json()
    assert resume["content_text"] == "Python FastAPI PostgreSQL Git developer"

    versions = client.get(f"/resumes/{resume['id']}/versions", headers=headers)
    assert versions.status_code == 200
    original_version = next(
        version for version in versions.json() if version["version_type"] == "original"
    )
    assert original_version["resume_id"] == resume["id"]

    ingestion = client.post("/jobs/ingest/mock")
    assert ingestion.status_code == 200
    assert ingestion.json()["inserted"] > 0
    jobs = client.get("/jobs?location=Pune&job_type=Full-time").json()
    assert jobs["total"] == 1
    job = jobs["items"][0]
    job_detail = client.get(f"/jobs/{job['id']}")
    assert job_detail.status_code == 200

    match = client.post(
        f"/matches/jobs/{job['id']}",
        headers=headers,
        json={"resume_id": resume["id"]},
    )
    assert match.status_code == 200
    match_data = match.json()
    assert match_data["resume_id"] == resume["id"]
    assert match_data["job_id"] == job["id"]
    assert 0 <= match_data["match_score"] <= 100
    assert set(match_data["matched_skills"]) >= {"Python", "FastAPI"}
    assert "SQLAlchemy" in match_data["missing_skills"]

    analysis = client.post(
        f"/matches/jobs/{job['id']}/analyze",
        headers=headers,
        json={"resume_id": resume["id"]},
    )
    assert analysis.status_code == 200
    assert isinstance(analysis.json()["recommendations"], list)

    tailoring = client.post(
        f"/matches/jobs/{job['id']}/tailor",
        headers=headers,
        json={"resume_id": resume["id"]},
    )
    assert tailoring.status_code == 200
    assert tailoring.json()["tailored_resume"]

    versions_after_tailoring = client.get(
        f"/resumes/{resume['id']}/versions", headers=headers
    )
    tailored_version = next(
        version
        for version in versions_after_tailoring.json()
        if version["version_type"] == "tailored"
        and version["job_id"] == job["id"]
        and version["content_text"] == tailoring.json()["tailored_resume"]
    )

    application = client.post(
        "/applications",
        headers=headers,
        json={
            "job_id": job["id"],
            "resume_version_id": tailored_version["id"],
            "status": "applied",
        },
    )
    assert application.status_code == 201
    application_data = application.json()
    assert application_data["resume_version_id"] == tailored_version["id"]

    status_update = client.patch(
        f"/applications/{application_data['id']}",
        headers=headers,
        json={"status": "interview"},
    )
    assert status_update.status_code == 200
    timeline = client.post(
        f"/applications/{application_data['id']}/timeline",
        headers=headers,
        json={"status": "offer", "note": "Received an offer"},
    )
    assert timeline.status_code == 201
    timeline_items = client.get(
        f"/applications/{application_data['id']}/timeline", headers=headers
    ).json()
    assert {item["status"] for item in timeline_items} >= {
        "applied",
        "interview",
        "offer",
    }

    notifications = client.get("/notifications", headers=headers).json()
    notification_types = {item["notification_type"] for item in notifications["items"]}
    assert {
        "job_match_found",
        "resume_tailored",
        "application_status_changed",
    }.issubset(notification_types)
    unread_before = client.get("/notifications/unread-count", headers=headers).json()[
        "unread_count"
    ]
    notification_id = notifications["items"][0]["id"]
    mark_read = client.patch(f"/notifications/{notification_id}/read", headers=headers)
    assert mark_read.status_code == 200
    assert mark_read.json()["is_read"] is True
    unread_after = client.get("/notifications/unread-count", headers=headers).json()[
        "unread_count"
    ]
    assert unread_after == unread_before - 1


def test_unsafe_tailoring_persists_no_version_or_notification(client, database):
    headers = _register_and_login(client, "unsafe-workflow@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]
    source = JobSource(name="Unsafe tailoring source")
    database.add(source)
    database.flush()
    job = Job(
        title="Backend Developer",
        company="Example Co",
        description="Python development",
        external_url="https://example.com/jobs/unsafe",
        deduplication_key="unsafe-tailoring-job",
        source_id=source.id,
    )
    resume = Resume(
        user_id=user_id,
        filename="resume.pdf",
        file_url="resume.pdf",
        content_text="Python developer",
    )
    database.add_all([job, resume])
    database.commit()

    provider = MagicMock()
    provider.tailor_resume.return_value = AITailoringResponse(
        tailored_resume="Python developer who managed 999 users.",
        changes_made=["Added unsupported metric"],
        warnings=[],
    )
    fastapi_app.dependency_overrides[get_ai_provider] = lambda: provider
    try:
        response = client.post(
            f"/matches/jobs/{job.id}/tailor",
            headers=headers,
            json={"resume_id": resume.id},
        )
        assert response.status_code == 422
    finally:
        fastapi_app.dependency_overrides.pop(get_ai_provider, None)

    versions = database.scalars(
        select(ResumeVersion).where(ResumeVersion.resume_id == resume.id)
    ).all()
    notifications = database.scalars(
        select(Notification).where(Notification.user_id == user_id)
    ).all()
    assert versions == []
    assert notifications == []
