import os
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys

sys.path.append(str(Path(__file__).parent.parent))
from config import settings

# 使用 config.py 中的设置
DATABASE_URL = settings.DATABASE_URL
print(f"Using database URL: {DATABASE_URL}")

# Create engine
engine = create_engine(DATABASE_URL, isolation_level="READ COMMITTED")

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine) 