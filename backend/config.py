import os
from dotenv import load_dotenv
from pathlib import Path

# Build a reliable path to the .env file
dotenv_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=dotenv_path)

class Settings:
    # 使用默認值作為備用
    DATABASE_URL: str = os.getenv("DATABASE_URL", "mysql+mysqlconnector://root:123456@localhost:3306/agentai_db")
    KIMI_API_KEY: str = os.getenv("KIMI_API_KEY", "your-api-key-here")

settings = Settings()

# 使用警告而不是錯誤
if settings.DATABASE_URL == "mysql+mysqlconnector://root:123456@localhost:3306/agentai_db":
    print("WARNING: Using default DATABASE_URL. Consider setting it in .env file.")

if settings.KIMI_API_KEY == "your-api-key-here":
    print("WARNING: Using default KIMI_API_KEY. Consider setting it in .env file.") 