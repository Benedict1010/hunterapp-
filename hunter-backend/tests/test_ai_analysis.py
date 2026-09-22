import pytest
from unittest.mock import MagicMock, patch
from app.services.ai.openai_provider import OpenAIProvider
from app.services.ai.schemas import AIAnalysisRequest, AIAnalysisResponse
from app.services.ai.exceptions import AIResponseError
from app.models.job import Job, JobSource
from app.models.resume import Resume

def test_openai_provider_analysis_parsing():
    # Mock OpenAI client
    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.choices = [
        MagicMock(message=MagicMock(content='{"summary": "Test", "strengths": ["S1"], "missing_skills": ["M1"], "recommendations": ["R1"]}'))
    ]
    mock_client.chat.completions.create.return_value = mock_response

    with patch("app.services.ai.openai_provider.OpenAI", return_value=mock_client):
        provider = OpenAIProvider(api_key="sk-test", model="gpt-4o-mini")
        request = AIAnalysisRequest(job_description="Job", resume_text="Resume")
        result = provider.analyze_job_resume(request)

        assert result.summary == "Test"
        assert result.strengths == ["S1"]
        assert result.missing_skills == ["M1"]
        assert result.recommendations == ["R1"]

def test_openai_provider_malformed_json():
    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.choices = [
        MagicMock(message=MagicMock(content='invalid json'))
    ]
    mock_client.chat.completions.create.return_value = mock_response

    with patch("app.services.ai.openai_provider.OpenAI", return_value=mock_client):
        provider = OpenAIProvider(api_key="sk-test", model="gpt-4o-mini")
        request = AIAnalysisRequest(job_description="Job", resume_text="Resume")
        with pytest.raises(AIResponseError):
            provider.analyze_job_resume(request)

def create_auth_header(client, email="analyzer@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "AI User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}

def test_ai_analysis_api_mock(client, database):
    # Test full path with mock provider
    headers = create_auth_header(client, "user_ai@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    source = JobSource(name="AI Source")
    database.add(source)
    database.flush()
    job = Job(title="Python Dev", company="A", description="D", external_url="u", deduplication_key="k", source_id=source.id)
    database.add(job)
    resume = Resume(user_id=user_id, filename="r.pdf", file_url="u.pdf", content_text="Expert in Python")
    database.add(resume)
    database.commit()

    # Call /analyze
    response = client.post(
        f"/matches/jobs/{job.id}/analyze",
        headers=headers,
        json={"resume_id": resume.id}
    )

    assert response.status_code == 200
    data = response.json()
    assert "summary" in data
    assert "Mock analysis" in data["summary"]
    assert "Python" in data["strengths"]

def test_ai_analysis_errors(client, database):
    headers1 = create_auth_header(client, "u1@example.com")
    headers2 = create_auth_header(client, "u2@example.com")

    # 1. Nonexistent job
    res = client.post("/matches/jobs/999/analyze", headers=headers1, json={"resume_id": "999"})
    assert res.status_code == 404

    # Setup job
    source = JobSource(name="Err Source")
    database.add(source)
    database.flush()
    job = Job(title="T", company="C", external_url="u", deduplication_key="k", source_id=source.id)
    database.add(job)
    database.commit()

    # 2. Unauthorized resume
    user1_me = client.get("/users/me", headers=headers1).json()
    resume1 = Resume(user_id=user1_me["id"], filename="r1.pdf", file_url="u1.pdf", content_text="Text")
    database.add(resume1)
    database.commit()

    res_bad_owner = client.post(f"/matches/jobs/{job.id}/analyze", headers=headers2, json={"resume_id": resume1.id})
    assert res_bad_owner.status_code == 404 # Per our implementation (UserResumeAnalyzer raises ValueError)

    # 3. Missing resume text
    resume2 = Resume(user_id=user1_me["id"], filename="r2.pdf", file_url="u2.pdf", content_text=None)
    database.add(resume2)
    database.commit()

    res_no_text = client.post(f"/matches/jobs/{job.id}/analyze", headers=headers1, json={"resume_id": resume2.id})
    assert res_no_text.status_code == 404 # Per our implementation
