from pydantic import BaseModel, computed_field
from typing import List, Optional

class AIAnalysisRequest(BaseModel):
    job_description: str
    resume_text: str

class AIAnalysisResponse(BaseModel):
    summary: str
    strengths: List[str]
    missing_skills: List[str]
    recommendations: List[str]
    raw_score: Optional[float] = None

class AITailoringRequest(BaseModel):
    job_description: str
    resume_text: str
    instructions: Optional[str] = None

class AITailoringResponse(BaseModel):
    tailored_resume: str
    changes_made: List[str]
    warnings: List[str]

    @computed_field
    @property
    def tailored_resume_text(self) -> str:
        return self.tailored_resume

    @computed_field
    @property
    def changed_sections(self) -> List[str]:
        return self.changes_made
