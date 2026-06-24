from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from config import settings

engine = create_engine(
    settings.DB_URL,
    connect_args={"check_same_thread": False},  # SQLite only
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    from models.db_models import (  # noqa: F401 – import triggers table creation
        Balance, Transaction, WatchlistItem, ScheduleItem, NewsItem,
    )
    Base.metadata.create_all(bind=engine)

    # Seed initial data if tables are empty
    from services.seed_data import seed_all
    db = SessionLocal()
    try:
        seed_all(db)
    finally:
        db.close()
