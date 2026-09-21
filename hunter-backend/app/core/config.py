import os


class Settings:
    """Runtime settings. PostgreSQL remains the production default."""

    database_url = os.getenv(
        "DATABASE_URL", "postgresql+psycopg://hunter:hunter@localhost:5432/hunter"
    )
    jwt_secret = os.getenv("JWT_SECRET", "dev_fallback_secret_key_change_in_production")
    jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
    jwt_expire_minutes = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))


settings = Settings()
