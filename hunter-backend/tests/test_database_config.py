import os
from unittest.mock import patch
from sqlalchemy import create_engine

from app.core.config import Settings, parse_cors_origins
from app.core.database import _connect_args


def test_postgres_default_database_url_and_settings():
    with patch.dict(os.environ, {}, clear=True):
        settings = Settings()
        assert "postgresql+psycopg://" in settings.database_url
        assert settings.jwt_algorithm == "HS256"


def test_connect_args_handles_sqlite_and_postgres():
    assert _connect_args("sqlite:///./test.db") == {"check_same_thread": False}
    assert _connect_args("postgresql+psycopg://user:pass@localhost:5432/db") == {}


def test_engine_has_pool_pre_ping_enabled():
    settings = Settings()
    test_engine = create_engine(
        settings.database_url,
        connect_args=_connect_args(settings.database_url),
        pool_pre_ping=True,
    )
    assert test_engine.pool._pre_ping is True


def test_parse_cors_origins_defaults_and_custom():
    default_origins = parse_cors_origins("")
    assert "http://localhost:3000" in default_origins
    assert "http://127.0.0.1:8080" in default_origins

    custom_origins = parse_cors_origins("http://example.com, http://app.hunter.local")
    assert custom_origins == ["http://example.com", "http://app.hunter.local"]


def test_cors_middleware_headers_on_health_request(client):
    res = client.options(
        "/health",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert res.status_code == 200
    assert res.headers.get("access-control-allow-origin") == "http://localhost:3000"


def test_environment_variable_precedence():
    with patch.dict(os.environ, {"CORS_ORIGINS": "https://custom.hunter.com"}):
        s = Settings()
        assert s.cors_origins == ["https://custom.hunter.com"]
