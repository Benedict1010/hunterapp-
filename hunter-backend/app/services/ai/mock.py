from app.services.ai.base import AIProvider
from app.services.ai.schemas import (
    AIAnalysisRequest,
    AIAnalysisResponse,
    AITailoringRequest,
    AITailoringResponse
)

class MockAIProvider(AIProvider):
    """
    Deterministic fake provider for testing and development.
    No network calls or API keys required.
    """

    def analyze_job_resume(self, request: AIAnalysisRequest) -> AIAnalysisResponse:
        return AIAnalysisResponse(
            summary="Mock analysis: Good fit for the role.",
            strengths=["Python", "FastAPI"],
            missing_skills=["Docker"],
            recommendations=["Highlight deployment experience."],
            raw_score=85.0
        )

    def tailor_resume(self, request: AITailoringRequest) -> AITailoringResponse:
        return AITailoringResponse(
            tailored_resume_text=f"Tailored version of: {request.resume_text[:50]}...",
            changed_sections=["Summary", "Skills"],
            warnings=["Please review the generated summary for accuracy."]
        )
