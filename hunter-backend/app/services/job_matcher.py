from sqlalchemy.orm import Session
from sqlalchemy import select
from app.models.job import Job
from app.models.resume import Resume
from app.models.match import JobMatch
from app.services.skill_extractor import extract_skills_from_text
from app.services.skill_vocabulary import normalize_skill

class JobMatcher:
    def __init__(self, db: Session):
        self.db = db

    def calculate_match(self, user_id: str, resume_id: str, job_id: str) -> JobMatch:
        """
        Calculate and persist/update a deterministic job match.
        """
        job = self.db.scalar(select(Job).where(Job.id == job_id))
        if not job:
            raise ValueError(f"Job with id {job_id} not found")

        resume = self.db.scalar(select(Resume).where(Resume.id == resume_id, Resume.user_id == user_id))
        if not resume:
            raise ValueError(f"Resume with id {resume_id} for user {user_id} not found")

        # 1. Get Resume Skills
        resume_skills = extract_skills_from_text(resume.content_text or "")

        # 2. Get Job Skills
        # First, use normalized JobSkill entities if they exist
        job_skills_entities = job.skills
        if job_skills_entities:
            # Normalize them against our vocabulary if possible, otherwise use as-is
            job_required_skills = set()
            for js in job_skills_entities:
                normalized = normalize_skill(js.name)
                job_required_skills.add(normalized if normalized else js.name)
        else:
            # Fallback: Extract from description if no specific skill entities
            job_required_skills = extract_skills_from_text(job.description or "")
            # Also check title
            job_required_skills.update(extract_skills_from_text(job.title))

        # 3. Calculate Matched and Missing
        matched = resume_skills.intersection(job_required_skills)
        missing = job_required_skills.difference(resume_skills)

        # 4. Scoring Algorithm
        # formula: (matched / required) * 100
        if not job_required_skills:
            # Edge case: Job has no identifiable skills.
            # If resume also has no skills, we could say 0 or 100.
            # Letting it be 100 if both are empty or just 0 to be safe.
            score = 100.0 if not resume_skills else 50.0 # Neutral baseline
        else:
            score = (len(matched) / len(job_required_skills)) * 100.0

        # 5. Explanation
        explanation = f"Matched {len(matched)} out of {len(job_required_skills)} required skills."
        if not job_required_skills:
            explanation = "No specific skills identified for this job."

        # 6. Upsert JobMatch
        stmt = select(JobMatch).where(
            JobMatch.user_id == user_id,
            JobMatch.resume_id == resume_id,
            JobMatch.job_id == job_id
        )
        existing_match = self.db.scalar(stmt)

        if existing_match:
            existing_match.match_score = score
            existing_match.matched_skills = list(matched)
            existing_match.missing_skills = list(missing)
            existing_match.explanation = explanation
            match_record = existing_match
        else:
            match_record = JobMatch(
                user_id=user_id,
                resume_id=resume_id,
                job_id=job_id,
                match_score=score,
                matched_skills=list(matched),
                missing_skills=list(missing),
                explanation=explanation
            )
            self.db.add(match_record)

        self.db.commit()
        self.db.refresh(match_record)
        return match_record
