import os
import sys
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 使用正确的导入路径
from backend.database.base import Base
from backend.database.database import engine
from backend.database.routers import users, chat, feedbacks, protocols, knowledge

# Create all database tables
# 只创建不存在的表，不删除现有表
Base.metadata.create_all(bind=engine)

app = FastAPI()

# 更新CORS设置 - 明确列出所有可能的源
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
    "http://10.0.2.2:8080",
    "http://10.0.2.2",
    "capacitor://localhost",
    "ionic://localhost",
    "*",  # 允许所有来源，仅用于开发环境
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