from app.models.job import Job
from app.services.job_ingestion import JobIngestionService
from app.services.job_normalizer import normalize_job
from app.services.job_sources.base import JobSourceAdapter
from app.services.job_sources.mock import MockJobSource, MockPartnerJobSource


class InvalidSource(JobSourceAdapter):
    name = "Invalid mock"
    base_url = "https://invalid.example"

    def fetch_jobs(self):
        return [{"role": "Missing URL", "organization": "Example Co."}]


def test_mock_source_returns_jobs():
    jobs = list(MockJobSource().fetch_jobs())
    assert len(jobs) == 5
    assert {job["role"] for job in jobs} >= {"Software Engineer Intern", "Full Stack Developer Intern", "Frontend Developer", "Backend Developer"}


def test_normalization_maps_source_specific_fields():
    raw = next(iter(MockPartnerJobSource().fetch_jobs()))
    job = normalize_job(raw, source_name="Mock Partner Board", source_base_url="https://mock-partner.example")
    assert job.title == "Backend Developer"
    assert job.company == "Data Harbor"
    assert job.external_url
    assert job.skills == ("Python", "FastAPI", "SQLAlchemy")


def test_valid_jobs_stored_and_cross_source_duplicates_skipped(database):
    service = JobIngestionService(database)
    first = service.ingest(MockJobSource())
    second = service.ingest(MockPartnerJobSource())
    assert (first.received, first.accepted, first.inserted) == (5, 5, 5)
    assert (second.received, second.accepted, second.inserted, second.skipped_duplicates) == (1, 1, 0, 1)
    assert database.query(Job).count() == 5


def test_invalid_job_is_rejected(database):
    summary = JobIngestionService(database).ingest(InvalidSource())
    assert (summary.received, summary.accepted, summary.rejected_invalid) == (1, 0, 1)
    assert database.query(Job).count() == 0


def test_job_api_and_mock_ingestion_endpoint(client):
    response = client.post("/jobs/ingest/mock")
    assert response.status_code == 200
    assert response.json() == {"received": 6, "accepted": 6, "inserted": 5, "skipped_duplicates": 1, "rejected_invalid": 0}
    listing = client.get("/jobs?location=Pune&limit=10")
    assert listing.status_code == 200
    body = listing.json()
    assert body["total"] == 1
    assert body["items"][0]["title"] == "Backend Developer"
    job = client.get(f"/jobs/{body['items'][0]['id']}")
    assert job.status_code == 200
    assert job.json()["source"] == "Mock Campus"
    assert job.json()["skills"]
