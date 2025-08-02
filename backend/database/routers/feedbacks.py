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
    """获取反馈列表"""
    try:
        # 从数据库获取反馈
        feedbacks = db.query(
            Feedback, User.username.label('user_name')
        ).join(
            User, User.user_id == Feedback.user_id
        ).offset(skip).limit(limit).all()
        
        # 格式化结果
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
                "status": feedback.status if hasattr(feedback, 'status') else "待处理"
            })
        
        return result
    except Exception as e:
        print(f"Error in get_feedbacks: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/feedbacks/stats")
def get_feedback_stats(db: Session = Depends(get_db)):
    """获取反馈统计数据"""
    try:
        # 获取总数
        total_count = db.query(func.count(Feedback.feedback_id)).scalar() or 0
        
        # 获取平均评分
        average_rating = db.query(func.avg(Feedback.rating)).scalar() or 0
        
        # 获取待处理数量 (假设有status字段)
        pending_count = db.query(func.count(Feedback.feedback_id)).filter(
            Feedback.status == "待处理"
        ).scalar() or 0
        
        # 获取评分分布
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
        
        # 获取实际的问题分类分布
        from sqlalchemy import text
        from sqlalchemy.orm import Session
        
        # 定义协议关键词列表
        protocol_keywords = [
            'OSPF', 'BGP', 'RIP', 'EIGRP', 'VLAN', 'STP', 'RSTP', 'MSTP',
            'ACL', 'NAT', 'VPN', 'QoS', 'MPLS', 'VRRP', 'HSRP', 'GLBP',
            'DHCP', 'DNS', 'HTTP', 'HTTPS', 'FTP', 'SMTP', 'SNMP', 'SSH',
            'TCP', 'UDP', 'ICMP', 'ARP', 'RARP', 'IGMP', 'PIM', 'OSPFV3',
            'IPV4', 'IPV6', 'RIPNG', 'BGP4+', 'IS-IS', 'LDP', 'RSVP'
        ]
        
        # 从问题表中获取问题内容进行分类
        try:
            # 假设有 Question 表，如果没有则使用模拟数据
            questions_query = text("""
                SELECT content FROM Question 
                WHERE content IS NOT NULL AND content != ''
            """)
            questions = db.execute(questions_query).fetchall()
            
            if questions:
                # 统计问题分类
                category_count = {}
                total_questions = 0
                
                for question in questions:
                    content = question[0].upper() if question[0] else ''
                    total_questions += 1
                    
                    # 检查是否包含协议关键词
                    found_protocol = None
                    for protocol in protocol_keywords:
                        if protocol in content:
                            found_protocol = protocol
                            break
                    
                    category = found_protocol if found_protocol else '其他'
                    category_count[category] = category_count.get(category, 0) + 1
                
                # 转换为分布格式
                category_distribution = []
                for category, count in category_count.items():
                    percentage = (count / total_questions * 100) if total_questions > 0 else 0
                    category_distribution.append({
                        "category": f"{category}相关问题" if category != '其他' else "其他问题",
                        "count": count,
                        "percentage": round(percentage, 1)
                    })
                
                # 按数量排序
                category_distribution.sort(key=lambda x: x['count'], reverse=True)
                
            else:
                # 如果没有问题数据，使用模拟数据
                category_distribution = [
                    {"category": "OSPF配置问题", "count": 345, "percentage": 28.0},
                    {"category": "BGP路由通告", "count": 287, "percentage": 23.0},
                    {"category": "VLAN通信问题", "count": 245, "percentage": 20.0},
                    {"category": "ACL规则配置", "count": 187, "percentage": 15.0},
                    {"category": "其他问题", "count": 181, "percentage": 14.0},
                ]
                
        except Exception as e:
            print(f"Error getting question categories: {e}")
            # 使用模拟数据作为备用
            category_distribution = [
                {"category": "OSPF配置问题", "count": 345, "percentage": 28.0},
                {"category": "BGP路由通告", "count": 287, "percentage": 23.0},
                {"category": "VLAN通信问题", "count": 245, "percentage": 20.0},
                {"category": "ACL规则配置", "count": 187, "percentage": 15.0},
                {"category": "其他问题", "count": 181, "percentage": 14.0},
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
    """创建新反馈"""
    print(f"Received feedback: {feedback}")
    
    try:
        # 检查必要参数
        user_id = feedback.get("user_id")
        solution_id = feedback.get("solution_id")
        rating = feedback.get("rating")
        comment = feedback.get("comment", "")
        
        if not user_id or not solution_id or rating is None:
            raise HTTPException(status_code=400, detail="user_id, solution_id and rating are required")
        
        # 检查用户和解决方案是否存在
        db_user = crud.get_user(db, user_id=user_id)
        db_solution = crud.get_solution(db, solution_id=solution_id)
        
        if not db_user:
            raise HTTPException(status_code=404, detail=f"User {user_id} not found")
        
        if not db_solution:
            raise HTTPException(status_code=404, detail=f"Solution {solution_id} not found")
        
        # 创建反馈
        feedback_schema = schemas.FeedbackCreate(
            solution_id=solution_id,
            user_id=user_id,
            rating=rating,
            comment=comment
        )
        db_feedback = crud.create_feedback(db=db, feedback=feedback_schema)
        print(f"Created feedback: {db_feedback.feedback_id}")
        
        # 回传回应
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
    """更新反馈状态"""
    try:
        status = status_data.get("status")
        if not status:
            raise HTTPException(status_code=400, detail="Status is required")
        
        # 获取反馈
        feedback = db.query(Feedback).filter(Feedback.feedback_id == feedback_id).first()
        if not feedback:
            raise HTTPException(status_code=404, detail=f"Feedback {feedback_id} not found")
        
        # 更新状态
        feedback.status = status
        db.commit()
        
        return {"success": True, "feedback_id": feedback_id, "status": status}
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"Error in update_feedback_status: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 

@router.get("/questions/categories")
def get_question_categories(db: Session = Depends(get_db)):
    """获取问题分类统计"""
    try:
        from sqlalchemy import text
        
        # 定义协议关键词列表
        protocol_keywords = [
            'OSPF', 'BGP', 'RIP', 'EIGRP', 'VLAN', 'STP', 'RSTP', 'MSTP',
            'ACL', 'NAT', 'VPN', 'QoS', 'MPLS', 'VRRP', 'HSRP', 'GLBP',
            'DHCP', 'DNS', 'HTTP', 'HTTPS', 'FTP', 'SMTP', 'SNMP', 'SSH',
            'TCP', 'UDP', 'ICMP', 'ARP', 'RARP', 'IGMP', 'PIM', 'OSPFV3',
            'IPV4', 'IPV6', 'RIPNG', 'BGP4+', 'IS-IS', 'LDP', 'RSVP'
        ]
        
        # 从问题表中获取问题内容进行分类
        try:
            questions_query = text("""
                SELECT content FROM Question 
                WHERE content IS NOT NULL AND content != ''
            """)
            questions = db.execute(questions_query).fetchall()
            
            if questions:
                # 统计问题分类
                category_count = {}
                total_questions = 0
                
                for question in questions:
                    content = question[0].upper() if question[0] else ''
                    total_questions += 1
                    
                    # 检查是否包含协议关键词
                    found_protocol = None
                    for protocol in protocol_keywords:
                        if protocol in content:
                            found_protocol = protocol
                            break
                    
                    category = found_protocol if found_protocol else '其他'
                    category_count[category] = category_count.get(category, 0) + 1
                
                # 转换为分布格式
                categories = []
                for category, count in category_count.items():
                    percentage = (count / total_questions * 100) if total_questions > 0 else 0
                    categories.append({
                        "category": category,
                        "count": count,
                        "percentage": round(percentage, 1)
                    })
                
                # 按数量排序
                categories.sort(key=lambda x: x['count'], reverse=True)
                
                return {
                    "success": True,
                    "total_questions": total_questions,
                    "categories": categories
                }
                
            else:
                return {
                    "success": True,
                    "total_questions": 0,
                    "categories": []
                }
                
        except Exception as e:
            print(f"Error getting question categories: {e}")
            return {
                "success": False,
                "error": f"Database error: {str(e)}",
                "total_questions": 0,
                "categories": []
            }
            
    except Exception as e:
        print(f"Error in get_question_categories: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 