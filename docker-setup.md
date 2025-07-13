# Docker 容器化設置指南

本指南將幫助您的團隊使用 Docker 快速部署整個 IP 智慧解答專家系統。

## 檔案說明

我們提供了以下 Docker 相關檔案：

1. `Dockerfile.backend` - 後端服務容器配置
2. `Dockerfile.frontend` - 前端服務容器配置
3. `docker-compose.yml` - 多容器應用配置
4. `init-db.sql` - 數據庫初始化腳本

## 快速開始

### 1. 安裝 Docker

如果您還沒有安裝 Docker，請按照以下步驟安裝：

- **Windows**: 下載並安裝 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- **macOS**: 下載並安裝 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
- **Linux**: 根據您的發行版，使用包管理器安裝 Docker 和 Docker Compose

### 2. 設置環境變數

在專案根目錄創建 `.env` 文件：

```bash
# 複製示例文件
cp .env.example .env

# 編輯 .env 文件，設置您的 API 密鑰
# 將 your_api_key_here 替換為您的實際 API 密鑰
```

### 3. 啟動服務

```bash
# 構建並啟動所有服務
docker-compose up -d

# 查看服務狀態
docker-compose ps

# 查看日誌
docker-compose logs -f
```

### 4. 訪問服務

- **前端界面**: http://localhost:8080
- **後端 API**: http://localhost:8000
- **API 文檔**: http://localhost:8000/docs

## 常見問題解決

### 1. 容器無法啟動

檢查日誌以獲取詳細錯誤信息：

```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs db
```

### 2. 數據庫連接問題

確保數據庫容器正在運行：

```bash
docker-compose ps db
```

如果數據庫容器已啟動但後端無法連接，檢查連接字符串：

```bash
# 檢查 docker-compose.yml 中的環境變數
# DATABASE_URL=mysql+mysqlconnector://root:123456@db:3306/agentai_db
```

### 3. 前端無法連接後端

檢查前端代碼中的 API 基礎 URL 是否正確配置。在開發環境中，應該指向 `http://localhost:8000/api`。

### 4. 重建服務

如果您修改了 Dockerfile 或代碼，需要重新構建服務：

```bash
# 重新構建並啟動特定服務
docker-compose up -d --build backend

# 重新構建所有服務
docker-compose up -d --build
```

## 數據持久化

數據存儲在 Docker 卷中，即使容器被刪除，數據也會保留：

- **MySQL 數據**: 存儲在 `mysql_data` 卷中
- **上傳文件**: 存儲在 `backend_uploads` 卷中

查看卷：

```bash
docker volume ls
```

## 生產環境部署

對於生產環境，建議進行以下額外配置：

1. 使用 HTTPS 保護通信
2. 設置更強的數據庫密碼
3. 限制 CORS 策略
4. 配置適當的日誌記錄
5. 設置資源限制

修改 `docker-compose.yml` 中的環境變數：

```yaml
environment:
  - ENVIRONMENT=production
  - DATABASE_URL=mysql+mysqlconnector://user:strong_password@db:3306/agentai_db
```

## 團隊協作

使用 Docker 的好處是每個團隊成員都可以在相同的環境中工作，避免「在我的機器上可以運行」的問題。

新團隊成員只需執行：

```bash
git clone <repository-url>
cd app
cp .env.example .env
# 編輯 .env 文件
docker-compose up -d
```

即可獲得完全相同的開發環境。
