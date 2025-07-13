# Python 后端服务

这是一个使用 FastAPI 搭建的后端服务，提供 HTTPS API 和 WebSocket 通信，并连接到 MySQL 数据库。

## 功能

- **HTTPS API**: 提供 RESTful API 用于常规的客户端-服务器通信 (例如：用户注册、数据查询)。
- **WebSocket**: 提供实时的双向通信通道。
- **MySQL 集成**: 使用 SQLAlchemy ORM 与 MySQL 数据库进行交互。
- **自动 API 文档**: FastAPI 会在 `/docs` 和 `/redoc` 路径下自动生成交互式 API 文档。

## 环境要求

- Python 3.8+
- MySQL 数据库

## 如何启动

1.  **安装依赖**:
    在 `backend` 目录下，打开终端并运行：

    ```bash
    pip install -r requirements.txt
    ```

2.  **配置数据库**:

    - 复制 `.env.example` 文件并重命名为 `.env`。
    - 打开 `.env` 文件，修改 `DATABASE_URL` 为您自己的 MySQL 连接信息。格式如下：
      ```
      DATABASE_URL=mysql+mysqlconnector://<user>:<password>@<host>[:<port>]/<database>
      ```
      例如：
      ```
      DATABASE_URL=mysql+mysqlconnector://root:your_password@localhost:3306/my_app_db
      ```

3.  **启动服务**:
    在 `backend` 目录下，运行 Uvicorn 服务器：

    ```bash
    uvicorn main:app --reload
    ```

    - `--reload` 参数会使服务在代码变更后自动重启，非常适合开发环境。

4.  **访问服务**:
    - **HTTPS API**: 服务启动后，您可以在 `http://127.0.0.1:8000` 访问。
    - **API 文档**:
      - Swagger UI: `http://127.0.0.1:8000/docs`
      - ReDoc: `http://127.0.0.1:8000/redoc`
    - **WebSocket**: 您可以使用支持 WebSocket 的客户端连接到 `ws://127.0.0.1:8000/ws/{your_client_id}`。

## 项目结构

```
backend/
├── .env              # 环境变量 (数据库连接等)
├── database.py       # SQLAlchemy 设置
├── crud.py           # 数据库操作 (Create, Read, Update, Delete)
├── main.py           # FastAPI 应用主入口
├── models.py         # 数据库模型 (SQLAlchemy models)
├── requirements.txt  # Python 依赖
├── schemas.py        # 数据校验模型 (Pydantic models)
└── routers/
    ├── __init__.py
    ├── user.py       # 用户相关的 API 路由
    └── websocket.py  # WebSocket 相关的路由
```
