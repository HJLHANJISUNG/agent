import os
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Build paths
dotenv_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=dotenv_path)

# Get database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("No DATABASE_URL environment variable found")

print(f"Using database URL: {DATABASE_URL}")

# Create engine
engine = create_engine(DATABASE_URL, isolation_level="READ COMMITTED")

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine) 