from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://yash:yash@localhost:5432/yash_erp"
    jwt_secret: str = "change-me-in-production-please-use-a-long-random-string"
    access_token_minutes: int = 15
    refresh_token_days: int = 14
    cookie_secure: bool = False
    upload_dir: str = "/data/uploads"
    max_upload_mb: int = 50
    admin_email: str = "admin@yashpowertech.local"
    admin_password: str = "Admin@12345"


settings = Settings()
