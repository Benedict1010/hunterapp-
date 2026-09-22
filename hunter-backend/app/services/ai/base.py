from abc import ABC, abstractmethod
from app.services.ai.schemas import (
    AIAnalysisRequest,
    AIAnalysisResponse,
    AITailoringRequest,
    AITailoringResponse
)

class AIProvider(ABC):
    """
    Abstract Base Class for AI Providers.
    Defines the contract for future AI-driven operations.
    """

    @abstractmethod
    def analyze_job_resume(self, request: AIAnalysisRequest) -> AIAnalysisResponse:
        """Analyze the fit between a job description and a resume."""
        pass

    @abstractmethod
    def tailor_resume(self, request: AITailoringRequest) -> AITailoringResponse:
        """Generate a tailored version of a resume for a specific job."""
        pass
