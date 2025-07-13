import os
import httpx
from fastapi import APIRouter, Depends, HTTPException, Body, UploadFile, File, Form, Request, Header
from sqlalchemy.orm import Session
from typing import Dict, Optional, List
from ..database import crud, schemas
from ..database.database import SessionLocal
from ..config import settings
from openai import OpenAI
import shutil
from pathlib import Path
from datetime import datetime
import uuid
import json
from pydantic import BaseModel
import traceback
import jwt
from typing import Optional
from ..routers.users import SECRET_KEY, ALGORITHM  # 導入 users.py 中的 JWT 設定

router = APIRouter()

# 确保上传目录存在
UPLOAD_DIR = Path("backend/static/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 驗證 JWT token
async def verify_token(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authentication scheme")
        
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # 驗證用戶是否存在
        user = crud.get_user(db, user_id=user_id)
        if user is None:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication error: {str(e)}")

async def save_upload_file(upload_file: UploadFile) -> str:
    """保存上传的文件并返回相对路径"""
    # 生成唯一文件名
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_filename = f"{timestamp}_{uuid.uuid4().hex[:8]}_{upload_file.filename}"
    file_path = UPLOAD_DIR / unique_filename
    
    try:
        # 保存文件
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(upload_file.file, buffer)
        return f"/static/uploads/{unique_filename}"
    finally:
        upload_file.file.close()

def get_ai_response(question_content: str) -> Dict:
    client = OpenAI(
        api_key=settings.KIMI_API_KEY,
        base_url="https://api.moonshot.cn/v1",
    )

    completion = client.chat.completions.create(
        model="moonshot-v1-8k",
        messages=[
            {"role": "system", "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手。"},
            {"role": "user", "content": question_content}
        ],
        temperature=0.3,
    )
    ai_steps = completion.choices[0].message.content
    confidence = 0.95
    return {"steps": ai_steps, "confidence_score": confidence}

class ChatRequest(BaseModel):
    user_id: str
    content: str

@router.post("/chat")
async def create_chat(
    request: Request,
    files: Optional[List[UploadFile]] = File(None),
    current_user = Depends(verify_token),
    db: Session = Depends(get_db)
):
    try:
        content_type = request.headers.get('content-type', '')
        
        # 处理 multipart form-data 请求（有文件上传时）
        if content_type.startswith('multipart/form-data'):
            form = await request.form()
            user_id = current_user.user_id  # 使用已驗證的用戶 ID
            content = form.get('content')
            files = form.getlist('files')
        # 处理 JSON 请求（无文件上传时）
        else:
            body = await request.json()
            user_id = current_user.user_id  # 使用已驗證的用戶 ID
            content = body.get('content')
            files = None

        if not content:
            raise HTTPException(status_code=400, detail="content is required")

        # 保存文件（如果有的话）
        image_url = None
        file_url = None
        file_name = None
        
        if files:
            for file in files:
                # 检查文件类型
                content_type = file.content_type or ""
                is_image = content_type.startswith('image/')
                
                saved_path = await save_upload_file(file)
                if is_image and not image_url:  # 只保存第一张图片
                    image_url = saved_path
                elif not is_image and not file_url:  # 只保存第一个非图片文件
                    file_url = saved_path
                    file_name = file.filename

        # 调用 AI API 获取回复
        print("Calling AI API...")
        ai_response = get_ai_response(content)
        print(f"AI response: {ai_response}")
        
        # 创建问题
        question_schema = schemas.QuestionCreate(
            content=content,
            image_url=image_url,
            file_url=file_url,
            file_name=file_name
        )
        db_question = crud.create_question(db=db, question=question_schema, user_id=user_id)
        print(f"Created question: {db_question.question_id}")
        
        # 创建解决方案
        solution_schema = schemas.SolutionCreate(
            question_id=db_question.question_id,
            steps=ai_response["steps"],
            confidence_score=ai_response["confidence_score"]
        )
        db_solution = crud.create_solution(db=db, solution=solution_schema)
        print(f"Created solution: {db_solution.solution_id}")
        
        # 返回响应
        return {
            "content": ai_response["steps"],
            "solution_id": db_solution.solution_id,
            "question_id": db_question.question_id,
            "user_id": user_id,
            "image_url": image_url,
            "file_url": file_url,
            "file_name": file_name
        }
        
    except Exception as e:
        print(f"Error in create_chat: {e}")
        traceback.print_exc() # 添加這行來打印詳細的錯誤堆疊
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 