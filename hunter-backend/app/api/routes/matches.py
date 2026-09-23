from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.match import JobMatch
from app.schemas.match import JobMatchRead, JobMatchRequest
from app.services.job_matcher import JobMatcher
from app.services.ai import get_ai_provider
from app.services.ai.job_resume_analyzer import JobResumeAnalyzer
from app.services.ai.resume_tailor import ResumeTailor
from app.services.ai.schemas import AIAnalysisResponse, AITailoringResponse
from app.services.ai.exceptions import AIError, AITailoringValidationError

router = APIRouter(prefix="/matches", tags=["matches"])


@router.post("/jobs/{job_id}", response_model=JobMatchRead)
def match_job(
    job_id: str,
    payload: JobMatchRequest,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> JobMatch:
    matcher = JobMatcher(database)
    try:
        match_result = matcher.calculate_match(
            user_id=current_user.id,
            resume_id=payload.resume_id,
            job_id=job_id
        )
        return match_result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred during matching: {str(e)}"
        )


@router.get("", response_model=list[JobMatchRead])
def list_my_matches(
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> list[JobMatch]:
    statement = select(JobMatch).where(JobMatch.user_id == current_user.id).order_by(JobMatch.updated_at.desc())
    return list(database.scalars(statement).all())


@router.get("/{match_id}", response_model=JobMatchRead)
def get_match(
    match_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> JobMatch:
    match_record = database.scalar(select(JobMatch).where(JobMatch.id == match_id))
    if not match_record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match record not found.")
    if match_record.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    return match_record


@router.post("/jobs/{job_id}/analyze", response_model=AIAnalysisResponse)
def analyze_match(
    job_id: str,
    payload: JobMatchRequest,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
    ai_provider = Depends(get_ai_provider)
) -> AIAnalysisResponse:
    analyzer = JobResumeAnalyzer(database, ai_provider)
    try:
        result = analyzer.analyze(
            user_id=current_user.id,
            resume_id=payload.resume_id,
            job_id=job_id
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        # Note: In a real app we might want to distinguish between 4xx and 5xx here
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Analysis failed: {str(e)}"
        )


@router.post("/jobs/{job_id}/tailor", response_model=AITailoringResponse)
def tailor_resume(
    job_id: str,
    payload: JobMatchRequest,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
    ai_provider = Depends(get_ai_provider)
) -> AITailoringResponse:
    tailorer = ResumeTailor(database, ai_provider)
    try:
        result = tailorer.tailor(
            user_id=current_user.id,
            resume_id=payload.resume_id,
            job_id=job_id
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except AITailoringValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"AI Tailoring safety validation failed: {str(e)}"
        )
    except AIError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Provider error: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Tailoring failed: {str(e)}"
        )
