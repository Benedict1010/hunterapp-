from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, delete
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.job import JobSource
from app.models.user import User, UserJobSource, new_uuid
from app.schemas.job_source import JobSourceRead, UserJobSourcesRead, UserJobSourcesUpdate

router = APIRouter(prefix="/job-sources", tags=["job-sources"])

DEFAULT_SOURCES = [
    {
        "name": "LinkedIn",
        "base_url": "https://linkedin.com",
        "description": "Professional network with global high-end roles",
        "is_available": False,
    },
    {
        "name": "Unstop",
        "base_url": "https://unstop.com",
        "description": "Hub for student competitions & tech hiring",
        "is_available": False,
    },
    {
        "name": "Naukri",
        "base_url": "https://naukri.com",
        "description": "Massive database of jobs across diverse sectors",
        "is_available": False,
    },
    {
        "name": "Internshala",
        "base_url": "https://internshala.com",
        "description": "Leading platform for internships and entry-level jobs",
        "is_available": False,
    },
    {
        "name": "Indeed",
        "base_url": "https://indeed.com",
        "description": "Aggregated job board covering local and global roles",
        "is_available": False,
    },
    {
        "name": "Career Pages",
        "base_url": "https://careers.company.com",
        "description": "Direct AI-tracking of specific top-tier company sites",
        "is_available": False,
    },
    {
        "name": "Mock Job Source",
        "base_url": "https://mockjobs.example.com",
        "description": "Internal mock ingestion feed for testing",
        "is_available": True,
    },
    {
        "name": "Mock Partner Source",
        "base_url": "https://partner.example.com",
        "description": "Internal partner mock feed for testing",
        "is_available": True,
    },
]


def _ensure_default_sources(database: Session) -> list[JobSource]:
    sources = list(database.scalars(select(JobSource)).all())
    existing_names = {s.name for s in sources}
    added = False
    for item in DEFAULT_SOURCES:
        if item["name"] not in existing_names:
            src = JobSource(
                name=item["name"],
                base_url=item["base_url"],
                description=item["description"],
                is_available=item["is_available"],
            )
            database.add(src)
            sources.append(src)
            added = True
    if added:
        database.commit()
        for s in sources:
            database.refresh(s)
    return sources


@router.get("", response_model=list[JobSourceRead])
def list_job_sources(database: Session = Depends(get_db)) -> list[JobSourceRead]:
    sources = _ensure_default_sources(database)
    return [JobSourceRead.model_validate(s) for s in sources]


@router.get("/selected", response_model=UserJobSourcesRead)
def get_selected_job_sources(
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> UserJobSourcesRead:
    user_sources = database.scalars(
        select(UserJobSource.source_id).where(UserJobSource.user_id == current_user.id)
    ).all()
    return UserJobSourcesRead(selected_source_ids=list(user_sources))


@router.put("/selected", response_model=UserJobSourcesRead)
def update_selected_job_sources(
    payload: UserJobSourcesUpdate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> UserJobSourcesRead:
    _ensure_default_sources(database)

    # Validate all requested source IDs exist
    if payload.source_ids:
        existing_ids = set(
            database.scalars(
                select(JobSource.id).where(JobSource.id.in_(payload.source_ids))
            ).all()
        )
        invalid_ids = set(payload.source_ids) - existing_ids
        if invalid_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid job source IDs: {', '.join(invalid_ids)}",
            )

    # Delete existing selections for current user
    database.execute(
        delete(UserJobSource).where(UserJobSource.user_id == current_user.id)
    )

    # Insert new selections
    for src_id in payload.source_ids:
        database.add(
            UserJobSource(
                id=new_uuid(),
                user_id=current_user.id,
                source_id=src_id,
            )
        )

    database.commit()

    return UserJobSourcesRead(selected_source_ids=payload.source_ids)
