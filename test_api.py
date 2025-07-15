import requests
import json

def test_api():
    print("測試後端 API 連接...")
    
    # 測試根路徑
    try:
        response = requests.get("http://127.0.0.1:8000/")
        print(f"根路徑響應: {response.status_code}")
        print(f"響應內容: {response.text}")
    except Exception as e:
        print(f"根路徑請求失敗: {e}")
    
    # 測試用戶註冊
    try:
        data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpassword"
        }
        response = requests.post(
            "http://127.0.0.1:8000/api/users/",
            headers={"Content-Type": "application/json"},
            data=json.dumps(data)
        )
        print(f"用戶註冊響應: {response.status_code}")
        print(f"響應內容: {response.text}")
    except Exception as e:
        print(f"用戶註冊請求失敗: {e}")

if __name__ == "__main__":
    test_api() 