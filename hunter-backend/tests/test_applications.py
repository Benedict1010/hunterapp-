from datetime import datetime, timezone
import pytest
from sqlalchemy import select

from app.models.application import Application, ApplicationStatus
from app.models.job import Job, JobSource
from app.models.resume import Resume, ResumeVersion, ResumeVersionType
from app.models.user import User


def create_auth_header(client, email="app_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Application User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}


def setup_user_job_resume(database, user_email="app_owner@example.com", key_suffix="1"):
    user = User(email=user_email, hashed_password="hashed_pw", full_name="App Owner")
    database.add(user)
    database.flush()

    source = JobSource(name=f"Source {key_suffix}")
    database.add(source)
    database.flush()

    job = Job(
        title=f"Software Engineer {key_suffix}",
        company="Acme Corp",
        location="Remote",
        description="Write code",
        external_url=f"http://example.com/job_{key_suffix}",
        deduplication_key=f"dedup_key_{key_suffix}",
        source_id=source.id,
    )
    database.add(job)
    database.flush()

    resume = Resume(
        user_id=user.id,
        filename="my_resume.pdf",
        file_url="url.pdf",
        content_text="Resume content",
        is_primary=True,
    )
    database.add(resume)
    database.flush()

    resume_version = ResumeVersion(
        resume_id=resume.id,
        user_id=user.id,
        job_id=job.id,
        version_type=ResumeVersionType.ORIGINAL.value,
        content_text="Resume version content",
    )
    database.add(resume_version)
    database.commit()

    return user, job, resume, resume_version


# 1, 2, 3, 4, 17, 18. Creation, defaults, job ref, resume version ref, url/source, timestamps
def test_create_application_success(client, database):
    headers = create_auth_header(client, "create_app_user@example.com")
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Create App Source")
    database.add(source)
    database.flush()

    job = Job(
        title="Backend Dev",
        company="Tech Corp",
        location="Remote",
        external_url="http://example.com/create_app_job",
        deduplication_key="dedup_create_app",
        source_id=source.id,
    )
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()

    version = ResumeVersion(
        resume_id=resume.id,
        user_id=me["id"],
        version_type="original",
        content_text="Text",
    )
    database.add(version)
    database.commit()

    payload = {
        "job_id": job.id,
        "resume_version_id": version.id,
        "application_url": "https://company.com/jobs/123/apply",
        "source": "LinkedIn",
    }
    res = client.post("/applications", headers=headers, json=payload)
    assert res.status_code == 201
    data = res.json()

    # 1. Created successfully
    assert data["id"] is not None
    assert data["user_id"] == me["id"]
    # 2. Defaults to "applied" status
    assert data["status"] == "applied"
    # 3. References correct job
    assert data["job_id"] == job.id
    assert data["job"]["title"] == "Backend Dev"
    assert data["job"]["company"] == "Tech Corp"
    # 4. References exact ResumeVersion
    assert data["resume_version_id"] == version.id
    # 17. Application URL/source work
    assert data["application_url"] == "https://company.com/jobs/123/apply"
    assert data["source"] == "linkedin"
    # 18. Timestamps persisted
    assert data["created_at"] is not None
    assert data["updated_at"] is not None
    assert data["applied_at"] is not None


# 5. Application list returns only current user's applications
def test_list_applications_user_isolation(client, database):
    headers1 = create_auth_header(client, "user1_app@example.com")
    headers2 = create_auth_header(client, "user2_app@example.com")

    me1 = client.get("/users/me", headers=headers1).json()

    source = JobSource(name="List App Source")
    database.add(source)
    database.flush()
    job = Job(
        title="Dev", company="Co", external_url="http://example.com/list_job", deduplication_key="k_list", source_id=source.id
    )
    resume = Resume(user_id=me1["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()
    version = ResumeVersion(resume_id=resume.id, user_id=me1["id"], version_type="original", content_text="Text")
    database.add(version)
    database.commit()

    # User 1 creates an application
    res_create = client.post("/applications", headers=headers1, json={"job_id": job.id, "resume_version_id": version.id})
    assert res_create.status_code == 201

    # User 1 lists applications
    res1 = client.get("/applications", headers=headers1)
    assert res1.status_code == 200
    assert len(res1.json()) == 1

    # User 2 lists applications -> empty
    res2 = client.get("/applications", headers=headers2)
    assert res2.status_code == 200
    assert len(res2.json()) == 0


# 6. Application detail works for owner
def test_get_application_detail(client, database):
    headers = create_auth_header(client, "detail_owner@example.com")
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Detail Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/detail", deduplication_key="k_detail", source_id=source.id)
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()
    version = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text")
    database.add(version)
    database.commit()

    created = client.post("/applications", headers=headers, json={"job_id": job.id, "resume_version_id": version.id}).json()

    res = client.get(f"/applications/{created['id']}", headers=headers)
    assert res.status_code == 200
    assert res.json()["id"] == created["id"]


# 7, 8. Owner can update status and metadata
def test_update_application_status_and_metadata(client, database):
    headers = create_auth_header(client, "update_owner@example.com")
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Update Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/update", deduplication_key="k_update", source_id=source.id)
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()
    version = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text")
    database.add(version)
    database.commit()

    created = client.post("/applications", headers=headers, json={"job_id": job.id, "resume_version_id": version.id}).json()

    # 7. Update status
    res_status = client.patch(f"/applications/{created['id']}", headers=headers, json={"status": "interview"})
    assert res_status.status_code == 200
    assert res_status.json()["status"] == "interview"

    # 8. Update metadata
    res_meta = client.patch(
        f"/applications/{created['id']}",
        headers=headers,
        json={"application_url": "https://new.url", "source": "Referral"},
    )
    assert res_meta.status_code == 200
    assert res_meta.json()["application_url"] == "https://new.url"
    assert res_meta.json()["source"] == "referral"


# 9, 10. User cannot change job_id or resume_version_id through update
def test_update_cannot_change_job_id_or_resume_version_id(client, database):
    headers = create_auth_header(client, "immut_owner@example.com")
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Immut Source")
    database.add(source)
    database.flush()
    job1 = Job(title="Dev 1", company="Co", external_url="http://example.com/imm1", deduplication_key="k_imm1", source_id=source.id)
    job2 = Job(title="Dev 2", company="Co", external_url="http://example.com/imm2", deduplication_key="k_imm2", source_id=source.id)
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job1, job2, resume])
    database.flush()
    version1 = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text 1")
    version2 = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="tailored", content_text="Text 2")
    database.add_all([version1, version2])
    database.commit()

    created = client.post("/applications", headers=headers, json={"job_id": job1.id, "resume_version_id": version1.id}).json()

    # Attempt to change job_id and resume_version_id via PATCH
    res = client.patch(
        f"/applications/{created['id']}",
        headers=headers,
        json={"job_id": job2.id, "resume_version_id": version2.id, "status": "viewed"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["job_id"] == job1.id  # Unchanged
    assert data["resume_version_id"] == version1.id  # Unchanged
    assert data["status"] == "viewed"  # Status was updated


# 11. Unauthenticated requests are rejected
def test_unauthenticated_requests_rejected(client):
    assert client.get("/applications").status_code == 401
    assert client.post("/applications", json={"job_id": "j", "resume_version_id": "r"}).status_code == 401
    assert client.get("/applications/some_id").status_code == 401
    assert client.patch("/applications/some_id", json={"status": "viewed"}).status_code == 401


# 12. User cannot create an application with another user's ResumeVersion
def test_cannot_create_application_with_other_user_resume_version(client, database):
    headers1 = create_auth_header(client, "user_rv1@example.com")
    headers2 = create_auth_header(client, "user_rv2@example.com")

    me1 = client.get("/users/me", headers=headers1).json()
    me2 = client.get("/users/me", headers=headers2).json()

    source = JobSource(name="RV Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/rv", deduplication_key="k_rv", source_id=source.id)
    resume2 = Resume(user_id=me2["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume2])
    database.flush()
    version2 = ResumeVersion(resume_id=resume2.id, user_id=me2["id"], version_type="original", content_text="User 2 Version")
    database.add(version2)
    database.commit()

    # User 1 tries to use User 2's resume version
    res = client.post("/applications", headers=headers1, json={"job_id": job.id, "resume_version_id": version2.id})
    assert res.status_code in (400, 403)


# 13. User cannot access another user's Application
def test_cannot_access_other_user_application(client, database):
    headers1 = create_auth_header(client, "app_owner_13@example.com")
    headers2 = create_auth_header(client, "app_other_13@example.com")

    me1 = client.get("/users/me", headers=headers1).json()

    source = JobSource(name="Access Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/acc", deduplication_key="k_acc", source_id=source.id)
    resume = Resume(user_id=me1["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()
    version = ResumeVersion(resume_id=resume.id, user_id=me1["id"], version_type="original", content_text="Text")
    database.add(version)
    database.commit()

    app_obj = client.post("/applications", headers=headers1, json={"job_id": job.id, "resume_version_id": version.id}).json()

    # User 2 tries GET detail
    res_get = client.get(f"/applications/{app_obj['id']}", headers=headers2)
    assert res_get.status_code == 403

    # User 2 tries PATCH
    res_patch = client.patch(f"/applications/{app_obj['id']}", headers=headers2, json={"status": "rejected"})
    assert res_patch.status_code == 403


# 14, 15, 16. Invalid job ID, invalid resume version ID, invalid status
def test_invalid_references_and_status(client, database):
    headers = create_auth_header(client, "invalid_ref_user@example.com")
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Invalid Ref Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="Co", external_url="http://example.com/inv_ref", deduplication_key="k_inv_ref", source_id=source.id)
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()
    version = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text")
    database.add(version)
    database.commit()

    # 14. Invalid job ID
    res_bad_job = client.post("/applications", headers=headers, json={"job_id": "nonexistent_job", "resume_version_id": version.id})
    assert res_bad_job.status_code == 404

    # 15. Invalid resume version ID
    res_bad_rv = client.post("/applications", headers=headers, json={"job_id": job.id, "resume_version_id": "nonexistent_rv"})
    assert res_bad_rv.status_code == 404

    # 16. Invalid status
    res_bad_status = client.post("/applications", headers=headers, json={"job_id": job.id, "resume_version_id": version.id, "status": "invalid_status_value"})
    assert res_bad_status.status_code == 422


# 19. Multiple applications can be created for different jobs
def test_multiple_applications_different_jobs(client, database):
    headers = create_auth_header(client, "multi_app_user@example.com")
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="Multi App Source")
    database.add(source)
    database.flush()
    job1 = Job(title="Dev 1", company="Co 1", external_url="http://example.com/m1", deduplication_key="k_m1", source_id=source.id)
    job2 = Job(title="Dev 2", company="Co 2", external_url="http://example.com/m2", deduplication_key="k_m2", source_id=source.id)
    resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job1, job2, resume])
    database.flush()
    version = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text")
    database.add(version)
    database.commit()

    app1 = client.post("/applications", headers=headers, json={"job_id": job1.id, "resume_version_id": version.id}).json()
    app2 = client.post("/applications", headers=headers, json={"job_id": job2.id, "resume_version_id": version.id}).json()

    assert app1["id"] != app2["id"]

    res_list = client.get("/applications", headers=headers)
    assert res_list.status_code == 200
    items = res_list.json()
    assert len(items) == 2


import sqlalchemy as sa


# 20. Database constraints behave correctly (foreign key cascades)
def test_application_database_cascade_delete(database):
    if database.bind.dialect.name == "sqlite":
        database.execute(sa.text("PRAGMA foreign_keys=ON"))

    user, job, resume, resume_version = setup_user_job_resume(database, "cascade_app@example.com", "cascade")

    application = Application(
        user_id=user.id,
        job_id=job.id,
        resume_version_id=resume_version.id,
        status="applied",
    )
    database.add(application)
    database.commit()

    app_id = application.id

    # Delete job -> application deleted via cascade
    database.delete(job)
    database.commit()

    assert database.get(Application, app_id) is None
