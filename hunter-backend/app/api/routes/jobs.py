from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.models.job import Job
from app.schemas.job import IngestionSummary, JobListResponse, JobRead, JobSkillRead
from app.services.job_ingestion import JobIngestionService
from app.services.job_sources.mock import MockJobSource, MockPartnerJobSource

router = APIRouter(prefix="/jobs", tags=["jobs"])


def serialize_job(job: Job) -> JobRead:
    return JobRead(id=job.id, title=job.title, company=job.company, location=job.location, description=job.description, salary_range=job.salary_range, job_type=job.job_type, external_url=job.external_url, posted_at=job.posted_at, source=job.source.name, skills=[JobSkillRead(name=skill.name, importance=skill.importance) for skill in job.skills])


@router.get("", response_model=JobListResponse)
def list_jobs(company: str | None = None, location: str | None = None, job_type: str | None = None, limit: int = Query(20, ge=1, le=100), offset: int = Query(0, ge=0), database: Session = Depends(get_db)) -> JobListResponse:
    filters = []
    if company:
        filters.append(Job.company.ilike(f"%{company}%"))
    if location:
        filters.append(Job.location.ilike(f"%{location}%"))
    if job_type:
        filters.append(Job.job_type.ilike(f"%{job_type}%"))
    statement = select(Job).options(selectinload(Job.source), selectinload(Job.skills)).where(*filters).order_by(Job.posted_at.desc(), Job.created_at.desc()).offset(offset).limit(limit)
    total = database.scalar(select(func.count()).select_from(Job).where(*filters)) or 0
    return JobListResponse(items=[serialize_job(job) for job in database.scalars(statement)], total=total, limit=limit, offset=offset)


@router.post("/ingest/mock", response_model=IngestionSummary, status_code=status.HTTP_200_OK)
def ingest_mock_jobs(database: Session = Depends(get_db)) -> IngestionSummary:
    service = JobIngestionService(database)
    combined = {"received": 0, "accepted": 0, "inserted": 0, "skipped_duplicates": 0, "rejected_invalid": 0}
    for adapter in (MockJobSource(), MockPartnerJobSource()):
        summary = service.ingest(adapter)
        for key, value in summary.__dict__.items():
            combined[key] += value
    return IngestionSummary(**combined)


@router.get("/{job_id}", response_model=JobRead)
def get_job(job_id: str, database: Session = Depends(get_db)) -> JobRead:
    job = database.scalar(select(Job).options(selectinload(Job.source), selectinload(Job.skills)).where(Job.id == job_id))
    if job is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return serialize_job(job)
