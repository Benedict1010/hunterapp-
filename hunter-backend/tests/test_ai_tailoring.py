import pytest
from unittest.mock import MagicMock, patch
import openai

from app.models.job import Job, JobSource, JobSkill
from app.models.resume import Resume
from app.services.ai.exceptions import (
    AIResponseError,
    AIRateLimitError,
    AITimeoutError,
    AIProviderUnavailableError,
    AITailoringValidationError
)
from app.main import app as fastapi_app
from app.services.ai import get_ai_provider
from app.services.ai.mock import MockAIProvider
from app.services.ai.openai_provider import OpenAIProvider
from app.services.ai.resume_tailor import ResumeTailor
from app.services.ai.schemas import AITailoringRequest, AITailoringResponse


def create_auth_header(client, email="tailor_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Tailor User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}


# 1. MockAIProvider determinism & basic tailoring
def test_mock_ai_provider_tailor():
    provider = MockAIProvider()
    req = AITailoringRequest(
        job_description="Backend Python Engineer",
        resume_text="Built APIs with Python and FastAPI."
    )
    res = provider.tailor_resume(req)

    assert isinstance(res, AITailoringResponse)
    assert "Tailored resume for job" in res.tailored_resume
    assert isinstance(res.changes_made, list)
    assert len(res.changes_made) > 0
    assert isinstance(res.warnings, list)


# 2. OpenAI provider response parsing using mocks
def test_openai_provider_tailor_parsing():
    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.choices = [
        MagicMock(
            message=MagicMock(
                content='{"tailored_resume": "Tailored content here.", "changes_made": ["Reworded bullets"], "warnings": ["Missing Docker"]}'
            )
        )
    ]
    mock_client.chat.completions.create.return_value = mock_response

    with patch("app.services.ai.openai_provider.OpenAI", return_value=mock_client):
        provider = OpenAIProvider(api_key="sk-test", model="gpt-4o-mini")
        req = AITailoringRequest(job_description="Job desc", resume_text="Resume text")
        result = provider.tailor_resume(req)

        assert result.tailored_resume == "Tailored content here."
        assert result.changes_made == ["Reworded bullets"]
        assert result.warnings == ["Missing Docker"]


# 3. Malformed OpenAI provider response
def test_openai_provider_malformed_json():
    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content="invalid json"))]
    mock_client.chat.completions.create.return_value = mock_response

    with patch("app.services.ai.openai_provider.OpenAI", return_value=mock_client):
        provider = OpenAIProvider(api_key="sk-test", model="gpt-4o-mini")
        req = AITailoringRequest(job_description="Job desc", resume_text="Resume text")
        with pytest.raises(AIResponseError):
            provider.tailor_resume(req)


# 4. Provider error mapping
def test_openai_provider_error_mappings():
    mock_client = MagicMock()

    with patch("app.services.ai.openai_provider.OpenAI", return_value=mock_client):
        provider = OpenAIProvider(api_key="sk-test", model="gpt-4o-mini")
        req = AITailoringRequest(job_description="Job desc", resume_text="Resume text")

        # Rate limit
        mock_client.chat.completions.create.side_effect = openai.RateLimitError(
            message="Rate limit", response=MagicMock(), body=None
        )
        with pytest.raises(AIRateLimitError):
            provider.tailor_resume(req)

        # Timeout
        mock_client.chat.completions.create.side_effect = openai.APITimeoutError(request=MagicMock())
        with pytest.raises(AITimeoutError):
            provider.tailor_resume(req)

        # Connection error
        mock_client.chat.completions.create.side_effect = openai.APIConnectionError(request=MagicMock())
        with pytest.raises(AIProviderUnavailableError):
            provider.tailor_resume(req)


# 5. Service-level checks: Successful tailoring with MockAIProvider & preserving original resume
def test_resume_tailor_service_success(database):
    source = JobSource(name="Tailor Source")
    database.add(source)
    database.flush()

    job = Job(
        title="Python Dev",
        company="Acme",
        description="Needs Python and FastAPI",
        external_url="http://example.com/job1",
        deduplication_key="tailor_key_1",
        source_id=source.id
    )
    database.add(job)

    original_text = "Built a React dashboard using JavaScript and Firebase."
    resume = Resume(
        user_id="user_123",
        filename="resume.pdf",
        file_url="http://example.com/resume.pdf",
        content_text=original_text
    )
    database.add(resume)
    database.commit()

    provider = MockAIProvider()
    tailorer = ResumeTailor(database, provider)

    res = tailorer.tailor(user_id="user_123", resume_id=resume.id, job_id=job.id)

    assert isinstance(res, AITailoringResponse)
    assert res.tailored_resume

    # CRITICAL CHECK: Verify original resume.content_text remains unchanged in database
    db_resume = database.get(Resume, resume.id)
    assert db_resume.content_text == original_text


# 6. Safety validation: Valid rephrasing allowed
def test_safety_validation_valid_rephrasing():
    orig = "Built a React dashboard using JavaScript and Firebase."
    job = Job(title="Frontend Engineer", company="Co", description="React dev")

    response = AITailoringResponse(
        tailored_resume="Developed a React-based dashboard using JavaScript and Firebase.",
        changes_made=["Reworded summary for role alignment"],
        warnings=[]
    )

    # Should not raise any error
    ResumeTailor.validate_safety(orig, job, response)


# 7. Safety validation: Detection and rejection of fabricated numeric claims
def test_safety_validation_rejects_fabricated_metrics():
    orig = "Built a React dashboard using JavaScript and Firebase."
    job = Job(title="Frontend Engineer", company="Co", description="React dev")

    response = AITailoringResponse(
        tailored_resume="Built a React dashboard serving 50,000 users.",
        changes_made=["Added scale metric"],
        warnings=[]
    )

    with pytest.raises(AITailoringValidationError) as exc_info:
        ResumeTailor.validate_safety(orig, job, response)

    assert "50,000" in str(exc_info.value) or "numeric" in str(exc_info.value).lower()


# 8. Safety validation: Detection and rejection of fabricated job skills
def test_safety_validation_rejects_fabricated_skills():
    orig = "Built a React dashboard using JavaScript and Firebase."
    job = Job(
        title="Frontend Engineer",
        company="Co",
        description="React dev",
        skills=[JobSkill(name="Kubernetes")]
    )

    response = AITailoringResponse(
        tailored_resume="Built a React dashboard using JavaScript, Firebase, and Kubernetes.",
        changes_made=["Added Kubernetes skill"],
        warnings=[]
    )

    with pytest.raises(AITailoringValidationError) as exc_info:
        ResumeTailor.validate_safety(orig, job, response)

    assert "Kubernetes" in str(exc_info.value) or "skill" in str(exc_info.value).lower()


# 9. Safety validation: Rejects fabricated dates/years
def test_safety_validation_rejects_fabricated_years():
    orig = "Software Engineer at Tech Corp from 2020 to 2022."
    job = Job(title="Dev", company="Co", description="Dev")

    response = AITailoringResponse(
        tailored_resume="Software Engineer at Tech Corp from 2018 to 2024.",
        changes_made=["Extended timeline"],
        warnings=[]
    )

    with pytest.raises(AITailoringValidationError) as exc_info:
        ResumeTailor.validate_safety(orig, job, response)

    err_msg = str(exc_info.value).lower()
    assert "2018" in str(exc_info.value) or "numeric" in err_msg or "year" in err_msg or "date" in err_msg


# 10. API endpoint tests: Authentication & success path
def test_tailor_api_endpoint(client, database):
    headers = create_auth_header(client, "api_tailor@example.com")
    user_me = client.get("/users/me", headers=headers).json()

    source = JobSource(name="API Source")
    database.add(source)
    database.flush()

    job = Job(
        title="Python Dev",
        company="A",
        description="D",
        external_url="u",
        deduplication_key="api_tailor_key",
        source_id=source.id
    )
    database.add(job)

    original_text = "Experienced in Python and PostgreSQL."
    resume = Resume(
        user_id=user_me["id"],
        filename="r.pdf",
        file_url="u.pdf",
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
    data = res.json()
    assert "tailored_resume" in data
    assert "changes_made" in data
    assert "warnings" in data

    # Verify original resume was not overwritten
    db_resume = database.get(Resume, resume.id)
    assert db_resume.content_text == original_text


# 11. API endpoint: Unauthenticated request fails
def test_tailor_api_unauthenticated(client):
    res = client.post("/matches/jobs/123/tailor", json={"resume_id": "456"})
    assert res.status_code == 401


# 12. API endpoint: Missing job / unauthorized resume / empty resume text
def test_tailor_api_error_cases(client, database):
    headers1 = create_auth_header(client, "user_t1@example.com")
    headers2 = create_auth_header(client, "user_t2@example.com")
    user1_id = client.get("/users/me", headers=headers1).json()["id"]

    # 1. Nonexistent job
    res_no_job = client.post(
        "/matches/jobs/nonexistent_job_id/tailor",
        headers=headers1,
        json={"resume_id": "some_resume_id"}
    )
    assert res_no_job.status_code == 404

    # Setup job
    source = JobSource(name="Err Source 2")
    database.add(source)
    database.flush()
    job = Job(title="T", company="C", external_url="u", deduplication_key="k2", source_id=source.id)
    database.add(job)

    resume1 = Resume(user_id=user1_id, filename="r1.pdf", file_url="u1.pdf", content_text="Valid resume content")
    database.add(resume1)
    database.commit()

    # 2. Unauthorized resume access (user2 tries to use user1's resume)
    res_bad_owner = client.post(
        f"/matches/jobs/{job.id}/tailor",
        headers=headers2,
        json={"resume_id": resume1.id}
    )
    assert res_bad_owner.status_code == 404

    # 3. Resume with missing/empty text
    resume_empty = Resume(user_id=user1_id, filename="r_empty.pdf", file_url="u_empty.pdf", content_text="")
    database.add(resume_empty)
    database.commit()

    res_empty_text = client.post(
        f"/matches/jobs/{job.id}/tailor",
        headers=headers1,
        json={"resume_id": resume_empty.id}
    )
    assert res_empty_text.status_code == 404


# 13. API endpoint safety failure returns 422
def test_tailor_api_safety_check_failure(client, database):
    headers = create_auth_header(client, "user_safety_fail@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    source = JobSource(name="Safety Source")
    database.add(source)
    database.flush()
    job = Job(title="T", company="C", external_url="u", deduplication_key="k_safety", source_id=source.id)
    database.add(job)

    resume = Resume(
        user_id=user_id,
        filename="r.pdf",
        file_url="u.pdf",
        content_text="Built a React dashboard."
    )
    database.add(resume)
    database.commit()

    # Mock provider returning a fabricated output that triggers safety failure
    mock_failing_provider = MagicMock()
    mock_failing_provider.tailor_resume.return_value = AITailoringResponse(
        tailored_resume="Built a React dashboard for 500,000 users.",
        changes_made=["Injected scale"],
        warnings=[]
    )

    fastapi_app.dependency_overrides[get_ai_provider] = lambda: mock_failing_provider
    try:
        res = client.post(
            f"/matches/jobs/{job.id}/tailor",
            headers=headers,
            json={"resume_id": resume.id}
        )

        assert res.status_code == 422
        assert "safety validation failed" in res.json()["detail"].lower()
    finally:
        fastapi_app.dependency_overrides.pop(get_ai_provider, None)
