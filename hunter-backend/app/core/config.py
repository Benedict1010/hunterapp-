import os


class Settings:
    """Runtime settings. PostgreSQL remains the production default."""

    database_url = os.getenv(
        "DATABASE_URL", "postgresql+psycopg://hunter:hunter@localhost:5432/hunter"
    )
    jwt_secret = os.getenv("JWT_SECRET", "dev_fallback_secret_key_change_in_production")
    jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
    jwt_expire_minutes = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))

    resume_upload_dir = os.getenv("RESUME_UPLOAD_DIR", "uploads/resumes")
    max_resume_file_size = int(os.getenv("MAX_RESUME_FILE_SIZE", str(5 * 1024 * 1024))) # 5 MB default

    ai_provider = os.getenv("AI_PROVIDER", "mock")
    ai_api_key = os.getenv("AI_API_KEY", "")
    ai_model = os.getenv("AI_MODEL", "gpt-4o-mini")


settings = Settings()
