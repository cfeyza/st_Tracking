from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEFAULT_JWT_SECRET = "change-this-to-a-long-random-string"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str = "postgresql+asyncpg://student_tracking_user:changeme@localhost:5432/student_tracking"

    JWT_SECRET_KEY: str = _DEFAULT_JWT_SECRET
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    VERIFICATION_BASE_URL: str = "http://localhost:8000"
    EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS: int = 48

    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = "no-reply@studenttracking.app"
    SMTP_USE_TLS: bool = True

    CORS_ORIGINS: str = "*"

    FIREBASE_CREDENTIALS_PATH: str = "firebase-service-account.json"

    @model_validator(mode="after")
    def _require_jwt_secret(self) -> "Settings":
        if self.JWT_SECRET_KEY == _DEFAULT_JWT_SECRET:
            raise RuntimeError(
                "JWT_SECRET_KEY is still the insecure default value. "
                "Set a strong secret in your .env file: "
                "python -c \"import secrets; print(secrets.token_hex(32))\""
            )
        return self

    @property
    def cors_origin_list(self) -> list[str]:
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
