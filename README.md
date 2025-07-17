# IP 智慧解答专家

这是一个使用 Flutter 和 FastAPI 构建的 AI 聊天应用程序，专门用于解答 IP 网络相关问题。

## 项目结构

```
app/
├── backend/            # FastAPI 后端
│   ├── database/       # 数据库相关代码
│   ├── routers/        # API 路由
│   └── requirements.txt # Python 依赖
├── lib/                # Flutter 前端
├── docker-compose.yml  # Docker 配置
├── Dockerfile.backend  # 后端 Docker 配置
├── Dockerfile.frontend # 前端 Docker 配置
└── init-db.sql         # 数据库初始化脚本
```

## 使用 Docker 快速部署

我们提供了 Docker 容器化配置，可以帮助您的团队快速部署整个环境。

### 前置条件

- 安装 [Docker](https://www.docker.com/get-started)
- 安装 [Docker Compose](https://docs.docker.com/compose/install/)

### 快速开始

1. 克隆代码库：

```bash
git clone <repository-url>
cd app
```

2. 设置环境变量：

```bash
# 创建 .env 文件
echo "KIMI_API_KEY=your_api_key_here" > .env
```

3. 使用 Docker Compose 启动服务：

```bash
docker-compose up -d
```

4. 访问应用：
   - 前端：http://localhost:8080
   - 后端 API：http://localhost:8000
   - API 文档：http://localhost:8000/docs

### 服务说明

- **MySQL 数据库**：运行在端口 3306
- **FastAPI 后端**：运行在端口 8000
- **Flutter Web 前端**：运行在端口 8080

### 开发模式

如果您想在容器中进行开发，可以使用以下命令：

```bash
# 启动所有服务并查看日志
docker-compose up

# 只重新构建并启动后端
docker-compose up --build backend

# 只重新构建并启动前端
docker-compose up --build frontend
```

### 数据持久化

- 数据库数据存储在 Docker 卷 `mysql_data` 中
- 上传的文件存储在 Docker 卷 `backend_uploads` 中

## 手动安装

如果您不想使用 Docker，也可以手动安装：

### 后端安装

1. 进入后端目录：

```bash
cd backend
```

2. 安装依赖：

```bash
pip install -r requirements.txt
```

3. 配置环境变量：

```bash
# 复制 .env.example 并修改
cp .env.example .env
```

4. 启动服务：

```bash
uvicorn main:app --reload
```

### 前端安装

1. 安装 Flutter：

```bash
# 下载 Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
```

2. 添加 Flutter 到环境变量：

```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

3. 安装依赖：

```bash
flutter pub get
```

4. 运行应用：

```bash
flutter run -d chrome
```

## 故障排除

### 数据库连接问题

如果遇到数据库连接问题，请检查：

1. 数据库服务是否正常运行：

```bash
docker-compose ps
```

2. 数据库连接字符串是否正确：

```bash
docker-compose logs backend
```

### 前端无法连接后端

检查 CORS 设置和 API 基础 URL 配置。

## 安全注意事项

- 生产环境中请更改默认密码
- 配置适当的 CORS 策略
- 使用 HTTPS 保护 API 通信
