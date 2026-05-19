import requests
import json
import uuid

BASE_URL = 'https://green-rabbit-backend-api.up.railway.app/api'

def test_api():
    # 1. Register a test user
    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    password = "TestPassword123!"
    
    print(f"Registering user: {email}")
    register_response = requests.post(f"{BASE_URL}/auth/register", json={
        "email": email,
        "password": password,
        "fullName": "Test User",
        "phone": "+1234567890",
        "country": "US",
        "acceptTerms": True,
        "acceptPrivacy": True
    })
    print(f"Register status: {register_response.status_code}")
    print(f"Register body: {register_response.text}")
    
    # 2. Login
    print("Logging in...")
    login_response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": password
    })
    print(f"Login status: {login_response.status_code}")
    print(f"Login body: {login_response.text}")
    
    login_data = login_response.json()
    token = login_data.get("data", {}).get("accessToken")
    print(f"Token obtained: {token is not None}")
    
    if not token:
        print("Failed to get token.")
        return
        
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # 3. Test different query parameter combinations for GET /comments
    test_cases = [
        {"type": "news_article", "targetId": "123"},
        {"type": "news_article", "target_id": "123"},
        {"target_type": "news_article", "target_id": "123"},
        {"commentable_type": "news_article", "commentable_id": "123"},
        {"type": "instrument", "targetId": "stock:AAPL"},
        {"targetId": "123"},
        {"target_id": "123"},
        {}
    ]
    
    for case in test_cases:
        print(f"\n--- Testing GET /comments with query params: {case} ---")
        res = requests.get(f"{BASE_URL}/comments", params=case, headers=headers)
        print(f"Status code: {res.status_code}")
        print(f"Response: {res.text}")

if __name__ == "__main__":
    test_api()
