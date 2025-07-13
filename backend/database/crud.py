from sqlalchemy.orm import Session
from . import base as models # Rename import for consistency
from . import schemas
import bcrypt

# Utility for password hashing
def get_password_hash(password):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# User CRUD
def get_user(db: Session, user_id: str):
    return db.query(models.User).filter(models.User.user_id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    db_user = models.User(
        user_id=user.user_id,
        email=user.email, 
        username=user.username,
        hashed_password=user.hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# Question CRUD
def create_question(db: Session, question: schemas.QuestionCreate, user_id: str):
    db_question = models.Question(**question.dict(), user_id=user_id)
    db.add(db_question)
    db.commit()
    db.refresh(db_question)
    return db_question

# Solution CRUD
def create_solution(db: Session, solution: schemas.SolutionCreate):
    db_solution = models.Solution(**solution.dict())
    db.add(db_solution)
    db.commit()
    db.refresh(db_solution)
    return db_solution

# Feedback CRUD
def create_feedback(db: Session, feedback: schemas.FeedbackCreate):
    db_feedback = models.Feedback(**feedback.dict())
    db.add(db_feedback)
    db.commit()
    db.refresh(db_feedback)
    return db_feedback

# Protocol CRUD
def get_protocol(db: Session, protocol_id: str):
    return db.query(models.Protocol).filter(models.Protocol.protocol_id == protocol_id).first()

def create_protocol(db: Session, protocol: schemas.ProtocolCreate):
    db_protocol = models.Protocol(**protocol.dict())
    db.add(db_protocol)
    db.commit()
    db.refresh(db_protocol)
    return db_protocol

# Knowledge CRUD
def get_knowledge(db: Session, knowledge_id: str):
    return db.query(models.Knowledge).filter(models.Knowledge.knowledge_id == knowledge_id).first()

def create_knowledge(db: Session, knowledge: schemas.KnowledgeCreate):
    db_knowledge = models.Knowledge(**knowledge.dict())
    db.add(db_knowledge)
    db.commit()
    db.refresh(db_knowledge)
    return db_knowledge 