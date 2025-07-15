# Docker 容器化设置指南

本指南将帮助您的团队使用 Docker 快速部署整个 IP 智慧解答专家系统。

## 文件说明

我们提供了以下 Docker 相关文件：

1. `Dockerfile.backend` - 后端服务容器配置
2. `Dockerfile.frontend` - 前端服务容器配置
3. `docker-compose.yml` - 多容器应用配置
4. `init-db.sql` - 数据库初始化脚本

## 快速开始

### 1. 安装 Docker

如果您还没有安装 Docker，请按照以下步骤安装：

- **Windows**: 下载并安装 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- **macOS**: 下载并安装 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
- **Linux**: 根据您的发行版，使用包管理器安装 Docker 和 Docker Compose

### 2. 设置环境变量

在项目根目录创建 `.env` 文件：

```bash
# 复制示例文件
cp .env.example .env

# 编辑 .env 文件，设置您的 API 密钥
# 将 your_api_key_here 替换为您的实际 API 密钥
```

### 3. 启动服务

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 访问服务

- **前端界面**: http://localhost:8080
- **后端 API**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs

## 常见问题解决

### 1. 容器无法启动

检查日志以获取详细错误信息：

```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs db
```

### 2. 数据库连接问题

确保数据库容器正在运行：

```bash
docker-compose ps db
```

如果数据库容器已启动但后端无法连接，检查连接字符串：

```bash
# 检查 docker-compose.yml 中的环境变量
# DATABASE_URL=mysql+mysqlconnector://root:123456@db:3306/agentai_db
```

### 3. 前端无法连接后端

检查前端代码中的 API 基础 URL 是否正确配置。在开发环境中，应该指向 `http://localhost:8000/api`。

### 4. 重建服务

如果您修改了 Dockerfile 或代码，需要重新构建服务：

```bash
# 重新构建并启动特定服务
docker-compose up -d --build backend

# 重新构建所有服务
docker-compose up -d --build
```

## 数据持久化

数据存储在 Docker 卷中，即使容器被删除，数据也会保留：

- **MySQL 数据**: 存储在 `mysql_data` 卷中
- **上传文件**: 存储在 `backend_uploads` 卷中

查看卷：

```bash
docker volume ls
```

## 生产环境部署

对于生产环境，建议进行以下额外配置：

1. 使用 HTTPS 保护通信
2. 设置更强的数据库密码
3. 限制 CORS 策略
4. 配置适当的日志记录
5. 设置资源限制

修改 `docker-compose.yml` 中的环境变量：

```yaml
environment:
  - ENVIRONMENT=production
  - DATABASE_URL=mysql+mysqlconnector://user:strong_password@db:3306/agentai_db
```

## 团队协作

使用 Docker 的好处是每个团队成员都可以在相同的环境中工作，避免"在我的机器上可以运行"的问题。

新团队成员只需执行：

```bash
git clone <repository-url>
cd app
cp .env.example .env
# 编辑 .env 文件
docker-compose up -d
```

即可获得完全相同的开发环境。
