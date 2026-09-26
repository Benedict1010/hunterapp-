import os
import uuid
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from fastapi.responses import FileResponse
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.resume import Resume, ResumeVersion, ResumeVersionType
from app.schemas.resume import ResumeRead, ResumeUpdate, ResumeVersionRead
from app.services.resume_extractor import extract_text_from_file, ResumeExtractionError

router = APIRouter(prefix="/resumes", tags=["resumes"])

ALLOWED_EXTENSIONS = {".pdf", ".docx"}


def get_safe_upload_dir() -> str:
    os.makedirs(settings.resume_upload_dir, exist_ok=True)
    return settings.resume_upload_dir


@router.post("", response_model=ResumeRead, status_code=status.HTTP_201_CREATED)
def upload_resume(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Resume:
    # Validation
    filename = file.filename or "resume"
    ext = os.path.splitext(filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type. Only PDF and DOCX files are allowed."
        )

    # Size validation
    try:
        content = file.file.read()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not read the uploaded file."
        )

    file_size = len(content)
    if file_size == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The uploaded file is empty."
        )
    if file_size > settings.max_resume_file_size:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File size exceeds the limit of {settings.max_resume_file_size} bytes."
        )

    # Rewind for safety
    file.file.seek(0)

    # Check if first resume
    existing_count = database.scalar(
        select(Resume).where(Resume.user_id == current_user.id)
    )
    is_first = existing_count is None

    # Save file securely
    safe_filename = f"{uuid.uuid4()}{ext}"
    upload_dir = get_safe_upload_dir()
    safe_path = os.path.join(upload_dir, safe_filename)

    with open(safe_path, "wb") as f:
        f.write(content)

    # Perform text extraction
    try:
        extracted_text = extract_text_from_file(safe_path, ext)
    except ResumeExtractionError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

    # Primary logic if this is first
    is_primary = True if is_first else False

    # Create metadata
    new_resume = Resume(
        user_id=current_user.id,
        filename=filename,
        file_url=safe_filename,  # relative filename or reference
        content_text=extracted_text,
        is_primary=is_primary
    )
    database.add(new_resume)
    database.flush()

    if extracted_text and extracted_text.strip():
        original_version = ResumeVersion(
            resume_id=new_resume.id,
            user_id=current_user.id,
            job_id=None,
            version_type=ResumeVersionType.ORIGINAL.value,
            content_text=extracted_text,
        )
        database.add(original_version)

    database.commit()
    database.refresh(new_resume)
    return new_resume


@router.get("", response_model=list[ResumeRead])
def list_resumes(
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> list[Resume]:
    statement = select(Resume).where(Resume.user_id == current_user.id).order_by(Resume.created_at.desc())
    return list(database.scalars(statement).all())


@router.get("/{resume_id}", response_model=ResumeRead)
def get_resume(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> Resume:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    return resume


@router.get("/{resume_id}/download")
def download_resume(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
):
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    safe_path = os.path.join(settings.resume_upload_dir, resume.file_url)
    if not os.path.exists(safe_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Physical file not found on disk.")

    media_type = "application/pdf" if resume.file_url.endswith(".pdf") else "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    return FileResponse(safe_path, media_type=media_type, filename=resume.filename)


@router.put("/{resume_id}", response_model=ResumeRead)
def update_resume(
    resume_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> Resume:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    # Validation
    filename = file.filename or "resume"
    ext = os.path.splitext(filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type. Only PDF and DOCX files are allowed."
        )

    try:
        content = file.file.read()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not read the uploaded file."
        )

    file_size = len(content)
    if file_size == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The uploaded file is empty."
        )
    if file_size > settings.max_resume_file_size:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File size exceeds the limit of {settings.max_resume_file_size} bytes."
        )

    # Save new file first to make sure it's valid
    safe_filename = f"{uuid.uuid4()}{ext}"
    safe_path = os.path.join(get_safe_upload_dir(), safe_filename)
    with open(safe_path, "wb") as f:
        f.write(content)

    # Perform text extraction
    try:
        extracted_text = extract_text_from_file(safe_path, ext)
    except ResumeExtractionError as e:
        # Clean up the newly uploaded file before failing if extraction fails
        if os.path.exists(safe_path):
            try:
                os.remove(safe_path)
            except Exception:
                pass
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

    # Remove old file if it exists
    old_path = os.path.join(settings.resume_upload_dir, resume.file_url)
    if os.path.exists(old_path):
        try:
            os.remove(old_path)
        except Exception:
            pass

    resume.filename = filename
    resume.file_url = safe_filename
    resume.content_text = extracted_text

    if extracted_text and extracted_text.strip():
        original_version = ResumeVersion(
            resume_id=resume.id,
            user_id=current_user.id,
            job_id=None,
            version_type=ResumeVersionType.ORIGINAL.value,
            content_text=extracted_text,
        )
        database.add(original_version)

    database.commit()
    database.refresh(resume)
    return resume


@router.get("/{resume_id}/versions", response_model=list[ResumeVersionRead])
def list_resume_versions(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> list[ResumeVersion]:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    statement = (
        select(ResumeVersion)
        .where(ResumeVersion.resume_id == resume_id, ResumeVersion.user_id == current_user.id)
        .order_by(ResumeVersion.created_at.desc())
    )
    return list(database.scalars(statement).all())


@router.get("/{resume_id}/versions/{version_id}", response_model=ResumeVersionRead)
def get_resume_version(
    resume_id: str,
    version_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> ResumeVersion:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    version = database.scalar(
        select(ResumeVersion).where(
            ResumeVersion.id == version_id,
            ResumeVersion.resume_id == resume_id,
            ResumeVersion.user_id == current_user.id,
        )
    )
    if not version:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume version not found.")

    return version



@router.delete("/{resume_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_resume(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
):
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    # Remove file from disk
    file_path = os.path.join(settings.resume_upload_dir, resume.file_url)
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
        except Exception:
            pass

    database.delete(resume)
    database.commit()


@router.patch("/{resume_id}/primary", response_model=ResumeRead)
def set_primary_resume(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> Resume:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    # Clear existing primary resumes for this user
    database.execute(
        update(Resume).where(Resume.user_id == current_user.id).values(is_primary=False)
    )

    resume.is_primary = True
    database.commit()
    database.refresh(resume)
    return resume


@router.post("/{resume_id}/extract", response_model=ResumeRead)
def reextract_resume(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> Resume:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    safe_path = os.path.join(settings.resume_upload_dir, resume.file_url)
    if not os.path.exists(safe_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Physical file not found on disk.")

    ext = os.path.splitext(resume.filename)[1].lower()
    try:
        extracted_text = extract_text_from_file(safe_path, ext)
    except ResumeExtractionError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

    resume.content_text = extracted_text

    if extracted_text and extracted_text.strip():
        original_version = ResumeVersion(
            resume_id=resume.id,
            user_id=current_user.id,
            job_id=None,
            version_type=ResumeVersionType.ORIGINAL.value,
            content_text=extracted_text,
        )
        database.add(original_version)

    database.commit()
    database.refresh(resume)
    return resume


@router.get("/{resume_id}/versions", response_model=list[ResumeVersionRead])
def list_resume_versions(
    resume_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> list[ResumeVersion]:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    statement = (
        select(ResumeVersion)
        .where(ResumeVersion.resume_id == resume_id, ResumeVersion.user_id == current_user.id)
        .order_by(ResumeVersion.created_at.desc())
    )
    return list(database.scalars(statement).all())


@router.get("/{resume_id}/versions/{version_id}", response_model=ResumeVersionRead)
def get_resume_version(
    resume_id: str,
    version_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db)
) -> ResumeVersion:
    resume = database.scalar(select(Resume).where(Resume.id == resume_id))
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
    if resume.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    version = database.scalar(
        select(ResumeVersion).where(
            ResumeVersion.id == version_id,
            ResumeVersion.resume_id == resume_id,
            ResumeVersion.user_id == current_user.id,
        )
    )
    if not version:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume version not found.")

    return version

