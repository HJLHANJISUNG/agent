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
from backend.database.routers.users import SECRET_KEY, ALGORITHM  # 导入 users.py 中的 JWT 设置

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

# 验证 JWT token
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
        
        # 验证用户是否存在
        user = crud.get_user(db, user_id=user_id)
        if user is None:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication error: {str(e)}")

async def save_upload_file(upload_file: UploadFile) -> str:
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
        # 实际API调用
        completion = client.chat.completions.create(
            model="moonshot-v1-8k",
            messages=[
                {"role": "system", "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手。请尽可能给出结构化的回答，使用适当的标题、项目符号和代码块来提高可读性。"},
                {"role": "user", "content": question_content}
            ],
            temperature=0.3,
        )
        ai_steps = completion.choices[0].message.content
        confidence = 0.95
        return {"steps": ai_steps, "confidence_score": confidence}
    except Exception as e:
        # 如果API调用失败，返回模拟数据
        print(f"AI API调用失败，使用模拟数据: {e}")
        # 根据问题内容生成一个简单的回应
        if "OSPF" in question_content:
            ai_steps = """OSPF（开放式最短路径优先）协议是一种内部网关协议，用于在单一自治系统内确定路由。配置OSPF的基本步骤：

1. 启用OSPF进程：
```
Router(config)# router ospf <process-id>
```

2. 设定路由器ID：
```
Router(config-router)# router-id <ip-address>
```

3. 定义要通告的网络：
```
Router(config-router)# network <ip-address> <wildcard-mask> area <area-id>
```

4. 配置OSPF区域：
```
Router(config-router)# area <area-id> <type>
```

5. 验证配置：
```
Router# show ip ospf
Router# show ip ospf neighbor
Router# show ip route ospf
```

要注意的关键点：
- 使用单一区域可简化配置
- 合理设计区域边界以减少LSA通告
- 考虑使用认证增强安全性
- 适当调整Hello间隔和Dead时间"""
        elif "BGP" in question_content:
            ai_steps = """BGP路由通告失败的常见原因：

1. **BGP对等体会话未建立**：
   - 检查TCP连接是否成功（端口179）
   - 确认AS号码配置正确
   - 检查neighbor语句中的IP地址是否正确

2. **路由策略或过滤问题**：
   - 检查route-map、prefix-list或as-path access-list是否过滤了路由
   - 查看distribute-list或filter-list配置

3. **Next-hop可达性问题**：
   - 确保next-hop地址可通过IGP到达
   - 检查next-hop-self配置是否正确

4. **网络声明问题**：
   - 确认network语句与实际路由表匹配
   - 检查network语句中的掩码设置

5. **Route Reflection问题**：
   - 在大型网络中检查Route Reflector配置
   - 确认cluster-id设置正确

6. **聚合问题**：
   - 检查aggregate-address命令是否正确
   - 确认suppress-map是否错误阻止了特定路由

7. **iBGP全网状连接缺失**：
   - 确保所有iBGP对等体之间有直接或通过Route Reflector的连接

常用诊断命令：
```
show ip bgp summary
show ip bgp neighbors
show ip bgp
debug ip bgp updates
```"""
        else:
            ai_steps = f"""关于"{question_content}"的回答：

这是一个关于网络协议的重要问题。在网络工程中，正确理解和配置各种协议对确保网络稳定运行至关重要。

解决这类问题时，我建议：

1. 首先确认网络拓扑和需求
2. 查阅相关设备的官方文档
3. 遵循最佳实践进行配置
4. 实施变更前进行充分测试
5. 保持配置的一致性和可维护性

对于更具体的解答，您可以提供更多关于具体网络环境和设备型号的细节，我可以给出更有针对性的建议。"""
        
        # 对回答进行预处理，插入适当的延迟标记
        # 这些标记可以被前端用来控制打字速度
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
            user_id = current_user.user_id  # 使用已验证的用户 ID
            content = form.get('content')
            files = form.getlist('files')
        # 处理 JSON 请求（无文件上传时）
        else:
            body = await request.json()
            user_id = current_user.user_id  # 使用已验证的用户 ID
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
        traceback.print_exc() # 添加这行来打印详细的错误堆叠
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 

@router.get("/chat/hot-questions")
async def get_hot_questions():
    """获取热门问题列表"""
    try:
        # 这里可以从数据库或缓存中获取真实的热门问题
        # 目前返回静态数据作为示例
        hot_questions = [
            {"id": "1", "question": "如何配置 OSPF 协议？", "count": 156},
            {"id": "2", "question": "BGP 路由通告失败的常见原因", "count": 142},
            {"id": "3", "question": "VLAN 间通信问题排查步骤", "count": 128},
            {"id": "4", "question": "ACL 规则配置最佳实践", "count": 115},
            {"id": "5", "question": "STP 根桥选举机制说明", "count": 98},
            {"id": "6", "question": "如何解决 DHCP 地址分配问题？", "count": 87},
            {"id": "7", "question": "VPN 隧道建立失败的排查方法", "count": 76},
            {"id": "8", "question": "IPv6 部署的关键步骤", "count": 65},
        ]
        return hot_questions
    except Exception as e:
        print(f"获取热门问题时出错: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 

@router.post("/chat/hot-questions/{question_id}/click")
async def record_hot_question_click(question_id: str):
    """记录热门问题的点击"""
    try:
        # 这里应该将点击记录到数据库中
        # 目前只是打印日志作为示例
        print(f"问题 {question_id} 被点击了")
        return {"success": True, "question_id": question_id}
    except Exception as e:
        print(f"记录问题点击时出错: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 