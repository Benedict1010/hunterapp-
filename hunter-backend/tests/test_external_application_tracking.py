from datetime import datetime, timezone
import pytest
from sqlalchemy import select

from app.models.application import Application, ApplicationStatus
from app.models.application_timeline import ApplicationTimeline
from app.models.job import Job, JobSource
from app.models.resume import Resume, ResumeVersion
from app.models.user import User


def create_auth_header(client, email="ext_track_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "External Tracking User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}


def setup_test_context(client, database, email="ext_owner@example.com", key_suffix="ext"):
    headers = create_auth_header(client, email)
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name=f"Job Source {key_suffix}")
    database.add(source)
    database.flush()

    job = Job(
        title=f"Engineer {key_suffix}",
        company="Acme Inc",
        location="Remote",
        external_url=f"http://example.com/job_{key_suffix}",
        deduplication_key=f"k_ext_{key_suffix}",
        source_id=source.id,
    )
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()

    version = ResumeVersion(
        resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text"
    )
    database.add(version)
    database.commit()

    return headers, me["id"], job, version


# 1. Valid HTTPS application URL accepted
def test_valid_https_url_accepted(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "https_url@example.com", "https")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "https://careers.company.com/apply/123",
        "source": "LinkedIn",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 201
    assert res.json()["application_url"] == "https://careers.company.com/apply/123"


# 2. Valid HTTP application URL accepted
def test_valid_http_url_accepted(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "http_url@example.com", "http")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "http://jobs.example.org/apply/456",
        "source": "Naukri",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 201
    assert res.json()["application_url"] == "http://jobs.example.org/apply/456"


# 3. Malformed URL rejected
def test_malformed_url_rejected(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "malformed_url@example.com", "malformed")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "ht tp://bad_url",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 422


# 4. javascript: URL rejected
def test_javascript_url_rejected(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "js_url@example.com", "js")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "javascript:alert('xss')",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 422


# 5. data: URL rejected
def test_data_url_rejected(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "data_url@example.com", "data")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "data:text/html,<script>alert(1)</script>",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 422


# 6. file: URL rejected
def test_file_url_rejected(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "file_url@example.com", "file")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "file:///etc/passwd",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 422


# 7. Application URL can be omitted
def test_application_url_can_be_omitted(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "omit_url@example.com", "omit")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 201
    assert res.json()["application_url"] is None


# 8. Source is stored and normalized correctly
def test_source_stored_and_normalized(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "norm_source@example.com", "norm")
    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "source": "  LinkedIn  ",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 201
    assert res.json()["source"] == "linkedin"


# 9. Source can be updated
def test_source_can_be_updated(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "upd_source@example.com", "upd_src")
    created = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job.id, "resume_version_id": version.id, "source": "linkedin"},
    ).json()

    res = client.patch(
        f"/applications/{created['id']}",
        headers=headers,
        json={"source": "  Unstop  "},
    )
    assert res.status_code == 200
    assert res.json()["source"] == "unstop"


# 10. Application URL can be updated
def test_application_url_can_be_updated(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "upd_url@example.com", "upd_url")
    created = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job.id, "resume_version_id": version.id, "application_url": "https://old.com/apply"},
    ).json()

    # Valid update
    res = client.patch(
        f"/applications/{created['id']}",
        headers=headers,
        json={"application_url": "https://new.com/apply"},
    )
    assert res.status_code == 200
    assert res.json()["application_url"] == "https://new.com/apply"

    # Invalid update rejected
    res_bad = client.patch(
        f"/applications/{created['id']}",
        headers=headers,
        json={"application_url": "invalid_url"},
    )
    assert res_bad.status_code == 422


# 11, 12. Ownership is enforced; another user cannot modify external tracking info
def test_ownership_enforcement_and_unauthorized_modification(client, database):
    headers1, u1_id, job1, v1 = setup_test_context(client, database, "owner1@example.com", "o1")
    headers2, u2_id, job2, v2 = setup_test_context(client, database, "owner2@example.com", "o2")

    created = client.post(
        "/applications",
        headers=headers1,
        json={"job_id": job1.id, "resume_version_id": v1.id, "application_url": "https://company.com/apply"},
    ).json()

    # User 2 tries to PATCH user 1's application
    res_patch = client.patch(
        f"/applications/{created['id']}",
        headers=headers2,
        json={"application_url": "https://hacked.com", "source": "hacked"},
    )
    assert res_patch.status_code == 403

    # Verify original app unchanged
    res_get = client.get(f"/applications/{created['id']}", headers=headers1)
    assert res_get.json()["application_url"] == "https://company.com/apply"


# 13. Metadata-only changes do not create timeline events
def test_metadata_only_changes_do_not_create_timeline_events(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "meta_tl@example.com", "meta_tl")
    created = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job.id, "resume_version_id": version.id, "application_url": "https://initial.com/apply"},
    ).json()

    app_id = created["id"]
    initial_events = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(initial_events) == 1

    # Update metadata only
    patch_res = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"application_url": "https://updated.com/apply", "source": "naukri"},
    )
    assert patch_res.status_code == 200

    after_events = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(after_events) == 1


# 14. Status changes still create exactly one timeline event
def test_status_changes_create_exactly_one_timeline_event(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "status_tl@example.com", "status_tl")
    created = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job.id, "resume_version_id": version.id},
    ).json()

    app_id = created["id"]
    patch_res = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"status": "interview", "application_url": "https://company.com/apply"},
    )
    assert patch_res.status_code == 200

    events = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(events) == 2
    assert events[0]["status"] == "interview"


# 15, 16. job_id and resume_version_id remain immutable
def test_job_id_and_resume_version_id_remain_immutable(client, database):
    headers, user_id, job1, v1 = setup_test_context(client, database, "immut_fields@example.com", "imm_fields")

    job2 = Job(
        title="Other Job",
        company="Other Co",
        external_url="http://example.com/other",
        deduplication_key="k_other",
        source_id=job1.source_id,
    )
    resume2 = Resume(user_id=user_id, filename="r2.pdf", file_url="u2.pdf", content_text="Text 2")
    database.add_all([job2, resume2])
    database.flush()
    v2 = ResumeVersion(resume_id=resume2.id, user_id=user_id, version_type="tailored", content_text="Text 2")
    database.add(v2)
    database.commit()

    created = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job1.id, "resume_version_id": v1.id},
    ).json()

    res = client.patch(
        f"/applications/{created['id']}",
        headers=headers,
        json={"job_id": job2.id, "resume_version_id": v2.id, "source": "company_site"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["job_id"] == job1.id
    assert data["resume_version_id"] == v1.id
    assert data["source"] == "company_site"


# 17. External-link endpoint returns URL and source for owner
def test_external_link_returns_url_for_owner(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "ext_link_owner@example.com", "ext_link_o")
    created = client.post(
        "/applications",
        headers=headers,
        json={
            "job_id": job.id,
            "resume_version_id": version.id,
            "application_url": "https://company.com/jobs/999/apply",
            "source": "internshala",
        },
    ).json()

    res = client.get(f"/applications/{created['id']}/external-link", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["application_id"] == created["id"]
    assert data["application_url"] == "https://company.com/jobs/999/apply"
    assert data["source"] == "internshala"


# 18. External-link endpoint rejects another user's application
def test_external_link_rejects_other_user(client, database):
    headers1, u1_id, job1, v1 = setup_test_context(client, database, "ext_link_u1@example.com", "ext_link_u1")
    headers2, u2_id, job2, v2 = setup_test_context(client, database, "ext_link_u2@example.com", "ext_link_u2")

    created = client.post(
        "/applications",
        headers=headers1,
        json={
            "job_id": job1.id,
            "resume_version_id": v1.id,
            "application_url": "https://company.com/apply",
        },
    ).json()

    res = client.get(f"/applications/{created['id']}/external-link", headers=headers2)
    assert res.status_code == 403


# 19. External-link endpoint handles missing URL appropriately
def test_external_link_missing_url_returns_404(client, database):
    headers, user_id, job, version = setup_test_context(client, database, "ext_link_no_url@example.com", "ext_link_nourl")
    created = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job.id, "resume_version_id": version.id},
    ).json()

    res = client.get(f"/applications/{created['id']}/external-link", headers=headers)
    assert res.status_code == 404
    assert "not found" in res.json()["detail"].lower()
