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

## Application Tracking & Timeline (Phase 3F.1 & 3F.2)

### Application Model & ResumeVersion Link
An `Application` represents a user's application to a specific job and captures the exact `ResumeVersion` used for that application.

#### Core Relationship
```text
User
 ├── Job
 ├── Resume
 │    └── ResumeVersion
 │
 └── Application
       ├── Job
       ├── ResumeVersion
       └── ApplicationTimeline (History)
```

### Current Status vs Application Timeline
- **`Application.status`**: Represents the current state of an application.
- **`ApplicationTimeline`**: Append-only historical event log capturing every state transition (`applied`, `viewed`, `interview`, `offer`, `rejected`, `withdrawn`).

#### Automatic Initial Event & Status Transitions
- Creating an application (`POST /applications`) automatically creates an initial `ApplicationTimeline` event (defaulting to `applied` or the supplied initial status) within the same database transaction.
- Updating an application's status via `PATCH /applications/{application_id}` or adding a timeline event via `POST /applications/{application_id}/timeline` records a new historical event and updates `Application.status` transactionally.
- Updating metadata-only fields (`application_url`, `source`, `applied_at`) or resubmitting the existing status does not generate duplicate timeline events.

#### Application & Timeline Endpoints
- `POST /applications`: Creates an application linked to `job_id` and `resume_version_id` owned by the user, creating an initial timeline event.
- `GET /applications`: Lists applications belonging to the authenticated user with optional `status` filtering.
- `GET /applications/{application_id}`: Fetches application detail for the owner.
- `PATCH /applications/{application_id}`: Updates mutable metadata. Status changes generate timeline history.
- `POST /applications/{application_id}/timeline`: Adds a new timeline event and updates `Application.status`.
- `GET /applications/{application_id}/timeline`: Lists timeline events newest-first.
- `GET /applications/{application_id}/timeline/{timeline_id}`: Retrieves a single timeline event (with IDOR protection).

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

