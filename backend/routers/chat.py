import os
import httpx
from fastapi import APIRouter, Depends, HTTPException, Body, UploadFile, File, Form, Request, Header
from sqlalchemy.orm import Session
from typing import Dict, Optional, List
from backend.database import crud, schemas
from backend.database.database import SessionLocal
from backend.config import settings
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
from backend.routers.users import SECRET_KEY, ALGORITHM  # 導入 users.py 中的 JWT 設定

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

    try:
        # 實際API調用
        completion = client.chat.completions.create(
            model="moonshot-v1-8k",
            messages=[
                {"role": "system", "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手。請盡可能給出結構化的回答，使用適當的標題、項目符號和代碼塊來提高可讀性。"},
                {"role": "user", "content": question_content}
            ],
            temperature=0.3,
        )
        ai_steps = completion.choices[0].message.content
        confidence = 0.95
        return {"steps": ai_steps, "confidence_score": confidence}
    except Exception as e:
        # 如果API調用失敗，返回模擬數據
        print(f"AI API調用失敗，使用模擬數據: {e}")
        # 根據問題內容生成一個簡單的回應
        if "OSPF" in question_content:
            ai_steps = """OSPF（開放式最短路徑優先）協議是一種內部網關協議，用於在單一自治系統內確定路由。配置OSPF的基本步驟：

1. 啟用OSPF進程：
```
Router(config)# router ospf <process-id>
```

2. 設定路由器ID：
```
Router(config-router)# router-id <ip-address>
```

3. 定義要通告的網絡：
```
Router(config-router)# network <ip-address> <wildcard-mask> area <area-id>
```

4. 配置OSPF區域：
```
Router(config-router)# area <area-id> <type>
```

5. 驗證配置：
```
Router# show ip ospf
Router# show ip ospf neighbor
Router# show ip route ospf
```

要注意的關鍵點：
- 使用單一區域可簡化配置
- 合理設計區域邊界以減少LSA通告
- 考慮使用認證增強安全性
- 適當調整Hello間隔和Dead時間"""
        elif "BGP" in question_content:
            ai_steps = """BGP路由通告失敗的常見原因：

1. **BGP對等體會話未建立**：
   - 檢查TCP連接是否成功（端口179）
   - 確認AS號碼配置正確
   - 檢查neighbor語句中的IP地址是否正確

2. **路由策略或過濾問題**：
   - 檢查route-map、prefix-list或as-path access-list是否過濾了路由
   - 查看distribute-list或filter-list配置

3. **Next-hop可達性問題**：
   - 確保next-hop地址可通過IGP到達
   - 檢查next-hop-self配置是否正確

4. **網絡聲明問題**：
   - 確認network語句與實際路由表匹配
   - 檢查network語句中的掩碼設置

5. **Route Reflection問題**：
   - 在大型網絡中檢查Route Reflector配置
   - 確認cluster-id設置正確

6. **聚合問題**：
   - 檢查aggregate-address命令是否正確
   - 確認suppress-map是否錯誤阻止了特定路由

7. **iBGP全網狀連接缺失**：
   - 確保所有iBGP對等體之間有直接或通過Route Reflector的連接

常用診斷命令：
```
show ip bgp summary
show ip bgp neighbors
show ip bgp
debug ip bgp updates
```"""
        else:
            ai_steps = f"""關於"{question_content}"的回答：

這是一個關於網絡協議的重要問題。在網絡工程中，正確理解和配置各種協議對確保網絡穩定運行至關重要。

解決這類問題時，我建議：

1. 首先確認網絡拓撲和需求
2. 查閱相關設備的官方文檔
3. 遵循最佳實踐進行配置
4. 實施變更前進行充分測試
5. 保持配置的一致性和可維護性

對於更具體的解答，您可以提供更多關於具體網絡環境和設備型號的細節，我可以給出更有針對性的建議。"""
        
        # 對回答進行預處理，插入適當的延遲標記
        # 這些標記可以被前端用來控制打字速度
        ai_steps = ai_steps.replace('\n\n', '\n<pause-long>\n')
        ai_steps = ai_steps.replace('：\n', '：<pause-medium>\n')
        ai_steps = ai_steps.replace('。', '。<pause-short>')
        ai_steps = ai_steps.replace('！', '！<pause-short>')
        ai_steps = ai_steps.replace('？', '？<pause-short>')
        
        confidence = 0.8
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

@router.get("/chat/hot-questions")
async def get_hot_questions():
    """獲取熱門問題列表"""
    try:
        # 這裡可以從數據庫或緩存中獲取真實的熱門問題
        # 目前返回靜態數據作為示例
        hot_questions = [
            {"id": "1", "question": "如何配置 OSPF 協議？", "count": 156},
            {"id": "2", "question": "BGP 路由通告失敗的常見原因", "count": 142},
            {"id": "3", "question": "VLAN 間通信問題排查步驟", "count": 128},
            {"id": "4", "question": "ACL 規則配置最佳實踐", "count": 115},
            {"id": "5", "question": "STP 根橋選舉機制說明", "count": 98},
            {"id": "6", "question": "如何解決 DHCP 地址分配問題？", "count": 87},
            {"id": "7", "question": "VPN 隧道建立失敗的排查方法", "count": 76},
            {"id": "8", "question": "IPv6 部署的關鍵步驟", "count": 65},
        ]
        return hot_questions
    except Exception as e:
        print(f"獲取熱門問題時出錯: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 

@router.post("/chat/hot-questions/{question_id}/click")
async def record_hot_question_click(question_id: str):
    """記錄熱門問題的點擊"""
    try:
        # 這裡應該將點擊記錄到數據庫中
        # 目前只是打印日誌作為示例
        print(f"問題 {question_id} 被點擊了")
        return {"success": True, "question_id": question_id}
    except Exception as e:
        print(f"記錄問題點擊時出錯: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 