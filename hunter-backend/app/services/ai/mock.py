from app.services.ai.base import AIProvider
from app.services.ai.schemas import (
    AIAnalysisRequest,
    AIAnalysisResponse,
    AITailoringRequest,
    AITailoringResponse
)
from app.services.ai.exceptions import AIResponseError, AIRateLimitError


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
        instructions = request.instructions or ""

        if "SIMULATE_MALFORMED" in instructions:
            raise AIResponseError("Malformed mock AI response.")
        if "SIMULATE_RATE_LIMIT" in instructions:
            raise AIRateLimitError("Mock rate limit exceeded.")

        tailored_text = f"Tailored resume for job:\n{request.resume_text}"

        if "SIMULATE_FABRICATION_METRIC" in instructions:
            tailored_text += "\nAchieved 50,000 users scale."
        elif "SIMULATE_FABRICATION_SKILL" in instructions:
            tailored_text += "\nExtensive experience with Kubernetes."

        return AITailoringResponse(
            tailored_resume=tailored_text,
            changes_made=[
                "Reordered technical skills section to highlight job relevant technologies.",
                "Reworded experience descriptions for improved clarity."
            ],
            warnings=[
                "Candidate lacks some secondary requirements mentioned in job description."
            ]
        )
