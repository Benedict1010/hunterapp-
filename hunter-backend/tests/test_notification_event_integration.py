import pytest
import sqlalchemy as sa

from app.models.job import Job, JobSource
from app.models.notification import Notification
from app.models.resume import Resume, ResumeVersion, ResumeVersionType
from app.models.user import User
from app.services.ai.exceptions import AITailoringValidationError, AIError
from app.services.ai.mock import MockAIProvider
from app.services.ai.resume_tailor import ResumeTailor


def create_auth_headers(client, email="event_test_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Event User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    headers = {"Authorization": f"Bearer {login_res.json()['access_token']}"}
    return headers


def setup_test_context(client, database, email="event_test_user@example.com", key_suffix="1"):
    headers = create_auth_headers(client, email)

    user = database.scalar(sa.select(User).where(User.email == email))

    source = JobSource(name=f"Source {key_suffix}")
    database.add(source)
    database.flush()

    job = Job(
        title="Senior Flutter Developer",
        company="Tech Corp",
        location="Remote",
        description="Flutter Dart Python SQL",
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
        content_text="Experienced Flutter developer with 5 years experience.",
        is_primary=True,
    )
    database.add(resume)
    database.flush()

    resume_version = ResumeVersion(
        resume_id=resume.id,
        user_id=user.id,
        job_id=job.id,
        version_type=ResumeVersionType.ORIGINAL.value,
        content_text="Experienced Flutter developer with 5 years experience.",
    )
    database.add(resume_version)
    database.commit()

    return headers, user, job, resume, resume_version


def create_test_application(client, headers, job_id, resume_version_id):
    app_res = client.post(
        "/applications",
        headers=headers,
        json={
            "job_id": job_id,
            "resume_version_id": resume_version_id,
            "status": "applied",
        },
    )
    assert app_res.status_code == 201
    return app_res.json()["id"]


# ==========================================
# 1. APPLICATION STATUS CHANGE TESTS
# ==========================================

def test_application_status_change_creates_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "app_notif_1@example.com", "app1")
    app_id = create_test_application(client, headers, job.id, rv.id)

    # Count notifications before PATCH
    notifs_before = client.get("/notifications", headers=headers).json()["items"]
    count_before = len(notifs_before)

    # Status change: applied -> interview via PATCH /applications/{id}
    patch_res = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"status": "interview"},
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "interview"

    # Verify notification created
    notifs_after = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_after) == count_before + 1

    new_notif = notifs_after[0]
    assert new_notif["notification_type"] == "application_status_changed"
    assert new_notif["related_entity_type"] == "application"
    assert new_notif["related_entity_id"] == app_id
    assert "Senior Flutter Developer" in new_notif["message"]
    assert "interview" in new_notif["message"]

    # Verify timeline event exists
    timeline_res = client.get(f"/applications/{app_id}/timeline", headers=headers)
    assert timeline_res.status_code == 200
    timeline_events = timeline_res.json()
    assert len(timeline_events) == 2  # Initial applied + new interview event
    assert timeline_events[0]["status"] == "interview"


def test_application_status_change_via_timeline_creates_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "app_notif_tl@example.com", "app_tl")
    app_id = create_test_application(client, headers, job.id, rv.id)

    notifs_before = client.get("/notifications", headers=headers).json()["items"]
    count_before = len(notifs_before)

    # Status change via timeline endpoint: applied -> offer
    timeline_post = client.post(
        f"/applications/{app_id}/timeline",
        headers=headers,
        json={"status": "offer", "note": "Received job offer"},
    )
    assert timeline_post.status_code == 201

    notifs_after = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_after) == count_before + 1

    new_notif = notifs_after[0]
    assert new_notif["notification_type"] == "application_status_changed"
    assert new_notif["related_entity_id"] == app_id
    assert "offer" in new_notif["message"]


def test_same_status_update_creates_no_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "app_notif_same@example.com", "app_same")
    app_id = create_test_application(client, headers, job.id, rv.id)

    notifs_before = client.get("/notifications", headers=headers).json()["items"]
    count_before = len(notifs_before)

    # Update with SAME status ("applied")
    patch_res = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"status": "applied"},
    )
    assert patch_res.status_code == 200

    notifs_after = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_after) == count_before


def test_metadata_only_update_creates_no_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "app_notif_meta@example.com", "app_meta")
    app_id = create_test_application(client, headers, job.id, rv.id)

    notifs_before = client.get("/notifications", headers=headers).json()["items"]
    count_before = len(notifs_before)

    # PATCH only external URL / source
    patch_res = client.patch(
        f"/applications/{app_id}",
        headers=headers,
        json={"application_url": "https://company.com/applied/123", "source": "linkedin"},
    )
    assert patch_res.status_code == 200

    notifs_after = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_after) == count_before


# ==========================================
# 2. JOB MATCH NOTIFICATION TESTS
# ==========================================

def test_job_match_creation_creates_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "match_notif_1@example.com", "m1")

    notifs_before = client.get("/notifications", headers=headers).json()["items"]
    count_before = len(notifs_before)

    # Calculate match for first time
    match_res = client.post(
        f"/matches/jobs/{job.id}",
        headers=headers,
        json={"resume_id": resume.id},
    )
    assert match_res.status_code == 200

    notifs_after = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_after) == count_before + 1

    new_notif = notifs_after[0]
    assert new_notif["notification_type"] == "job_match_found"
    assert new_notif["related_entity_type"] == "job"
    assert new_notif["related_entity_id"] == job.id
    assert "Senior Flutter Developer" in new_notif["message"]
    assert "Tech Corp" in new_notif["message"]


def test_repeated_job_match_request_creates_no_duplicate_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "match_notif_rpt@example.com", "mr")

    # First match
    client.post(f"/matches/jobs/{job.id}", headers=headers, json={"resume_id": resume.id})
    notifs_1 = client.get("/notifications", headers=headers).json()["items"]
    count_1 = len(notifs_1)

    # Second match call (same job + resume)
    match_res2 = client.post(f"/matches/jobs/{job.id}", headers=headers, json={"resume_id": resume.id})
    assert match_res2.status_code == 200

    notifs_2 = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_2) == count_1  # No new notification created!


# ==========================================
# 3. RESUME TAILORING NOTIFICATION TESTS
# ==========================================

def test_successful_resume_tailoring_creates_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "tailor_notif_1@example.com", "t1")

    notifs_before = client.get("/notifications", headers=headers).json()["items"]
    count_before = len(notifs_before)

    # Post tailoring request
    tailor_res = client.post(
        f"/matches/jobs/{job.id}/tailor",
        headers=headers,
        json={"resume_id": resume.id},
    )
    assert tailor_res.status_code == 200

    notifs_after = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_after) == count_before + 1

    new_notif = notifs_after[0]
    assert new_notif["notification_type"] == "resume_tailored"
    assert new_notif["related_entity_type"] == "resume_version"
    assert "Senior Flutter Developer" in new_notif["message"]


def test_repeated_successful_tailoring_creates_another_notification(client, database):
    headers, user, job, resume, rv = setup_test_context(client, database, "tailor_notif_rpt@example.com", "tr")

    # First tailoring
    client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": resume.id})
    notifs_1 = client.get("/notifications", headers=headers).json()["items"]
    count_1 = len(notifs_1)

    # Second tailoring call -> creates new ResumeVersion & new notification
    client.post(f"/matches/jobs/{job.id}/tailor", headers=headers, json={"resume_id": resume.id})
    notifs_2 = client.get("/notifications", headers=headers).json()["items"]
    assert len(notifs_2) == count_1 + 1


def test_failed_safety_tailoring_creates_no_notification(database):
    class FabricationAIProvider(MockAIProvider):
        def tailor_resume(self, request):
            resp = super().tailor_resume(request)
            resp.tailored_resume += " Managed $500,000,000 budget with 999% profit."
            return resp

    user = User(email="fail_safety@example.com", hashed_password="pw", full_name="User")
    database.add(user)
    database.flush()

    source = JobSource(name="Source Fail Safety")
    database.add(source)
    database.flush()

    job = Job(
        title="Dev",
        company="Corp",
        description="Coding",
        location="Remote",
        source_id=source.id,
        external_url="http://example.com/job_fs",
        deduplication_key="dedup_fs",
    )
    database.add(job)

    resume = Resume(user_id=user.id, filename="test.pdf", content_text="Software engineer with experience.")
    database.add(resume)
    database.commit()

    tailorer = ResumeTailor(database, FabricationAIProvider())

    with pytest.raises(AITailoringValidationError):
        tailorer.tailor(user_id=user.id, resume_id=resume.id, job_id=job.id)

    versions = database.scalars(sa.select(ResumeVersion).where(ResumeVersion.user_id == user.id)).all()
    assert len(versions) == 0

    notifs = database.scalars(sa.select(Notification).where(Notification.user_id == user.id)).all()
    assert len(notifs) == 0


def test_failed_ai_provider_creates_no_notification(database):
    class ErrorAIProvider(MockAIProvider):
        def tailor_resume(self, request):
            raise AIError("Provider connection error")

    user = User(email="fail_ai@example.com", hashed_password="pw", full_name="User")
    database.add(user)
    database.flush()

    source = JobSource(name="Source Fail AI")
    database.add(source)
    database.flush()

    job = Job(
        title="Dev",
        company="Corp",
        description="Coding",
        location="Remote",
        source_id=source.id,
        external_url="http://example.com/job_fai",
        deduplication_key="dedup_fai",
    )
    database.add(job)

    resume = Resume(user_id=user.id, filename="test.pdf", content_text="Software engineer with experience.")
    database.add(resume)
    database.commit()

    tailorer = ResumeTailor(database, ErrorAIProvider())

    with pytest.raises(AIError):
        tailorer.tailor(user_id=user.id, resume_id=resume.id, job_id=job.id)

    notifs = database.scalars(sa.select(Notification).where(Notification.user_id == user.id)).all()
    assert len(notifs) == 0


# ==========================================
# 4. TRANSACTION & ROLLBACK SAFETY TESTS
# ==========================================

def test_transaction_rollback_cleans_up_notification(database):
    user = User(email="tx_roll@example.com", hashed_password="pw", full_name="User")
    database.add(user)
    database.flush()

    source = JobSource(name="Source TX Roll")
    database.add(source)
    database.flush()

    job = Job(
        title="Dev",
        company="Corp",
        description="Coding",
        location="Remote",
        source_id=source.id,
        external_url="http://example.com/job_tx",
        deduplication_key="dedup_tx",
    )
    database.add(job)
    database.commit()

    try:
        from app.services.notification_service import NotificationService
        NotificationService.notify_job_match_found(
            db=database,
            user_id=user.id,
            job_id=job.id,
            job_title=job.title,
            match_score=0.8,
            commit=False,
        )
        raise ValueError("Simulated failure during operation")
    except ValueError:
        database.rollback()

    notifs = database.scalars(sa.select(Notification).where(Notification.user_id == user.id)).all()
    assert len(notifs) == 0
