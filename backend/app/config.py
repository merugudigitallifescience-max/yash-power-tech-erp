from urllib.parse import quote

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://yash:yash@localhost:5432/yash_erp"
    storage: str = "local"          # local = files on disk; db = bytes in Postgres
    static_dir: str = "/app/static"  # built web app (single-service deploys)

    @field_validator("database_url")
    @classmethod
    def use_psycopg(cls, v: str) -> str:
        # Hosts like Render hand out postgres:// or postgresql:// URLs.
        for prefix in ("postgres://", "postgresql://"):
            if v.startswith(prefix):
                return "postgresql+psycopg://" + v[len(prefix):]
        return v

    db_password: str | None = None  # optional: raw password inserted into a password-less DATABASE_URL

    @model_validator(mode="after")
    def insert_password(self):
        if self.db_password:
            scheme, rest = self.database_url.split("://", 1)
            userinfo, hostpart = rest.split("@", 1)
            user = userinfo.split(":", 1)[0]
            self.database_url = f"{scheme}://{user}:{quote(self.db_password, safe='')}@{hostpart}"
        return self
    jwt_secret: str = "change-me-in-production-please-use-a-long-random-string"
    access_token_minutes: int = 15
    refresh_token_days: int = 14
    cookie_secure: bool = False
    upload_dir: str = "/data/uploads"
    max_upload_mb: int = 50
    admin_email: str = "admin@yashpowertech.local"
    admin_password: str = "Admin@12345"


settings = Settings()
