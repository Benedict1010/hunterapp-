# Hunter backend

## Job ingestion (Phase 3C)

The production database target remains PostgreSQL. Configure `DATABASE_URL` with a PostgreSQL SQLAlchemy URL and apply migrations with `alembic upgrade head`. SQLite is used only by the isolated test fixtures.

The ingestion pipeline is deliberately independent of HTTP:

```text
JobSourceAdapter -> source-native records -> normalize_job -> validation
    -> external URL / company-title deduplication -> SQLAlchemy persistence
```

`JobSourceAdapter` is the extension boundary for later permitted source integrations. It only needs `name`, optional `base_url`, and `fetch_jobs()`. The current `MockJobSource` plus `MockPartnerJobSource` have no network behavior and provide five distinct realistic roles plus one cross-source duplicate (`Data Harbor` / `Backend Developer`).

Normalization converts source aliases into one `NormalizedJob` shape. Required title, company, external URL, and source are validated before persistence. A listing is skipped if its external URL already exists or its SHA-256 key over whitespace-normalized, case-folded company and title already exists. This recognizes the same role from a second source with a different URL.

## Endpoints

- `GET /health`
- `GET /jobs?company=&location=&job_type=&limit=20&offset=0`
- `GET /jobs/{job_id}`
- `POST /jobs/ingest/mock` — development-only manual mock ingestion

Run the mock ingestion after starting the API:

```bash
uvicorn app.main:app --reload
curl -X POST http://127.0.0.1:8000/jobs/ingest/mock
```

Run backend tests from this directory with `pytest`. The test suite uses isolated in-memory SQLite databases and never changes the production PostgreSQL configuration.
