# Hunter AI Job Hunter - Technical Architecture

## 1. System Overview

Hunter is an AI-powered job search and application management system. It automates the process of finding jobs, tailoring resumes, and tracking applications.

### High-Level Architecture
```text
+-----------------------+      HTTPS/REST      +-----------------------+
|   Flutter Mobile App  | <------------------> |    FastAPI Backend    |
|   (iOS & Android)     |          JSON        |       (Python)        |
+-----------------------+                      +-----------+-----------+
                                                           |
                                                           | SQLAlchemy ORM
                                                           v
                                               +-----------+-----------+
                                               |  PostgreSQL Database  |
                                               +-----------+-----------+
                                                           |
                                            +--------------+--------------+
                                            |                             |
                                  +---------+---------+        +----------+----------+
                                  |   AI Services     |        |   Background Tasks  |
                                  | (OpenAI/Claude)   |        | (Celery/Redis)      |
                                  +-------------------+        +---------------------+
```

## 2. Flutter Frontend Architecture

The frontend follows a **Feature-First Architecture** combined with clean architecture principles within each feature.

- **`lib/app/`**: Global configuration, routing, and theme.
- **`lib/core/`**: Reusable widgets, constants, utilities, and base classes.
- **`lib/features/`**: Divided by functional modules. Each feature contains:
    - `presentation/`: Widgets and UI state management (Controllers/Blocs).
    - `domain/`: Business logic, entities, and repository interfaces.
    - `data/`: API clients, repository implementations, and DTOs.

## 3. FastAPI Backend Architecture

The backend is built with FastAPI for high performance and rapid development.

- **Router-based modularity**: Features are grouped into APIRouters (e.g., `/jobs`, `/resumes`, `/users`).
- **Dependency Injection**: Used for database sessions and authentication.
- **Pydantic**: For data validation and serialization.
- **SQLAlchemy 2.0**: As the ORM for database interactions.

## 4. PostgreSQL Database Role

PostgreSQL serves as the primary relational data store, ensuring data integrity and supporting complex queries for job matching and analytics.

## 5. Authentication Architecture

- **Mechanism**: JWT (JSON Web Tokens).
- **Flow**:
    1. User submits credentials.
    2. Backend validates and issues Access + Refresh tokens.
    3. Flutter app stores tokens securely (e.g., `flutter_secure_storage`).
    4. Flutter app includes Bearer token in subsequent requests.

## 6. User/Profile Architecture

- Manages user identity, contact information, and professional details.
- Linked to `JobPreferences` to drive the matching engine.

## 7. Resume Architecture

- Supports multiple resumes per user.
- **ResumeVersion**: Tracks history and AI-tailored variations for specific job applications.
- Store PDF/Docx files in object storage (e.g., AWS S3) with metadata in PostgreSQL.

## 8. Job-Source Integration Architecture

- Modular "Scraper/Ingestor" pattern.
- Supports external APIs (LinkedIn, Indeed, etc.) and direct web scraping.
- Abstraction layer to normalize data from different sources.

## 9. Job Storage and Deduplication

- Jobs are stored in a centralized `Job` table.
- **Deduplication**: Uses a combination of Job URL, Company Name, and Title hashing to identify duplicate listings across sources.

## 10. Job Matching Architecture

- Compares `JobPreferences` and `Resume` content against `Job` requirements.
- Uses vector embeddings (via pgvector or external service) for semantic matching.
- Provides a "Match Score" for each job relative to the user.

## 11. AI Resume Tailoring Architecture

- Utilizes LLMs (OpenAI GPT or Anthropic Claude) to analyze job descriptions.
- Suggests modifications to the user's base resume to highlight relevant skills.
- Generates `ResumeVersion` specific to an `Application`.

## 12. Application Tracking Architecture

- Tracks the lifecycle of a job application: `Applied` -> `Interviewing` -> `Offered` -> `Rejected`.
- **ApplicationTimeline**: Captures every state change and user note.

## 13. Notification Architecture

- Supports Push Notifications (FCM) and In-app notifications.
- Triggered by job matches, status updates, or system alerts.

## 14. Background Job-Search Architecture

- Asynchronous workers (Celery) periodically poll job sources.
- Processes job matching in the background to avoid blocking the API.

## 15. API Layer Structure

- `GET /jobs`: List/filter jobs.
- `POST /applications`: Apply for a job.
- `GET /profile`: User data.
- Standardized error responses and pagination.

## 16. Security Considerations

- HTTPS for all communications.
- Input validation on both Frontend and Backend.
- CORS configuration to restrict API access.
- Secure storage for sensitive data on device.

## 17. Development Environment

- **Frontend**: Flutter SDK, VS Code/Android Studio.
- **Backend**: Python 3.10+, FastAPI, Uvicorn.
- **Database**: PostgreSQL (Dockerized).
- **Version Control**: Git (GitHub).

## 18. Production Deployment Architecture

- **Frontend**: Google Play Store / Apple App Store.
- **Backend**: Containerized (Docker) on AWS/GCP/DigitalOcean.
- **Database**: Managed PostgreSQL instance.

## 19. Data Flow Diagrams

### Job Ingestion Flow
```text
[Job Source] -> [Scraper/Worker] -> [Normalization] -> [Deduplication] -> [PostgreSQL]
                                                                            |
                                                                    [Match Engine] -> [Notification]
```

### Application Flow
```text
[User] -> [Select Job] -> [AI Tailoring] -> [Generate PDF] -> [Submit App] -> [Track Timeline]
```

## 20. Proposed Project Folder Structure

### Backend (Proposed)
```text
hunter-backend/
├── app/
│   ├── api/          # Endpoints
│   ├── core/         # Config, security
│   ├── crud/         # DB operations
│   ├── models/       # SQLAlchemy models
│   ├── schemas/      # Pydantic models
│   ├── services/     # Business logic (AI, Scrapers)
│   └── main.py
├── tests/
└── alembic/          # Migrations
```

## 21. Phase 3 Implementation Sequence

1.  **Phase 3A**: Architecture Documentation (Current).
2.  **Phase 3B**: Backend Foundation (FastAPI, PostgreSQL setup, Basic Auth).
3.  **Phase 3C**: Job Ingestion Service (Mock sources first).
4.  **Phase 3D**: Resume Management & Storage.
5.  **Phase 3E**: Job Matching & AI Tailoring integration.
6.  **Phase 3F**: Application Tracking & Notifications.
7.  **Phase 3G**: Flutter Integration (Connect UI to real API).

---

## Database Entities & Relationships

### User
- `id`: UUID
- `email`: String (Unique)
- `hashed_password`: String
- `full_name`: String
- `created_at`: DateTime

### Resume
- `id`: UUID
- `user_id`: FK(User)
- `file_url`: String
- `content_text`: Text (Extracted for AI)
- `is_primary`: Boolean

### ResumeVersion
- `id`: UUID
- `resume_id`: FK(Resume)
- `job_id`: FK(Job)
- `modified_content`: Text
- `file_url`: String

### Job
- `id`: UUID
- `title`: String
- `company`: String
- `location`: String
- `description`: Text
- `salary_range`: String
- `source_id`: FK(JobSource)
- `external_url`: String
- `posted_at`: DateTime

### JobSource
- `id`: UUID
- `name`: String (e.g., LinkedIn, Indeed)
- `base_url`: String

### JobSkill
- `id`: UUID
- `job_id`: FK(Job)
- `name`: String
- `importance`: Float

### JobPreference
- `id`: UUID
- `user_id`: FK(User)
- `preferred_roles`: List[String]
- `preferred_locations`: List[String]
- `min_salary`: Integer

### JobMatch
- `id`: UUID
- `user_id`: FK(User)
- `job_id`: FK(Job)
- `score`: Float
- `status`: Enum (New, Interested, Dismissed)

### Application
- `id`: UUID
- `user_id`: FK(User)
- `job_id`: FK(Job)
- `resume_version_id`: FK(ResumeVersion)
- `status`: Enum (Applied, Interviewing, Offered, Rejected)
- `applied_at`: DateTime

### ApplicationTimeline
- `id`: UUID
- `application_id`: FK(Application)
- `status`: Enum
- `notes`: Text
- `created_at`: DateTime

### Notification
- `id`: UUID
- `user_id`: FK(User)
- `title`: String
- `message`: Text
- `is_read`: Boolean
- `type`: String
- `created_at`: DateTime
