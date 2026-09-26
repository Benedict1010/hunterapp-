# Hunter - AI Job Hunter

Hunter is an AI-powered job search and application management system with a FastAPI backend and Flutter mobile application.

## Backend Architecture & Resume Versions (Phase 3E.4)

### ResumeVersion Concept & Lifecycle
The `ResumeVersion` entity represents a concrete snapshot of a resume. Each `Resume` can have multiple historical versions.

#### Version Types
- **`original`**: Created automatically upon successful upload (`POST /resumes`), replacement (`PUT /resumes/{resume_id}`), or re-extraction (`POST /resumes/{resume_id}/extract`) of a resume file. Represents the extracted source text from the uploaded file and does not require a `job_id`.
- **`tailored`**: Created automatically after successful AI resume tailoring (`POST /matches/jobs/{job_id}/tailor`). Stores the tailored resume content targeted toward a specific job (`job_id`), along with `changes_made` and `warnings`.

#### Persistence & Anti-Fabrication Rules
- **Safety Validation First**: A `tailored` `ResumeVersion` is persisted **only** after the AI response passes deterministic anti-fabrication safety validation (rejecting fabricated numbers, unearned target skills, or invalid date additions). If AI generation or validation fails, no version is persisted.
- **Original Resume Immutability**: The primary `Resume.content_text` remains untouched and acts as the source of truth. Tailoring operations **never** overwrite `Resume.content_text`.
- **Duplicate / Repeated Tailoring**: Tailoring the same (user, resume, job) combination multiple times creates distinct, immutable `ResumeVersion` snapshots. `GET /resumes/{resume_id}/versions` returns all versions ordered by `created_at` descending, allowing callers to access full history and identify the latest tailored version.

#### Version Retrieval Endpoints
- `GET /resumes/{resume_id}/versions`: Returns all versions for a resume owned by the current user (newest first).
- `GET /resumes/{resume_id}/versions/{version_id}`: Returns a single version snapshot owned by the current user.

#### Limitations & Future Enhancements
- **Current Limitation**: Versions store structured plain text (`content_text`).
- **Future Enhancement**: Rendering tailored text into downloadable PDF/DOCX files.

## Getting Started

This project includes a Flutter mobile app (`lib/`) and FastAPI backend (`hunter-backend/`).

### Running Backend Tests
```bash
cd hunter-backend
python -m pytest -q
```

### Running Flutter Tests & Analyzer
```bash
flutter analyze
flutter test
```

