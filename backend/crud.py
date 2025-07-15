from sqlalchemy.orm import Session
import models
from database.base import User, Question, Solution, Feedback, Protocol, Knowledge
import schemas
import uuid
from datetime import datetime

# --- User ---
def get_user(db: Session, user_id: str):
    return db.query(User).filter(User.user_id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    db_user = User(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# --- Question & Solution ---
def get_question(db: Session, question_id: str):
    return db.query(Question).filter(Question.question_id == question_id).first()

def get_questions(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Question).offset(skip).limit(limit).all()

def create_question(db: Session, question: schemas.QuestionCreate, user_id: str):
    question_id = str(uuid.uuid4())
    db_question = Question(
        question_id=question_id,
        user_id=user_id,
        content=question.content,
        image_url=question.image_url,
        file_url=question.file_url,
        file_name=question.file_name,
        ask_time=datetime.now()
    )
    db.add(db_question)
    db.commit()
    db.refresh(db_question)
    return db_question

def get_solution(db: Session, solution_id: str):
    return db.query(Solution).filter(Solution.solution_id == solution_id).first()

def get_solutions(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Solution).offset(skip).limit(limit).all()

def create_solution(db: Session, solution: schemas.SolutionCreate):
    solution_id = str(uuid.uuid4())
    db_solution = Solution(
        solution_id=solution_id,
        question_id=solution.question_id,
        steps=solution.steps,
        confidence_score=solution.confidence_score
    )
    db.add(db_solution)
    db.commit()
    db.refresh(db_solution)
    return db_solution

# --- Feedback ---
def create_feedback(db: Session, feedback: schemas.FeedbackCreate):
    feedback_id = str(uuid.uuid4())
    db_feedback = Feedback(
        feedback_id=feedback_id,
        user_id=feedback.user_id,
        solution_id=feedback.solution_id,
        rating=feedback.rating,
        comment=feedback.comment
    )
    db.add(db_feedback)
    db.commit()
    db.refresh(db_feedback)
    return db_feedback 