import pytest
from unittest.mock import MagicMock, patch
from sqlalchemy import select

from app.models.job import Job, JobSource, JobSkill
from app.models.resume import Resume, ResumeVersion, ResumeVersionType
from app.models.user import User
from app.services.ai.exceptions import AIRateLimitError
from app.services.ai.schemas import AITailoringResponse
from app.main import app as fastapi_app
from app.services.ai import get_ai_provider


def create_auth_header(client, email="version_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Version User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}


# 1. Original version creation after successful resume upload/extraction
@patch("app.api.routes.resumes.extract_text_from_file", return_value="Extracted mock text content")
def test_original_version_created_on_upload(mock_extract, client, database):
    headers = create_auth_header(client, "upload_user@example.com")
    res = client.post(
        "/resumes",
        headers=headers,
        files={"file": ("my_resume.pdf", b"%PDF-1.4 mock content", "application/pdf")}
    )
    assert res.status_code == 201
    resume_data = res.json()
    resume_id = resume_data["id"]

    # Verify original version in DB
    versions = list(database.scalars(
        select(ResumeVersion).where(ResumeVersion.resume_id == resume_id)
    ).all())
    assert len(versions) == 1
    assert versions[0].version_type == "original"
    assert versions[0].job_id is None
    assert versions[0].content_text == "Extracted mock text content"


# 2. No original version on failed extraction
@patch("app.api.routes.resumes.extract_text_from_file")
def test_no_original_version_on_failed_extraction(mock_extract, client, database):
    from app.services.resume_extractor import ResumeExtractionError
    mock_extract.side_effect = ResumeExtractionError("Extraction failed")

    headers = create_auth_header(client, "fail_extract_user@example.com")
    res = client.post(
        "/resumes",
        headers=headers,
        files={"file": ("corrupt.pdf", b"corrupt bytes", "application/pdf")}
    )
    assert res.status_code == 400

    # Verify no Resume or ResumeVersion created
    assert database.scalar(select(ResumeVersion)) is None
    assert database.scalar(select(Resume)) is None


# 3. Resume replacement behavior
@patch("app.api.routes.resumes.extract_text_from_file", return_value="Extracted mock text content")
def test_resume_replacement_creates_new_original_version(mock_extract, client, database):
    headers = create_auth_header(client, "replace_user@example.com")
    res1 = client.post(
        "/resumes",
        headers=headers,
        files={"file": ("v1.pdf", b"%PDF-1.4 v1 content", "application/pdf")}
    )
    resume_id = res1.json()["id"]

    res2 = client.put(
        f"/resumes/{resume_id}",
        headers=headers,
        files={"file": ("v2.pdf", b"%PDF-1.4 v2 content", "application/pdf")}
    )
    assert res2.status_code == 200

    versions = list(database.scalars(
        select(ResumeVersion)
        .where(ResumeVersion.resume_id == resume_id)
        .order_by(ResumeVersion.created_at.asc())
    ).all())
    assert len(versions) == 2
    assert all(v.version_type == "original" for v in versions)


# 4, 5, 6, 7, 8, 9. Tailored version persistence, original content unchanged, content/changes/warnings/job_id persisted
def test_tailored_version_persistence_and_attributes(client, database):
    headers = create_auth_header(client, "tailor_persist_user@example.com")
    user_me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Tailor Persist Source")
    database.add(source)
    database.flush()

    job = Job(
        title="Python Dev",
        company="Acme Corp",
        description="Needs Python FastAPI",
        external_url="http://example.com/job_tailor",
        deduplication_key="key_tailor_persist",
        source_id=source.id
    )
    database.add(job)

    original_text = "Experienced with Python and REST APIs."
    resume = Resume(
        user_id=user_me["id"],
        filename="original.pdf",
        file_url="url.pdf",
        content_text=original_text
    )
    database.add(resume)
    database.commit()

    res = client.post(
        f"/matches/jobs/{job.id}/tailor",
        headers=headers,
        json={"resume_id": resume.id}
    )
    assert res.status_code == 200

    # 5. Original Resume.content_text remains unchanged
    db_resume = database.get(Resume, resume.id)
    assert db_resume.content_text == original_text

    # 4, 6, 7, 8, 9. Tailored version attributes
    versions = list(database.scalars(
        select(ResumeVersion)
        .where(ResumeVersion.resume_id == resume.id, ResumeVersion.version_type == "tailored")
    ).all())
    assert len(versions) == 1
    v = versions[0]
    assert v.job_id == job.id  # 9. Job association
    assert v.content_text == res.json()["tailored_resume"]  # 6. Tailored content
    assert v.changes_made == res.json()["changes_made"]  # 7. changes_made persistence
    assert v.warnings == res.json()["warnings"]  # 8. warnings persistence


# 10, 11, 12, 13, 14. Listing, retrieval, auth protection, ownership protection, version isolation
def test_version_listing_and_retrieval_and_security(client, database):
    headers_owner = create_auth_header(client, "v_owner@example.com")
    headers_other = create_auth_header(client, "v_other@example.com")

    user_owner_id = client.get("/users/me", headers=headers_owner).json()["id"]

    resume = Resume(
        user_id=user_owner_id,
        filename="resume.pdf",
        file_url="file.pdf",
        content_text="Owner resume text"
    )
    database.add(resume)
    database.flush()

    version1 = ResumeVersion(
        resume_id=resume.id,
        user_id=user_owner_id,
        version_type="original",
        content_text="Owner resume text"
    )
    version2 = ResumeVersion(
        resume_id=resume.id,
        user_id=user_owner_id,
        version_type="tailored",
        content_text="Tailored resume text"
    )
    database.add_all([version1, version2])
    database.commit()

    # 12. Unauthenticated protection
    assert client.get(f"/resumes/{resume.id}/versions").status_code == 401
    assert client.get(f"/resumes/{resume.id}/versions/{version1.id}").status_code == 401

    # 13, 14. Ownership protection and version isolation
    assert client.get(f"/resumes/{resume.id}/versions", headers=headers_other).status_code == 403
    assert client.get(f"/resumes/{resume.id}/versions/{version1.id}", headers=headers_other).status_code == 403

    # 10. Listing for owner
    list_res = client.get(f"/resumes/{resume.id}/versions", headers=headers_owner)
    assert list_res.status_code == 200
    items = list_res.json()
    assert len(items) == 2

    # 11. Individual retrieval for owner
    get_res = client.get(f"/resumes/{resume.id}/versions/{version1.id}", headers=headers_owner)
    assert get_res.status_code == 200
    assert get_res.json()["id"] == version1.id
    assert get_res.json()["version_type"] == "original"


# 15, 16. Invalid resume / Invalid job
def test_tailoring_invalid_resume_or_job(client, database):
    headers = create_auth_header(client, "invalid_tailor_user@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    source = JobSource(name="Invalid Tailor Source")
    database.add(source)
    database.flush()

    job = Job(
        title="Dev", company="Co", external_url="http://example.com/job_inv",
        deduplication_key="key_inv", source_id=source.id
    )
    resume = Resume(user_id=user_id, filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.commit()

    # Invalid resume ID
    res_bad_resume = client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": "nonexistent_resume"})
    assert res_bad_resume.status_code == 404

    # Invalid job ID
    res_bad_job = client.post("/matches/jobs/nonexistent_job/tailor", headers=headers, json={"resume_id": resume.id})
    assert res_bad_job.status_code == 404

    # Verify no tailored versions were created
    versions = list(database.scalars(select(ResumeVersion).where(ResumeVersion.version_type == "tailored")).all())
    assert len(versions) == 0


# 17. Failed AI tailoring does not create a version
def test_failed_ai_provider_creates_no_version(client, database):
    headers = create_auth_header(client, "ai_fail_user@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    source = JobSource(name="AI Fail Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/ai_fail", deduplication_key="k_ai_fail", source_id=source.id)
    resume = Resume(user_id=user_id, filename="r.pdf", file_url="u.pdf", content_text="Software engineer")
    database.add_all([job, resume])
    database.commit()

    mock_failing_provider = MagicMock()
    mock_failing_provider.tailor_resume.side_effect = AIRateLimitError("Rate limit exceeded")

    fastapi_app.dependency_overrides[get_ai_provider] = lambda: mock_failing_provider
    try:
        res = client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": resume.id})
        assert res.status_code == 500

        # Verify no tailored version was saved
        versions = list(database.scalars(select(ResumeVersion).where(ResumeVersion.resume_id == resume.id, ResumeVersion.version_type == "tailored")).all())
        assert len(versions) == 0
    finally:
        fastapi_app.dependency_overrides.pop(get_ai_provider, None)


# 18. Failed anti-fabrication validation does not create a version
def test_failed_safety_validation_creates_no_version(client, database):
    headers = create_auth_header(client, "safety_fail_user@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    source = JobSource(name="Safety Fail Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/s_fail", deduplication_key="k_s_fail", source_id=source.id)
    resume = Resume(user_id=user_id, filename="r.pdf", file_url="u.pdf", content_text="Software engineer")
    database.add_all([job, resume])
    database.commit()

    mock_unsafe_provider = MagicMock()
    mock_unsafe_provider.tailor_resume.return_value = AITailoringResponse(
        tailored_resume="Software engineer leading 1,000,000 users.",
        changes_made=["Added scale"],
        warnings=[]
    )

    fastapi_app.dependency_overrides[get_ai_provider] = lambda: mock_unsafe_provider
    try:
        res = client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": resume.id})
        assert res.status_code == 422

        # Verify no version created
        versions = list(database.scalars(select(ResumeVersion).where(ResumeVersion.resume_id == resume.id, ResumeVersion.version_type == "tailored")).all())
        assert len(versions) == 0
    finally:
        fastapi_app.dependency_overrides.pop(get_ai_provider, None)


# 19. Repeated tailoring behavior according to chosen versioning strategy (immutable history)
def test_repeated_tailoring_creates_distinct_immutable_versions(client, database):
    headers = create_auth_header(client, "repeat_tailor_user@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    source = JobSource(name="Repeat Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/repeat", deduplication_key="k_repeat", source_id=source.id)
    resume = Resume(user_id=user_id, filename="r.pdf", file_url="u.pdf", content_text="Python engineer")
    database.add_all([job, resume])
    database.commit()

    res1 = client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": resume.id})
    res2 = client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": resume.id})
    assert res1.status_code == 200
    assert res2.status_code == 200

    tailored_versions = list(database.scalars(
        select(ResumeVersion)
        .where(ResumeVersion.resume_id == resume.id, ResumeVersion.version_type == "tailored")
        .order_by(ResumeVersion.created_at.desc())
    ).all())
    assert len(tailored_versions) == 2
    assert tailored_versions[0].id != tailored_versions[1].id


# 20. Foreign key integrity test
def test_foreign_key_cascade_deletion(database):
    user = User(email="cascade@example.com", hashed_password="pw", full_name="Cascade User")
    database.add(user)
    database.flush()

    resume = Resume(user_id=user.id, filename="c.pdf", file_url="c.pdf", content_text="Cascade text")
    database.add(resume)
    database.flush()

    version = ResumeVersion(resume_id=resume.id, user_id=user.id, version_type="original", content_text="Cascade text")
    database.add(version)
    database.commit()

    # Delete resume and verify version is deleted via cascade
    database.delete(resume)
    database.commit()

    assert database.get(ResumeVersion, version.id) is None
