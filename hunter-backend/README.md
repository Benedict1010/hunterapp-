# Hunter backend

## Authentication & User Foundation (Phase 3B)

- Password hashing is enforced using the secure `bcrypt` algorithm. Plaintext credentials are never saved or log-exposed.
- JSON Web Tokens (JWT) are signed via high-entropy `HS256` keys with localized expiration timeout checks.
- Endpoints:
  - `POST /auth/register` — Validates format inputs, flags duplicate emails, handles registration.
  - `POST /auth/login` — Issues access bearer tokens upon identity confirmation.
  - `GET /users/me` — Protected endpoint returning user details of the authorized context.

## Job Ingestion (Phase 3C)

The production database target remains PostgreSQL. Configure `DATABASE_URL` with a PostgreSQL SQLAlchemy URL and apply migrations with `alembic upgrade head`. SQLite is used only by the isolated test fixtures.

The ingestion pipeline is deliberately independent of HTTP:

```text
JobSourceAdapter -> source-native records -> normalize_job -> validation
    -> external URL / company-title deduplication -> SQLAlchemy persistence
```

`JobSourceAdapter` is the extension boundary for later permitted source integrations. It only needs `name`, optional `base_url`, and `fetch_jobs()`. The current `MockJobSource` plus `MockPartnerJobSource` have no network behavior and provide five distinct realistic roles plus one cross-source duplicate (`Data Harbor` / `Backend Developer`).

Normalization converts source aliases into one `NormalizedJob` shape. Required title, company, external URL, and source are validated before persistence. A listing is skipped if its external URL already exists or its SHA-256 key over whitespace-normalized, case-folded company and title already exists. This recognizes the same role from a second source with a different URL.

## Resume Management & Storage (Phase 3D)

Local file system storage is utilized for development-only purposes. Production infrastructure planning intends to introduce secure object storage variants (e.g., AWS S3).
- **Supported Formats**: `.pdf`, `.docx`
- **Max File Size Limit**: Configurable environment token (Default: 5 MB)
- **Security Constraints**: Endpoints are locked behind secure JWT validation layers. Filenames are translated to random high-entropy UUID representations on the disk to mitigate path traversal risks or overlap attacks. Cross-tenant access controls isolate assets per owner.
- **First-Resume Assignment**: The first uploaded document automatically locks into `is_primary = true`. Subsequent uploads default to `false` unless explicitly overridden.
- **Primary Flipping Strategy**: Flipping a specific document to primary sweeps existing primary markers for that authenticated user context to `false`.

## AI Foundation & Tailoring (Phase 3E.3.1, 3E.3.2 & 3E.3.3)

A provider-agnostic abstraction layer for AI-driven features.
- **Abstraction**: `AIProvider` interface defines contracts for analysis and tailoring.
- **Implementations**:
  - `MockAIProvider`: Deterministic responses for testing/offline dev.
  - `OpenAIProvider`: Real-world analysis and tailoring using GPT models.
- **AI Analysis**: `POST /matches/jobs/{job_id}/analyze` performs a deep comparison between a job and a resume, identifying strengths, missing skills, and providing recommendations.
- **AI Tailoring**: `POST /matches/jobs/{job_id}/tailor` generates a job-aligned tailored resume without modifying the original resume.
- **Anti-Fabrication Safeguards**:
  - Strict system prompt rules instruct models never to fabricate employment, dates, metrics, credentials, or unsupported skills.
  - Post-generation deterministic safety validator checks for newly introduced numbers/metrics, unsupported target job skills, and dates.
  - Rejects unsafe/fabricated responses with HTTP 422 `AITailoringValidationError`.
- **Preservation & Non-Persistence**: `Resume.content_text` is never overwritten. Tailored output is returned transiently in the response payload. Persistent versioning is deferred to future phases.
- **Safety Validation Limitations**: Deterministic validation verifies explicit additions of unsupported numbers, dates, credentials, and target job skills. It does not perform deep semantic equivalence checks or catch subtle phrasing shifts that do not introduce explicit numbers or keywords.
- **Configuration**: Managed via `AI_PROVIDER` (`mock` or `openai`), `AI_API_KEY`, and `AI_MODEL` (e.g., `gpt-4o-mini`).
- **Privacy**: Only necessary resume/job text is sent to the provider. No PII or credentials are leaked.

## Endpoints

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET /users/me`
- `GET /jobs?company=&location=&job_type=&limit=20&offset=0`
- `GET /jobs/{job_id}`
- `POST /jobs/ingest/mock` — development-only manual mock ingestion
- `POST /resumes` — Upload a document (.pdf or .docx)
- `GET /resumes` — List all documents belonging to the authenticated user
- `GET /resumes/{resume_id}` — Fetch single resume document metadata
- `GET /resumes/{resume_id}/download` — Securely stream the binary file attachment
- `PUT /resumes/{resume_id}` — Safely swap file contents and refresh filename indices
- `DELETE /resumes/{resume_id}` — Clean metadata logs and delete files from the disk
- `PATCH /resumes/{resume_id}/primary` — Update the primary active target for that user
- `POST /matches/jobs/{job_id}/analyze` — AI-powered job/resume analysis
- `POST /matches/jobs/{job_id}/tailor` — AI-assisted safe resume tailoring

Run the mock ingestion after starting the API:

```bash
uvicorn app.main:app --reload
curl -X POST http://127.0.0.1:8000/jobs/ingest/mock
```

Run backend tests from this directory with `pytest`. The test suite uses isolated in-memory SQLite databases and never changes the production PostgreSQL configuration.
