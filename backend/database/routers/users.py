from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database import crud
from backend.database.database import SessionLocal
from backend.database.base import User
from backend import schemas
import uuid
import bcrypt
import logging
from datetime import datetime, timedelta
from pydantic import BaseModel
import jwt
from typing import Optional

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 定义请求模型
class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str
    username: Optional[str] = None  # 为了与前端兼容

# JWT 设置
SECRET_KEY = "your-secret-key-here"  # 在生产环境中应使用环境变量
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24小时

router = APIRouter(
    prefix="/users",
    tags=["users"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.User)
def create_user(user: UserRegister, db: Session = Depends(get_db)):
    """创建新用户"""
    try:
        logger.info(f"开始创建用户: {user.username}")
        # 检查用户是否已存在
        existing_user = crud.get_user_by_email(db=db, email=user.email)
        if existing_user:
            logger.info(f"用户邮箱已存在: {user.email}")
            raise HTTPException(status_code=400, detail="Email already registered")
            
        # 生成密码的哈希值
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(user.password.encode('utf-8'), salt)
        
        # 创建新用户，移除 user_id 的手动赋值
        new_user = User(
            username=user.username,
            email=user.email,
            hashed_password=hashed.decode('utf-8')
        )
        
        logger.info(f"准备将新用户写入数据库: {new_user.username}")
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        logger.info(f"用户创建成功，ID: {new_user.user_id}")
        
        return new_user
        
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"创建用户时发生错误: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=list[schemas.User])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = crud.get_users(db, skip=skip, limit=limit)
    return users

@router.get("/{user_id}", response_model=schemas.User)
def read_user(user_id: str, db: Session = Depends(get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@router.post("/token", response_model=dict)
def login_for_access_token(user_data: UserLogin, db: Session = Depends(get_db)):
    """获取用户访问令牌"""
    try:
        logger.info(f"尝试登录用户: {user_data.email}")
        
        # 根据电子邮件查找用户
        user = crud.get_user_by_email(db=db, email=user_data.email)
        if not user:
            logger.warning(f"找不到用户: {user_data.email}")
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # 验证密码
        is_password_correct = bcrypt.checkpw(
            user_data.password.encode('utf-8'), 
            user.hashed_password.encode('utf-8')
        )
        
        if not is_password_correct:
            logger.warning(f"密码验证失败: {user_data.email}")
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # 创建访问令牌
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        expire = datetime.utcnow() + access_token_expires
        
        payload = {
            "sub": str(user.user_id),
            "email": user.email,
            "username": user.username,
            "exp": expire
        }
        
        access_token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        logger.info(f"用户 {user_data.email} 登录成功，生成令牌")
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.user_id,
            "username": user.username,
            "email": user.email
        }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"登录时发生错误: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/test")
def create_test_user(db: Session = Depends(get_db)):
    """创建测试用户"""
    try:
        logger.info("开始创建测试用户")
        # 检查用户是否已存在
        existing_user = crud.get_user_by_email(db=db, email="test@example.com")
        if existing_user:
            logger.info(f"用户已存在: {existing_user.user_id}")
            return {
                "user_id": existing_user.user_id,
                "username": existing_user.username,
                "email": existing_user.email,
                "register_date": existing_user.register_date
            }
            
        # 生成测试密码的哈希值
        password = "test123"
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        
        # 创建新用户
        new_user = User(
            user_id=str(uuid.uuid4()),
            username="test_user",
            email="test@example.com",
            hashed_password=hashed.decode('utf-8')
        )
        
        logger.info(f"准备创建新用户: {new_user.user_id}")
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        logger.info(f"用户创建成功: {new_user.user_id}")
        
        return {
            "user_id": new_user.user_id,
            "username": new_user.username,
            "email": new_user.email,
            "register_date": new_user.register_date
        }
    except Exception as e:
        logger.error(f"创建用户时发生错误: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e)) 