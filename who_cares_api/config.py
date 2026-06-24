from pydantic_settings import BaseSettings
import os


class Settings(BaseSettings):
    PIN: str = "123456"
    DB_URL: str = "sqlite:///./data/who_cares.db"

    class Config:
        env_file = ".env"


settings = Settings()
