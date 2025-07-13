# 開發指南

## 目錄

- [系統要求](#系統要求)
- [環境設置](#環境設置)
- [代碼更新流程](#代碼更新流程)
- [開發工具](#開發工具)
- [常見問題](#常見問題)

## 系統要求

### 後端要求

- Python 3.8+
- MySQL 8.0+
- Docker Desktop
- Git

### 前端要求

- Flutter SDK 3.8.1+
- Dart SDK
- IDE（推薦：VS Code 或 Android Studio）

## 環境設置

### 1. 克隆代碼庫

```bash
git clone https://github.com/hdhddddd/agent.git
cd agent
```

### 2. 設置後端環境

```bash
cd backend
python -m venv .venv
# Windows
.venv\Scripts\activate
# Linux/Mac
source .venv/bin/activate

# 安裝依賴
pip install -r requirements.txt
```

### 3. 設置前端環境

```bash
# 在專案根目錄執行
flutter pub get
```

### 4. 設置 Docker 環境

```bash
# 啟動 Docker 服務
docker-compose up -d
```

## 代碼更新流程

當團隊成員更新了代碼後，請按以下步驟更新本地環境：

### 1. 更新代碼

```bash
git pull origin main
```

### 2. 更新依賴

檢查以下文件是否有更新：

- `backend/requirements.txt`
- `pubspec.yaml`
- `docker-compose.yml`

如果有更新，執行相應的更新命令：

```bash
# 更新後端依賴
cd backend
pip install -r requirements.txt

# 更新前端依賴
flutter pub get

# 重建 Docker 容器（如果需要）
docker-compose down
docker-compose up -d
```

### 3. 數據庫更新

如果 `init-db.sql` 有更改：

1. 備份重要數據
2. 重新創建數據庫容器

```bash
docker-compose down
docker-compose up -d
```

### 4. 啟動服務

```bash
# 啟動後端（本地開發）
cd backend
python run.py

# 啟動前端
flutter run
```

## 開發工具

### 推薦的 IDE 和插件

- VS Code
  - Flutter 插件
  - Python 插件
  - Docker 插件
- Android Studio
  - Flutter 插件

### 實用的 Docker 命令

```bash
# 查看容器狀態
docker-compose ps

# 查看容器日誌
docker-compose logs -f

# 重啟特定服務
docker-compose restart <service-name>
```

## 常見問題

### 1. 端口衝突

如果遇到端口衝突（例如 3306 端口），可以在 `docker-compose.yml` 中修改端口映射：

```yaml
ports:
  - "3307:3306" # 將主機端口改為 3307
```

### 2. 數據庫連接問題

- 檢查 MySQL 容器是否正常運行
- 確認連接字符串是否正確
- 檢查防火牆設置

### 3. Flutter 相關問題

- 運行 `flutter doctor` 檢查環境問題
- 清理構建緩存：`flutter clean`
- 更新 Flutter SDK：`flutter upgrade`

### 4. Git 相關問題

- 如果遇到合併衝突，請與團隊成員溝通
- 使用 `git status` 檢查當前狀態
- 使用 `git log` 查看最近的更改

## 注意事項

1. 在拉取更新前，確保本地修改已提交或暫存
2. 定期備份重要數據
3. 遇到問題及時與團隊溝通
4. 保持開發環境的整潔和最新
