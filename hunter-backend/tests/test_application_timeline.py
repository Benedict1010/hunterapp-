from datetime import datetime, timezone
from unittest.mock import patch
import pytest
import sqlalchemy as sa
from sqlalchemy import select

from app.models.application import Application, ApplicationStatus
from app.models.application_timeline import ApplicationTimeline
from app.models.job import Job, JobSource
from app.models.resume import Resume, ResumeVersion, ResumeVersionType
from app.models.user import User


def create_auth_header(client, email="timeline_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Timeline User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}


def setup_application(client, database, email="timeline_owner@example.com", key_suffix="1"):
    headers = create_auth_header(client, email)
    me = client.get("/users/me", headers=headers).json()

    source = JobSource(name=f"Timeline Source {key_suffix}")
    database.add(source)
    database.flush()

    job = Job(
        title=f"Engineer {key_suffix}",
        company="Tech Corp",
        location="Remote",
        external_url=f"http://example.com/job_{key_suffix}",
        deduplication_key=f"k_time_{key_suffix}",
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

    app_res = client.post(
        "/applications",
        headers=headers,
        json={"job_id": job.id, "resume_version_id": version.id, "status": "applied"},
    )
    app_data = app_res.json()
    return headers, me["id"], job, version, app_data


# 1, 2, 3. Automatic initial timeline event creation, status, and application belonging
def test_automatic_initial_timeline_event(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "auto_init@example.com", "init")

    app_id = app_data["id"]

    # Verify initial timeline event created in DB
    events = list(
        database.scalars(
            select(ApplicationTimeline).where(ApplicationTimeline.application_id == app_id)
        ).all()
    )
    assert len(events) == 1
    # 2. Correct initial status
    assert events[0].status == "applied"
    # 3. Belongs to correct application
    assert events[0].application_id == app_id


# 4, 5. GET timeline returns events and is newest-first
def test_list_timeline_events_newest_first(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "list_time@example.com", "list")
    app_id = app_data["id"]

    # Add second timeline event
    post_res1 = client.post(
        f"/applications/{app_id}/timeline",
        headers=headers,
        json={"status": "viewed", "note": "Recruiter viewed"},
    )
    assert post_res1.status_code == 201

    # Add third timeline event
    post_res2 = client.post(
        f"/applications/{app_id}/timeline",
        headers=headers,
        json={"status": "interview", "note": "Scheduled round 1"},
    )
    assert post_res2.status_code == 201

    # 4. GET timeline
    list_res = client.get(f"/applications/{app_id}/timeline", headers=headers)
    assert list_res.status_code == 200
    items = list_res.json()
    assert len(items) == 3

    # 5. Ordered newest first
    assert items[0]["status"] == "interview"
    assert items[1]["status"] == "viewed"
    assert items[2]["status"] == "applied"


# 6. GET timeline detail works
def test_get_timeline_detail(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "detail_time@example.com", "detail")
    app_id = app_data["id"]

    list_res = client.get(f"/applications/{app_id}/timeline", headers=headers)
    timeline_id = list_res.json()[0]["id"]

    detail_res = client.get(f"/applications/{app_id}/timeline/{timeline_id}", headers=headers)
    assert detail_res.status_code == 200
    assert detail_res.json()["id"] == timeline_id
    assert detail_res.json()["application_id"] == app_id


# 7, 8, 9, 21, 22. Unauthenticated requests, unauthorized user, and IDOR protection
def test_timeline_security_and_authorization(client, database):
    headers1, user1_id, job1, v1, app1_data = setup_application(client, database, "sec_user1@example.com", "sec1")
    headers2, user2_id, job2, v2, app2_data = setup_application(client, database, "sec_user2@example.com", "sec2")

    app1_id = app1_data["id"]
    app2_id = app2_data["id"]

    # Get user 1's timeline event ID
    list_res1 = client.get(f"/applications/{app1_id}/timeline", headers=headers1)
    t1_id = list_res1.json()[0]["id"]

    # Get user 2's timeline event ID
    list_res2 = client.get(f"/applications/{app2_id}/timeline", headers=headers2)
    t2_id = list_res2.json()[0]["id"]

    # 7. Unauthenticated rejected
    assert client.get(f"/applications/{app1_id}/timeline").status_code == 401
    assert client.post(f"/applications/{app1_id}/timeline", json={"status": "viewed"}).status_code == 401
    assert client.get(f"/applications/{app1_id}/timeline/{t1_id}").status_code == 401

    # 8. User 2 cannot access User 1's application timeline
    assert client.get(f"/applications/{app1_id}/timeline", headers=headers2).status_code == 403
    assert client.post(f"/applications/{app1_id}/timeline", headers=headers2, json={"status": "viewed"}).status_code == 403

    # 9. User 2 cannot access User 1's timeline event detail
    assert client.get(f"/applications/{app1_id}/timeline/{t1_id}", headers=headers2).status_code == 403

    # 22. IDOR: User 1 tries to pass User 2's timeline_id with User 1's application_id
    res_idor = client.get(f"/applications/{app1_id}/timeline/{t2_id}", headers=headers1)
    assert res_idor.status_code == 404


# 10, 11, 12, 13. POST timeline event creates event, updates status, transactionally, preserves history
def test_post_timeline_event_updates_status_transactionally(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "post_time@example.com", "post")
    app_id = app_data["id"]

    # 10. POST timeline event
    post_res = client.post(
        f"/applications/{app_id}/timeline",
        headers=headers,
        json={"status": "interview", "note": "Round 1 interview"},
    )
    assert post_res.status_code == 201
    data = post_res.json()
    assert data["status"] == "interview"
    assert data["note"] == "Round 1 interview"

    # 11. Application.status is updated to "interview"
    app_res = client.get(f"/applications/{app_id}", headers=headers)
    assert app_res.json()["status"] == "interview"

    # 13. Previous timeline events remain unchanged
    list_res = client.get(f"/applications/{app_id}/timeline", headers=headers)
    events = list_res.json()
    assert len(events) == 2
    assert events[0]["status"] == "interview"
    assert events[1]["status"] == "applied"


# 14, 15, 16. PATCH application status creates timeline event, metadata-only does not, same status does not
def test_patch_application_timeline_behavior(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "patch_time@example.com", "patch")
    app_id = app_data["id"]

    # 15. PATCH application metadata without status change does NOT create timeline event
    patch_meta = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"application_url": "https://company.com/job/123", "source": "LinkedIn"},
    )
    assert patch_meta.status_code == 200
    t_list1 = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(t_list1) == 1  # Only initial event

    # 16. PATCH status with same existing status does NOT create duplicate event
    patch_same = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"status": "applied"},
    )
    assert patch_same.status_code == 200
    t_list2 = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(t_list2) == 1

    # 14. PATCH application status creates timeline event
    patch_status = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"status": "viewed"},
    )
    assert patch_status.status_code == 200
    t_list3 = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(t_list3) == 2
    assert t_list3[0]["status"] == "viewed"


# 17. Invalid status is rejected
def test_invalid_status_rejected(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "inv_status@example.com", "inv")
    app_id = app_data["id"]

    res = client.post(
        f"/applications/{app_id}/timeline",
        headers=headers,
        json={"status": "non_existent_status"},
    )
    assert res.status_code == 422


# 18. Multiple status transitions preserve full history
def test_multiple_status_transitions_preserve_history(client, database):
    headers, user_id, job, version, app_data = setup_application(client, database, "history_time@example.com", "hist")
    app_id = app_data["id"]

    statuses = ["viewed", "interview", "offer", "withdrawn"]
    for s in statuses:
        res = client.post(
            f"/applications/{app_id}/timeline",
            headers=headers,
            json={"status": s, "note": f"Transitioned to {s}"},
        )
        assert res.status_code == 201

    events = client.get(f"/applications/{app_id}/timeline", headers=headers).json()
    assert len(events) == 5  # Initial applied + 4 transitions
    assert [e["status"] for e in events] == ["withdrawn", "offer", "interview", "viewed", "applied"]


# 19. Deleting Application cascades to timeline events
def test_application_timeline_cascade_delete(database):
    if database.bind.dialect.name == "sqlite":
        database.execute(sa.text("PRAGMA foreign_keys=ON"))

    user = User(email="cascade_time@example.com", hashed_password="pw", full_name="Cascade User")
    database.add(user)
    database.flush()

    source = JobSource(name="Cascade Source")
    database.add(source)
    database.flush()

    job = Job(title="Dev", company="Co", external_url="http://example.com/casc", deduplication_key="k_casc", source_id=source.id)
    resume = Resume(user_id=user.id, filename="r.pdf", file_url="u.pdf", content_text="Text")
    database.add_all([job, resume])
    database.flush()

    version = ResumeVersion(resume_id=resume.id, user_id=user.id, version_type="original", content_text="Text")
    database.add(version)
    database.flush()

    app_obj = Application(user_id=user.id, job_id=job.id, resume_version_id=version.id, status="applied")
    database.add(app_obj)
    database.flush()

    timeline = ApplicationTimeline(application_id=app_obj.id, status="applied", note="Init")
    database.add(timeline)
    database.commit()

    t_id = timeline.id

    database.delete(app_obj)
    database.commit()

    assert database.get(ApplicationTimeline, t_id) is None


from fastapi.testclient import TestClient
from app.main import app as fastapi_app


# Rollback behavior test: If timeline event creation fails, application creation/status is not left in invalid state
def test_transactional_rollback_on_error(database):
    with TestClient(fastapi_app, raise_server_exceptions=False) as c:
        reg_payload = {"email": "rollback@example.com", "password": "password123", "full_name": "Rollback User"}
        c.post("/auth/register", json=reg_payload)
        login_res = c.post("/auth/login", json={"email": "rollback@example.com", "password": "password123"})
        headers = {"Authorization": f"Bearer {login_res.json()['access_token']}"}
        me = c.get("/users/me", headers=headers).json()

        source = JobSource(name="Rollback Source")
        database.add(source)
        database.flush()
        job = Job(title="Dev", company="Co", external_url="http://example.com/roll", deduplication_key="k_roll", source_id=source.id)
        resume = Resume(user_id=me["id"], filename="r.pdf", file_url="u.pdf", content_text="Text")
        database.add_all([job, resume])
        database.flush()
        version = ResumeVersion(resume_id=resume.id, user_id=me["id"], version_type="original", content_text="Text")
        database.add(version)
        database.commit()

        # Simulate database error during initial timeline creation
        with patch("app.api.routes.applications.ApplicationTimeline") as mock_timeline:
            mock_timeline.side_effect = Exception("Simulated timeline insertion error")

            res = c.post(
                "/applications",
                headers=headers,
                json={"job_id": job.id, "resume_version_id": version.id},
            )
            assert res.status_code == 500

    # Verify no orphan application was created
    apps = list(database.scalars(select(Application).where(Application.user_id == me["id"])).all())
    assert len(apps) == 0
