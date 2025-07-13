import os
from dotenv import load_dotenv
from pathlib import Path

# Build a reliable path to the .env file
dotenv_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=dotenv_path)

class Settings:
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    KIMI_API_KEY: str = os.getenv("KIMI_API_KEY")

settings = Settings()

if settings.DATABASE_URL is None:
    raise ValueError("FATAL ERROR: DATABASE_URL is not set. Please check your .env file.")

if settings.KIMI_API_KEY is None:
    raise ValueError("FATAL ERROR: KIMI_API_KEY is not set. Please check your .env file.") 