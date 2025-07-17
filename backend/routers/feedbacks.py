from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend import crud
from backend import schemas
from backend.database.database import SessionLocal
from typing import Dict, List
from sqlalchemy import func
from backend.database.base import Feedback, User, Solution

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/feedbacks/")
def get_feedbacks(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    """獲取反饋列表"""
    try:
        # 從數據庫獲取反饋
        feedbacks = db.query(
            Feedback, User.username.label('user_name')
        ).join(
            User, User.user_id == Feedback.user_id
        ).offset(skip).limit(limit).all()
        
        # 格式化結果
        result = []
        for feedback, user_name in feedbacks:
            result.append({
                "feedback_id": feedback.feedback_id,
                "user_id": feedback.user_id,
                "user_name": user_name,
                "solution_id": feedback.solution_id,
                "rating": feedback.rating,
                "comment": feedback.comment,
                "created_at": feedback.created_at.strftime("%Y-%m-%d") if feedback.created_at else None,
                "status": feedback.status if hasattr(feedback, 'status') else "待處理"
            })
        
        return result
    except Exception as e:
        print(f"Error in get_feedbacks: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/feedbacks/stats")
def get_feedback_stats(db: Session = Depends(get_db)):
    """獲取反饋統計數據"""
    try:
        # 獲取總數
        total_count = db.query(func.count(Feedback.feedback_id)).scalar() or 0
        
        # 獲取平均評分
        average_rating = db.query(func.avg(Feedback.rating)).scalar() or 0
        
        # 獲取待處理數量 (假設有status欄位)
        pending_count = db.query(func.count(Feedback.feedback_id)).filter(
            Feedback.status == "待處理"
        ).scalar() or 0
        
        # 獲取評分分佈
        rating_distribution = []
        for rating in range(1, 6):
            count = db.query(func.count(Feedback.feedback_id)).filter(
                Feedback.rating == rating
            ).scalar() or 0
            percentage = (count / total_count * 100) if total_count > 0 else 0
            rating_distribution.append({
                "rating": rating,
                "count": count,
                "percentage": percentage
            })
        
        # 獲取問題分類分佈 (這裡需要根據實際數據結構調整)
        # 這裡只是模擬數據
        category_distribution = [
            {"category": "OSPF配置問題", "count": 345, "percentage": 28.0},
            {"category": "BGP路由通告", "count": 287, "percentage": 23.0},
            {"category": "VLAN通信問題", "count": 245, "percentage": 20.0},
            {"category": "ACL規則配置", "count": 187, "percentage": 15.0},
            {"category": "其他問題", "count": 181, "percentage": 14.0},
        ]
        
        return {
            "total_count": total_count,
            "average_rating": float(average_rating),
            "pending_count": pending_count,
            "rating_distribution": rating_distribution,
            "category_distribution": category_distribution
        }
    except Exception as e:
        print(f"Error in get_feedback_stats: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/feedbacks/")
def create_feedback(feedback: Dict, db: Session = Depends(get_db)):
    """創建新反饋"""
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
            "success": True,
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

@router.put("/feedbacks/{feedback_id}/status")
def update_feedback_status(feedback_id: str, status_data: Dict, db: Session = Depends(get_db)):
    """更新反饋狀態"""
    try:
        status = status_data.get("status")
        if not status:
            raise HTTPException(status_code=400, detail="Status is required")
        
        # 獲取反饋
        feedback = db.query(Feedback).filter(Feedback.feedback_id == feedback_id).first()
        if not feedback:
            raise HTTPException(status_code=404, detail=f"Feedback {feedback_id} not found")
        
        # 更新狀態
        feedback.status = status
        db.commit()
        
        return {"success": True, "feedback_id": feedback_id, "status": status}
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"Error in update_feedback_status: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 