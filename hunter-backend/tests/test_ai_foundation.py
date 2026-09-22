import pytest
from app.services.ai import get_ai_provider, AIConfigurationError
from app.services.ai.mock import MockAIProvider
from app.services.ai.schemas import AIAnalysisRequest, AITailoringRequest
from app.core.config import settings

def test_ai_provider_factory_default(monkeypatch):
    monkeypatch.setattr(settings, "ai_provider", "mock")
    provider = get_ai_provider()
    assert isinstance(provider, MockAIProvider)

def test_ai_provider_factory_invalid(monkeypatch):
    monkeypatch.setattr(settings, "ai_provider", "unsupported_provider")
    with pytest.raises(AIConfigurationError) as exc:
        get_ai_provider()
    assert "Unsupported AI provider" in str(exc.value)

def test_openai_provider_missing_key(monkeypatch):
    monkeypatch.setattr(settings, "ai_provider", "openai")
    monkeypatch.setattr(settings, "ai_api_key", "")
    with pytest.raises(AIConfigurationError) as exc:
        get_ai_provider()
    assert "AI_API_KEY is required" in str(exc.value)

def test_mock_provider_contracts():
    provider = MockAIProvider()

    # Test Analysis Contract
    analysis_req = AIAnalysisRequest(
        job_description="Need a Python dev",
        resume_text="I am a Python dev"
    )
    analysis_res = provider.analyze_job_resume(analysis_req)
    assert analysis_res.summary
    assert isinstance(analysis_res.strengths, list)
    assert isinstance(analysis_res.missing_skills, list)

    # Test Tailoring Contract
    tailor_req = AITailoringRequest(
        job_description="Need a Python dev",
        resume_text="I am a Python dev"
    )
    tailor_res = provider.tailor_resume(tailor_req)
    assert tailor_res.tailored_resume_text
    assert isinstance(tailor_res.changed_sections, list)
    assert isinstance(tailor_res.warnings, list)
