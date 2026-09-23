import re
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.models.job import Job
from app.models.resume import Resume
from app.services.ai.base import AIProvider
from app.services.ai.schemas import AITailoringRequest, AITailoringResponse
from app.services.ai.exceptions import AITailoringValidationError
from app.services.skill_extractor import extract_skills_from_text


class ResumeTailor:
    """
    Service responsible for AI-assisted resume tailoring.
    Enforces resume ownership, non-empty content requirements,
    and post-generation anti-fabrication safety validation.
    """

    def __init__(self, db: Session, ai_provider: AIProvider):
        self.db = db
        self.ai_provider = ai_provider

    def tailor(
        self,
        user_id: str,
        resume_id: str,
        job_id: str,
        instructions: Optional[str] = None
    ) -> AITailoringResponse:
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

        # 3. Validate resume content exists
        if not resume.content_text or not resume.content_text.strip():
            raise ValueError("Resume has no extracted text content. Please run extraction first.")

        # 4. Build tailoring context
        job_description = f"Title: {job.title}\nCompany: {job.company}\nDescription: {job.description}\n"
        if job.skills:
            job_description += "Required Skills: " + ", ".join([s.name for s in job.skills])

        request = AITailoringRequest(
            job_description=job_description,
            resume_text=resume.content_text,
            instructions=instructions
        )

        # 5. Call AI Provider
        response = self.ai_provider.tailor_resume(request)

        # 6. Post-generation safety validation
        self.validate_safety(resume.content_text, job, response)

        # 7. Return structured tailoring result
        return response

    @staticmethod
    def validate_safety(original_text: str, job: Job, response: AITailoringResponse) -> None:
        """
        Deterministic post-generation anti-fabrication safety validator.
        Compares the original resume and tailored resume to detect suspicious additions:
        - New numeric claims/metrics
        - New unsupported target job skills
        - New dates/years

        Limitations:
        Deterministic validation checks for explicit additions of numbers, dates, and keywords.
        It cannot perform full semantic equivalence verification or catch subtle linguistic shifts
        that do not introduce explicit unsupported numbers or keywords.
        """
        tailored_text = response.tailored_resume
        if not tailored_text or not tailored_text.strip():
            raise AITailoringValidationError("Tailored resume output is empty.")

        # 1. Check for fabricated numeric claims
        orig_digits = set(re.findall(r'\d+', original_text))
        tailored_numbers = re.findall(r'\$?\b\d+(?:[\.,]\d+)?%?[kKmMbB]?\b', tailored_text)

        for num_str in tailored_numbers:
            digits_in_num = set(re.findall(r'\d+', num_str))
            if digits_in_num and not digits_in_num.issubset(orig_digits):
                clean_num = num_str.replace(',', '').replace('$', '').replace('%', '')
                if clean_num not in original_text and num_str not in original_text:
                    raise AITailoringValidationError(
                        f"Anti-fabrication safety check failed: Introduced new numeric claim '{num_str}' "
                        f"not found in original resume."
                    )

        # 2. Check for fabricated target job skills
        orig_skills = extract_skills_from_text(original_text)
        tailored_skills = extract_skills_from_text(tailored_text)

        job_skills_normalized = set()
        if job.skills:
            for js in job.skills:
                job_skills_normalized.add(js.name.lower())
        job_skills_extracted = extract_skills_from_text((job.description or "") + " " + (job.title or ""))
        for s in job_skills_extracted:
            job_skills_normalized.add(s.lower())

        new_skills_in_tailored = tailored_skills - orig_skills
        for skill in new_skills_in_tailored:
            if skill.lower() in job_skills_normalized or any(skill.lower() in js for js in job_skills_normalized):
                raise AITailoringValidationError(
                    f"Anti-fabrication safety check failed: Introduced unsupported job skill '{skill}' "
                    f"not present in original resume."
                )

        if job.skills:
            for js in job.skills:
                skill_name = js.name
                pattern = r'\b' + re.escape(skill_name) + r'\b'
                if re.search(pattern, tailored_text, re.IGNORECASE):
                    if not re.search(pattern, original_text, re.IGNORECASE) and skill_name not in orig_skills:
                        raise AITailoringValidationError(
                            f"Anti-fabrication safety check failed: Introduced target job skill '{skill_name}' "
                            f"not present in original resume."
                        )

        # 3. Check for new dates / years
        orig_years = set(re.findall(r'\b(?:19|20)\d{2}\b', original_text))
        tailored_years = set(re.findall(r'\b(?:19|20)\d{2}\b', tailored_text))
        new_years = tailored_years - orig_years
        if new_years:
            raise AITailoringValidationError(
                f"Anti-fabrication safety check failed: Introduced new date/year(s) {sorted(list(new_years))} "
                f"not present in original resume."
            )
