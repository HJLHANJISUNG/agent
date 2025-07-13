from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import crud, schemas
from ..database.database import SessionLocal
from typing import Dict

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/feedbacks/")
def create_feedback(feedback: Dict, db: Session = Depends(get_db)):
    print(f"Received feedback: {feedback}")
    
    try:
        # 檢查必要參數
        user_id = feedback.get("user_id")
        solution_id = feedback.get("solution_id")
        rating = feedback.get("rating")
        comment = feedback.get("comment", "")
        
        if not user_id or not solution_id or rating is None:
            raise HTTPException(status_code=400, detail="user_id, solution_id and rating are required")
        
        # 檢查用戶和解決方案是否存在
        db_user = crud.get_user(db, user_id=user_id)
        db_solution = crud.get_solution(db, solution_id=solution_id)
        
        if not db_user:
            raise HTTPException(status_code=404, detail=f"User {user_id} not found")
        
        if not db_solution:
            raise HTTPException(status_code=404, detail=f"Solution {solution_id} not found")
        
        # 創建反饋
        feedback_schema = schemas.FeedbackCreate(
            solution_id=solution_id,
            user_id=user_id,
            rating=rating,
            comment=comment
        )
        db_feedback = crud.create_feedback(db=db, feedback=feedback_schema)
        print(f"Created feedback: {db_feedback.feedback_id}")
        
        # 回傳回應
        return {
            "feedback_id": db_feedback.feedback_id,
            "solution_id": solution_id,
            "user_id": user_id,
            "rating": rating,
            "comment": comment
        }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"Error in create_feedback: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 