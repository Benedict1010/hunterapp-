from pydantic import BaseModel
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
    tailored_resume_text: str
    changed_sections: List[str]
    warnings: List[str]
