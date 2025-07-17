# 开发指南

## 目录

- [系统要求](#系统要求)
- [环境设置](#环境设置)
- [代码更新流程](#代码更新流程)
- [开发工具](#开发工具)
- [常见问题](#常见问题)

## 系统要求

### 后端要求

- Python 3.8+
- MySQL 8.0+
- Docker Desktop
- Git

### 前端要求

- Flutter SDK 3.8.1+
- Dart SDK
- IDE（推荐：VS Code 或 Android Studio）

## 环境设置

### 1. 克隆代码库

```bash
git clone https://github.com/hdhddddd/agent.git
cd agent
```

### 2. 设置后端环境

```bash
cd backend
python -m venv .venv
# Windows
.venv\Scripts\activate
# Linux/Mac
source .venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 3. 设置前端环境

```bash
# 在项目根目录执行
flutter pub get
```

### 4. 设置 Docker 环境

```bash
# 启动 Docker 服务
docker-compose up -d
```

## 代码更新流程

当团队成员更新了代码后，请按以下步骤更新本地环境：

### 1. 更新代码

```bash
git pull origin main
```

### 2. 更新依赖

检查以下文件是否有更新：

- `backend/requirements.txt`
- `pubspec.yaml`
- `docker-compose.yml`

如果有更新，执行相应的更新命令：

```bash
# 更新后端依赖
cd backend
pip install -r requirements.txt

# 更新前端依赖
flutter pub get

# 重建 Docker 容器（如果需要）
docker-compose down
docker-compose up -d
```

### 3. 数据库更新

如果 `init-db.sql` 有更改：

1. 备份重要数据
2. 重新创建数据库容器

```bash
docker-compose down
docker-compose up -d
```

### 4. 启动服务

```bash
# 启动后端（本地开发）
cd backend
python run.py

# 启动前端
flutter run
```

## 开发工具

### 推荐的 IDE 和插件

- VS Code
  - Flutter 插件
  - Python 插件
  - Docker 插件
- Android Studio
  - Flutter 插件

### 实用的 Docker 命令

```bash
# 查看容器状态
docker-compose ps

# 查看容器日志
docker-compose logs -f

# 重启特定服务
docker-compose restart <service-name>
```

## 常见问题

### 1. 端口冲突

如果遇到端口冲突（例如 3306 端口），可以在 `docker-compose.yml` 中修改端口映射：

```yaml
ports:
  - "3307:3306" # 将主机端口改为 3307
```

### 2. 数据库连接问题

- 检查 MySQL 容器是否正常运行
- 确认连接字符串是否正确
- 检查防火墙设置

### 3. Flutter 相关问题

- 运行 `flutter doctor` 检查环境问题
- 清理构建缓存：`flutter clean`
- 更新 Flutter SDK：`flutter upgrade`

### 4. Git 相关问题

- 如果遇到合并冲突，请与团队成员沟通
- 使用 `git status` 检查当前状态
- 使用 `git log` 查看最近的更改

## 注意事项

1. 在拉取更新前，确保本地修改已提交或暂存
2. 定期备份重要数据
3. 遇到问题及时与团队沟通
4. 保持开发环境的整洁和最新
