import os
from pathlib import Path
from dotenv import load_dotenv

# Resolve .env relative to the backend project directory
BACKEND_DIR = Path(__file__).resolve().parents[2]
ENV_PATH = BACKEND_DIR / ".env"

if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH, override=False)


def parse_cors_origins(origins_str: str) -> list[str]:
    if not origins_str:
        return [
            "http://localhost:3000",
            "http://localhost:8080",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080",
        ]
    return [origin.strip() for origin in origins_str.split(",") if origin.strip()]


class Settings:
    """Runtime settings. PostgreSQL remains the production default."""

    def __init__(self) -> None:
        self.database_url = os.getenv(
            "DATABASE_URL",
            "postgresql+psycopg://hunter:hunter@localhost:5432/hunter",
        )
        self.jwt_secret = os.getenv(
            "JWT_SECRET", "dev_fallback_secret_key_change_in_production"
        )
        self.jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
        self.jwt_expire_minutes = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))

        self.resume_upload_dir = os.getenv("RESUME_UPLOAD_DIR", "uploads/resumes")
        self.max_resume_file_size = int(
            os.getenv("MAX_RESUME_FILE_SIZE", str(5 * 1024 * 1024))
        )  # 5 MB default

        self.ai_provider = os.getenv("AI_PROVIDER", "mock")
        self.ai_api_key = os.getenv("AI_API_KEY", "")
        self.ai_model = os.getenv("AI_MODEL", "gpt-4o-mini")

        self.cors_origins = parse_cors_origins(os.getenv("CORS_ORIGINS", ""))


settings = Settings()
