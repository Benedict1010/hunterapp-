from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.security import get_optional_user
from app.models.job import Job
from app.models.user import JobPreference, User, UserJobSource
from app.schemas.job import IngestionSummary, JobListResponse, JobRead, JobSkillRead
from app.services.job_ingestion import JobIngestionService
from app.services.job_sources.mock import MockJobSource, MockPartnerJobSource

router = APIRouter(prefix="/jobs", tags=["jobs"])


def serialize_job(job: Job) -> JobRead:
    return JobRead(
        id=job.id,
        title=job.title,
        company=job.company,
        location=job.location,
        description=job.description,
        salary_range=job.salary_range,
        job_type=job.job_type,
        external_url=job.external_url,
        posted_at=job.posted_at,
        source=job.source.name,
        skills=[JobSkillRead(name=skill.name, importance=skill.importance) for skill in job.skills],
    )


@router.get("", response_model=JobListResponse)
def list_jobs(
    company: str | None = None,
    location: str | None = None,
    job_type: str | None = None,
    use_saved_preferences: bool = Query(False),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User | None = Depends(get_optional_user),
    database: Session = Depends(get_db),
) -> JobListResponse:
    if use_saved_preferences and current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required for personalized job discovery",
            headers={"WWW-Authenticate": "Bearer"},
        )

    filters = []

    # Explicit query parameters
    if company:
        filters.append(Job.company.ilike(f"%{company}%"))
    if location:
        filters.append(Job.location.ilike(f"%{location}%"))
    if job_type:
        filters.append(Job.job_type.ilike(f"%{job_type}%"))

    # Personalized preferences
    if use_saved_preferences and current_user is not None:
        # Selected source filtering
        user_sources = database.scalars(
            select(UserJobSource.source_id).where(UserJobSource.user_id == current_user.id)
        ).all()
        selected_source_ids = list(user_sources)
        if selected_source_ids:
            filters.append(Job.source_id.in_(selected_source_ids))

        # Job preferences filtering
        pref = database.scalar(
            select(JobPreference).where(JobPreference.user_id == current_user.id)
        )
        if pref:
            if not job_type and pref.job_type:
                filters.append(Job.job_type.ilike(f"%{pref.job_type}%"))
            if not location and pref.preferred_locations:
                loc_conditions = [
                    Job.location.ilike(f"%{loc}%") for loc in pref.preferred_locations if loc.strip()
                ]
                if loc_conditions:
                    filters.append(or_(*loc_conditions))
            if pref.preferred_roles:
                role_conditions = [
                    or_(Job.title.ilike(f"%{r}%"), Job.description.ilike(f"%{r}%"))
                    for r in pref.preferred_roles
                    if r.strip()
                ]
                if role_conditions:
                    filters.append(or_(*role_conditions))

    statement = (
        select(Job)
        .options(selectinload(Job.source), selectinload(Job.skills))
        .where(*filters)
        .order_by(Job.posted_at.desc(), Job.created_at.desc(), Job.id.desc())
        .offset(offset)
        .limit(limit)
    )
    total = database.scalar(select(func.count()).select_from(Job).where(*filters)) or 0
    return JobListResponse(
        items=[serialize_job(job) for job in database.scalars(statement)],
        total=total,
        limit=limit,
        offset=offset,
    )


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
    job = database.scalar(
        select(Job)
        .options(selectinload(Job.source), selectinload(Job.skills))
        .where(Job.id == job_id)
    )
    if job is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return serialize_job(job)
