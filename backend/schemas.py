from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

# User schemas
class UserBase(BaseModel):
    username: str
    email: str

class UserCreate(BaseModel):
    user_id: str
    username: str
    email: str
    hashed_password: str

class User(BaseModel):
    user_id: str
    username: str
    email: str
    register_date: datetime

    class Config:
        from_attributes = True

# Question schemas
class QuestionBase(BaseModel):
    content: str
    image_url: Optional[str] = None
    file_url: Optional[str] = None
    file_name: Optional[str] = None

class QuestionCreate(QuestionBase):
    pass

class Question(QuestionBase):
    question_id: str
    user_id: str
    ask_time: datetime

    class Config:
        from_attributes = True

# Solution schemas
class SolutionBase(BaseModel):
    steps: str
    confidence_score: float

class SolutionCreate(SolutionBase):
    question_id: str

class Solution(SolutionBase):
    solution_id: str
    question_id: str

    class Config:
        from_attributes = True

# Feedback schemas
class FeedbackBase(BaseModel):
    rating: int
    comment: Optional[str] = None

class FeedbackCreate(FeedbackBase):
    user_id: str
    solution_id: str

class Feedback(FeedbackBase):
    feedback_id: str
    user_id: str
    solution_id: str

    class Config:
        from_attributes = True

# Protocol schemas
class ProtocolBase(BaseModel):
    name: str
    rfc_number: Optional[str] = None

class ProtocolCreate(ProtocolBase):
    pass

class Protocol(ProtocolBase):
    protocol_id: str

    class Config:
        from_attributes = True

# Knowledge schemas
class KnowledgeBase(BaseModel):
    content: str
    source: Optional[str] = None

class KnowledgeCreate(KnowledgeBase):
    protocol_id: str

class Knowledge(KnowledgeBase):
    knowledge_id: str
    protocol_id: str
    update_time: datetime

    class Config:
        from_attributes = True 