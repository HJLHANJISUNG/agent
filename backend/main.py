import os
import sys
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database.base import Base
from .database.database import engine
from .routers import users, chat, feedbacks, protocols, knowledge

# Create all database tables
Base.metadata.create_all(bind=engine)

app = FastAPI()

# Set up CORS
origins = ["*"] # Allow all origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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