# IP 智慧解答專家

這是一個使用 Flutter 和 FastAPI 構建的 AI 聊天應用程序，專門用於解答 IP 網絡相關問題。

## 項目結構

```
app/
├── backend/            # FastAPI 後端
│   ├── database/       # 數據庫相關代碼
│   ├── routers/        # API 路由
│   └── requirements.txt # Python 依賴
├── lib/                # Flutter 前端
├── docker-compose.yml  # Docker 配置
├── Dockerfile.backend  # 後端 Docker 配置
├── Dockerfile.frontend # 前端 Docker 配置
└── init-db.sql         # 數據庫初始化腳本
```

## 使用 Docker 快速部署

我們提供了 Docker 容器化配置，可以幫助您的團隊快速部署整個環境。

### 前置條件

- 安裝 [Docker](https://www.docker.com/get-started)
- 安裝 [Docker Compose](https://docs.docker.com/compose/install/)

### 快速開始

1. 克隆代碼庫：

```bash
git clone <repository-url>
cd app
```

2. 設置環境變數：

```bash
# 創建 .env 文件
echo "KIMI_API_KEY=your_api_key_here" > .env
```

3. 使用 Docker Compose 啟動服務：

```bash
docker-compose up -d
```

4. 訪問應用：
   - 前端：http://localhost:8080
   - 後端 API：http://localhost:8000
   - API 文檔：http://localhost:8000/docs

### 服務說明

- **MySQL 數據庫**：運行在端口 3306
- **FastAPI 後端**：運行在端口 8000
- **Flutter Web 前端**：運行在端口 8080

### 開發模式

如果您想在容器中進行開發，可以使用以下命令：

```bash
# 啟動所有服務並查看日誌
docker-compose up

# 只重新構建並啟動後端
docker-compose up --build backend

# 只重新構建並啟動前端
docker-compose up --build frontend
```

### 數據持久化

- 數據庫數據存儲在 Docker 卷 `mysql_data` 中
- 上傳的文件存儲在 Docker 卷 `backend_uploads` 中

## 手動安裝

如果您不想使用 Docker，也可以手動安裝：

### 後端安裝

1. 進入後端目錄：

```bash
cd backend
```

2. 安裝依賴：

```bash
pip install -r requirements.txt
```

3. 配置環境變數：

```bash
# 複製 .env.example 並修改
cp .env.example .env
```

4. 啟動服務：

```bash
uvicorn main:app --reload
```

### 前端安裝

1. 安裝 Flutter：

```bash
# 下載 Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
```

2. 添加 Flutter 到環境變數：

```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

3. 安裝依賴：

```bash
flutter pub get
```

4. 運行應用：

```bash
flutter run -d chrome
```

## 故障排除

### 數據庫連接問題

如果遇到數據庫連接問題，請檢查：

1. 數據庫服務是否正常運行：

```bash
docker-compose ps
```

2. 數據庫連接字符串是否正確：

```bash
docker-compose logs backend
```

### 前端無法連接後端

檢查 CORS 設置和 API 基礎 URL 配置。

## 安全注意事項

- 生產環境中請更改默認密碼
- 配置適當的 CORS 策略
- 使用 HTTPS 保護 API 通信
