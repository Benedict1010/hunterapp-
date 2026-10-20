from sqlalchemy.exc import IntegrityError

from app.api.routes.jobs import record_job_view
from app.models.job import Job, JobSource, UserJobView
from app.models.user import User


def _headers_for(client, email: str) -> dict[str, str]:
    password = "password123"
    client.post(
        "/auth/register",
        json={"email": email, "password": password, "full_name": "View Test User"},
    )
    token = client.post("/auth/login", json={"email": email, "password": password}).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _job(database) -> Job:
    source = JobSource(name="View test source")
    database.add(source)
    database.flush()
    job = Job(
        title="Flutter Engineer",
        company="View Co",
        external_url="https://example.test/jobs/view",
        deduplication_key="view-test-job",
        source_id=source.id,
    )
    database.add(job)
    database.commit()
    return job


def test_job_views_require_authentication_and_job_details_remain_public(client, database):
    job = _job(database)

    assert client.get(f"/jobs/{job.id}").status_code == 200
    assert client.get("/jobs/viewed").status_code == 401
    assert client.post(f"/jobs/{job.id}/view").status_code == 401
    assert database.query(UserJobView).count() == 0


def test_job_view_is_idempotent_and_persisted(client, database):
    job = _job(database)
    headers = _headers_for(client, "views@example.com")

    first = client.post(f"/jobs/{job.id}/view", headers=headers)
    second = client.post(f"/jobs/{job.id}/view", headers=headers)

    assert first.status_code == second.status_code == 200
    assert first.json()["id"] == second.json()["id"]
    assert database.query(UserJobView).count() == 1
    listed = client.get("/jobs/viewed", headers=headers)
    assert listed.status_code == 200
    assert [view["job_id"] for view in listed.json()] == [job.id]


def test_job_views_are_isolated_per_user_and_unique_constraint_prevents_duplicates(client, database):
    job = _job(database)
    headers_one = _headers_for(client, "view-one@example.com")
    headers_two = _headers_for(client, "view-two@example.com")

    assert client.post(f"/jobs/{job.id}/view", headers=headers_one).status_code == 200
    assert client.get("/jobs/viewed", headers=headers_two).json() == []
    assert client.post(f"/jobs/{job.id}/view", headers=headers_two).status_code == 200
    assert database.query(UserJobView).count() == 2

    first_view = database.query(UserJobView).filter_by(job_id=job.id).first()
    database.add(UserJobView(user_id=first_view.user_id, job_id=job.id))
    try:
        database.commit()
        raise AssertionError("The user/job uniqueness constraint must reject duplicates")
    except IntegrityError:
        database.rollback()

    assert database.query(UserJobView).count() == 2


def test_job_view_recovers_from_a_concurrent_unique_constraint_conflict(client, database):
    job = _job(database)
    headers = _headers_for(client, "view-race@example.com")
    created = client.post(f"/jobs/{job.id}/view", headers=headers).json()
    user = database.query(User).filter_by(email="view-race@example.com").one()

    class RaceSession:
        """Makes the endpoint's first lookup miss like a competing request."""

        def __init__(self, session):
            self._session = session
            self._first_scalar = True

        def get(self, *args, **kwargs):
            return self._session.get(*args, **kwargs)

        def scalar(self, statement):
            if self._first_scalar:
                self._first_scalar = False
                return None
            return self._session.scalar(statement)

        def begin_nested(self):
            return self._session.begin_nested()

        def add(self, instance):
            self._session.add(instance)

        def flush(self):
            self._session.flush()

    recovered = record_job_view(job.id, user, RaceSession(database))

    assert recovered.id == created["id"]
    assert database.query(UserJobView).filter_by(user_id=user.id, job_id=job.id).count() == 1
    # The savepoint rollback keeps the caller's session usable.
    assert database.query(Job).filter_by(id=job.id).one().id == job.id
