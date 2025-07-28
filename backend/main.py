import os
import sys
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 使用正確的導入路徑
from backend.database.base import Base
from backend.database.database import engine
from backend.database.routers import users, chat, feedbacks, protocols, knowledge

# Create all database tables
# 只創建不存在的表，不刪除現有表
Base.metadata.create_all(bind=engine)

app = FastAPI()

# 更新CORS設置 - 明確列出所有可能的源
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
    "http://10.0.2.2:8080",
    "http://10.0.2.2",
    "capacitor://localhost",
    "ionic://localhost",
    "*",  # 允許所有來源，僅用於開發環境
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

# Include the routers
app.include_router(users.router, prefix="/api", tags=["Users"])
app.include_router(chat.router, prefix="/api", tags=["Chat"])
app.include_router(feedbacks.router, prefix="/api", tags=["Feedbacks"])
app.include_router(protocols.router, prefix="/api", tags=["Protocols"])
app.include_router(knowledge.router, prefix="/api", tags=["Knowledge"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the AgentAI API"} 