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
- `GET /applications/{application_id}/external-link`: Dedicated read-only endpoint returning stored `application_url` and `source` for the owner.
- `PATCH /applications/{application_id}`: Updates mutable metadata. Status changes generate timeline history.
- `POST /applications/{application_id}/timeline`: Adds a new timeline event and updates `Application.status`.
- `GET /applications/{application_id}/timeline`: Lists timeline events newest-first.
- `GET /applications/{application_id}/timeline/{timeline_id}`: Retrieves a single timeline event (with IDOR protection).

### External Application Tracking (Phase 3F.3)

#### Job Discovery Source vs Application Source
- **Job Discovery Source (`JobSource`)**: Identifies where Hunter discovered/ingested the job posting (e.g., automated scraper source).
- **Application Source (`Application.source`)**: Normalized lowercase string identifier (e.g., `linkedin`, `naukri`, `internshala`, `unstop`, `company_site`) representing where the user actually completed or submitted their application. Defaults to the job's discovery source name when omitted.

#### Application URL & Security Validation
- **`Application.application_url`**: Stores the external application URL (up to 1000 characters) so the mobile app can launch or return to the external page.
- **URL Validation**: Validates `http://` and `https://` URLs with valid netloc domains. Strictly rejects non-HTTP schemes (`javascript:`, `data:`, `file:`) and malformed strings.
- **Data-Only Storage**: URLs are validated and stored safely as data only. The backend does not perform crawling, scraping, or server-side URL fetching.

#### Limitations & Future Enhancements
- **Current Limitation**: Versions store structured plain text (`content_text`).
- **Future Enhancement**: Rendering tailored text into downloadable PDF/DOCX files.

## Persistent Notifications & Domain Event Integration (Phase 3F.4 & 3F.5)

### Notification Model & Foundation
The `Notification` entity provides persistent in-app notifications for users, storing title, message, notification type, read state (`is_read`), and optional entity references (`related_entity_type`, `related_entity_id`).

#### Key Features & Endpoints
- `POST /notifications`: Creates a notification for the authenticated user (HTTP 201).
- `GET /notifications`: Returns user's notifications ordered newest first with pagination (`limit`, `offset`) and `is_read` filtering.
- `GET /notifications/unread-count`: Returns the current count of unread notifications for the user.
- `PATCH /notifications/read-all`: Marks all unread notifications for the user as read and returns the `updated_count`.
- `GET /notifications/{notification_id}`: Fetches notification detail (owner-only, HTTP 403 for unauthorized access).
- `PATCH /notifications/{notification_id}/read`: Idempotently marks a single notification as read.

#### Domain Event Integration & Transaction Safety
Automated in-app notifications are transactionally generated during core domain operations using `NotificationService`:
1. **Application Status Changes**: Genuine application status transitions (`applied` -> `interview`, `offer`, etc.) generate an `application_status_changed` notification referencing the job title and company. Metadata-only updates or resubmissions of the same status do not produce duplicate notifications.
2. **New Job Matches**: Creation of a newly persisted `JobMatch` generates a `job_match_found` notification referencing the matched job title and company. Re-calculating or requesting an existing match does not produce duplicate notifications.
3. **Successful AI Resume Tailoring**: Creating and persisting a validated `ResumeVersion` generates a `resume_tailored` notification referencing the target job title. If AI generation or safety validation fails, no notification is created.
4. **Transaction Safety**: Notification persistence is strictly atomic and part of the originating database transaction (`commit=False` flush pattern). If the parent operation rolls back, the notification is rolled back consistently.
5. **FCM Delivery**: External FCM push notification delivery remains intentionally deferred to future integration phases.

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

