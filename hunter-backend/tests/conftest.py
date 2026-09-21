import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
# Use a shared cache in-memory URL
os.environ["DATABASE_URL"] = "sqlite:///file:testdb?mode=memory&cache=shared"

import app.core.database as db_mod
from app.core.database import Base, get_db

# Override the engine in app.core.database to use StaticPool for tests
db_mod.engine = create_engine(
    os.environ["DATABASE_URL"],
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
db_mod.SessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=db_mod.engine
)

# Import models to ensure they are registered on Base.metadata
import app.models  # noqa
from app.main import app as fastapi_app


@pytest.fixture()
def database():
    Base.metadata.create_all(bind=db_mod.engine)
    session = db_mod.SessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=db_mod.engine)


@pytest.fixture()
def client(database):
    def override_db():
        yield database

    fastapi_app.dependency_overrides[get_db] = override_db
    with TestClient(fastapi_app) as test_client:
        yield test_client
    fastapi_app.dependency_overrides.clear()
