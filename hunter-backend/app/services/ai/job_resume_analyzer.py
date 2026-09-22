from sqlalchemy.orm import Session
from sqlalchemy import select

from app.models.job import Job
from app.models.resume import Resume
from app.services.ai.base import AIProvider
from app.services.ai.schemas import AIAnalysisRequest, AIAnalysisResponse

class JobResumeAnalyzer:
    def __init__(self, db: Session, ai_provider: AIProvider):
        self.db = db
        self.ai_provider = ai_provider

    def analyze(self, user_id: str, resume_id: str, job_id: str) -> AIAnalysisResponse:
        # 1. Load the job
        job = self.db.scalar(select(Job).where(Job.id == job_id))
        if not job:
            raise ValueError(f"Job with id {job_id} not found")

        # 2. Load the resume and verify ownership
        resume = self.db.scalar(
            select(Resume).where(Resume.id == resume_id, Resume.user_id == user_id)
        )
        if not resume:
            raise ValueError(f"Resume with id {resume_id} not found for current user")

        # 3. Validate resume content
        if not resume.content_text:
            raise ValueError("Resume has no extracted text content. Please run extraction first.")

        # 4. Build structured AI input
        job_description = f"Title: {job.title}\nCompany: {job.company}\nDescription: {job.description}\n"
        if job.skills:
            job_description += "Required Skills: " + ", ".join([s.name for s in job.skills])

        request = AIAnalysisRequest(
            job_description=job_description,
            resume_text=resume.content_text
        )

        # 5. Invoke AI provider
        return self.ai_provider.analyze_job_resume(request)
