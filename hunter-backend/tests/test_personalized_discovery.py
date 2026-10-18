from app.models.match import JobMatch
from app.models.notification import Notification


def _register_and_login(client, email: str, name: str = "Test User") -> dict[str, str]:
    client.post(
        "/auth/register",
        json={"email": email, "password": "password123", "full_name": name},
    )
    token = client.post(
        "/auth/login",
        json={"email": email, "password": "password123"},
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_public_get_jobs_compatibility(client):
    ingest_resp = client.post("/jobs/ingest/mock")
    assert ingest_resp.status_code == 200

    response = client.get("/jobs")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 5
    assert len(data["items"]) == 5


def test_personalized_discovery_requires_authentication(client):
    resp_no_token = client.get("/jobs?use_saved_preferences=true")
    assert resp_no_token.status_code == 401

    resp_bad_token = client.get(
        "/jobs?use_saved_preferences=true",
        headers={"Authorization": "Bearer invalidtoken123"},
    )
    assert resp_bad_token.status_code == 401

    resp_anon = client.get("/jobs")
    assert resp_anon.status_code == 200


def test_mock_adapter_mapping_to_selectable_source_ids(client):
    sources = client.get("/job-sources").json()
    mock_source = next(s for s in sources if s["name"] == "Mock Job Source")

    client.post("/jobs/ingest/mock")

    jobs = client.get("/jobs").json()["items"]
    mock_jobs = [j for j in jobs if j["source"] == "Mock Job Source"]
    assert len(mock_jobs) == 5
    for j in mock_jobs:
        job_detail = client.get(f"/jobs/{j['id']}").json()
        assert job_detail["source"] == "Mock Job Source"


def test_selected_source_filtering_single_and_multiple(client):
    client.post("/jobs/ingest/mock")
    headers = _register_and_login(client, "user_sources@example.com")

    sources = client.get("/job-sources").json()
    mock_job_src = next(s for s in sources if s["name"] == "Mock Job Source")
    mock_partner_src = next(s for s in sources if s["name"] == "Mock Partner Source")

    client.put(
        "/job-sources/selected",
        headers=headers,
        json={"source_ids": [mock_job_src["id"]]},
    )

    res_single = client.get("/jobs?use_saved_preferences=true", headers=headers).json()
    assert res_single["total"] == 5
    assert all(j["source"] == "Mock Job Source" for j in res_single["items"])

    client.put(
        "/job-sources/selected",
        headers=headers,
        json={"source_ids": [mock_job_src["id"], mock_partner_src["id"]]},
    )

    res_multi = client.get("/jobs?use_saved_preferences=true", headers=headers).json()
    assert res_multi["total"] == 5


def test_empty_source_selection_does_not_restrict_sources(client):
    client.post("/jobs/ingest/mock")
    headers = _register_and_login(client, "empty_sources@example.com")

    client.put(
        "/job-sources/selected",
        headers=headers,
        json={"source_ids": []},
    )

    res = client.get("/jobs?use_saved_preferences=true", headers=headers).json()
    assert res["total"] == 5


def test_selected_unavailable_source_behavior(client):
    client.post("/jobs/ingest/mock")
    headers = _register_and_login(client, "unavailable@example.com")

    sources = client.get("/job-sources").json()
    linkedin = next(s for s in sources if s["name"] == "LinkedIn")
    assert linkedin["is_available"] is False

    client.put(
        "/job-sources/selected",
        headers=headers,
        json={"source_ids": [linkedin["id"]]},
    )

    res = client.get("/jobs?use_saved_preferences=true", headers=headers).json()
    assert res["total"] == 0
    assert res["items"] == []


def test_valid_authenticated_user_isolation(client):
    client.post("/jobs/ingest/mock")

    headers_u1 = _register_and_login(client, "user1_iso@example.com")
    headers_u2 = _register_and_login(client, "user2_iso@example.com")

    sources = client.get("/job-sources").json()
    mock_src = next(s for s in sources if s["name"] == "Mock Job Source")
    linkedin = next(s for s in sources if s["name"] == "LinkedIn")

    client.put(
        "/job-sources/selected",
        headers=headers_u1,
        json={"source_ids": [mock_src["id"]]},
    )

    client.put(
        "/job-sources/selected",
        headers=headers_u2,
        json={"source_ids": [linkedin["id"]]},
    )

    res_u1 = client.get("/jobs?use_saved_preferences=true", headers=headers_u1).json()
    res_u2 = client.get("/jobs?use_saved_preferences=true", headers=headers_u2).json()

    assert res_u1["total"] == 5
    assert res_u2["total"] == 0


def test_pagination_after_filtering(client):
    client.post("/jobs/ingest/mock")
    headers = _register_and_login(client, "page_user@example.com")

    sources = client.get("/job-sources").json()
    mock_src = next(s for s in sources if s["name"] == "Mock Job Source")

    client.put(
        "/job-sources/selected",
        headers=headers,
        json={"source_ids": [mock_src["id"]]},
    )

    page1 = client.get(
        "/jobs?use_saved_preferences=true&limit=2&offset=0",
        headers=headers,
    ).json()
    assert page1["total"] == 5
    assert len(page1["items"]) == 2

    page2 = client.get(
        "/jobs?use_saved_preferences=true&limit=2&offset=2",
        headers=headers,
    ).json()
    assert page2["total"] == 5
    assert len(page2["items"]) == 2

    ids_p1 = {j["id"] for j in page1["items"]}
    ids_p2 = {j["id"] for j in page2["items"]}
    assert ids_p1.isdisjoint(ids_p2)


def test_no_match_or_notification_creation_during_job_listing(client, database):
    client.post("/jobs/ingest/mock")
    headers = _register_and_login(client, "side_effects@example.com")

    initial_matches = database.query(JobMatch).count()
    initial_notifications = database.query(Notification).count()

    client.get("/jobs?use_saved_preferences=true", headers=headers)
    client.get("/jobs")

    assert database.query(JobMatch).count() == initial_matches
    assert database.query(Notification).count() == initial_notifications


def test_ingestion_and_deduplication_regressions(client):
    first = client.post("/jobs/ingest/mock").json()
    assert first["inserted"] == 5

    second = client.post("/jobs/ingest/mock").json()
    assert second["inserted"] == 0
    assert second["skipped_duplicates"] == 6


def test_legacy_source_alias_and_url_alias_resolution(client, database):
    from app.models.job import JobSource
    from app.services.job_ingestion import JobIngestionService
    from app.services.job_sources.mock import MockJobSource

    legacy_source = JobSource(name="Mock Campus", base_url="https://mock-campus.example", is_available=True)
    database.add(legacy_source)
    database.commit()

    service = JobIngestionService(database)
    summary = service.ingest(MockJobSource())
    assert summary.inserted == 5

    sources = database.query(JobSource).filter(JobSource.name == "Mock Campus").all()
    assert len(sources) == 1
    assert sources[0].id == legacy_source.id
