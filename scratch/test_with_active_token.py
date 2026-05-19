import requests

BASE_URL = 'https://green-rabbit-backend-api.up.railway.app/api'
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJwcm8iLCJsYW5nIjoiZW4iLCJ0diI6MSwiaWF0IjoxNzc2NjMwOTI0LCJleHAiOjE3NzY2MzQ1MjR9.-A1zSVSn8BIJi9EqWyQM2G8G2MgTaaDUV_7xii7qkzg"

def test():
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }
    
    test_cases = [
        {"type": "news_article", "targetId": "123"},
        {"type": "news_article", "target_id": "123"},
        {"target_type": "news_article", "target_id": "123"},
        {"commentable_type": "news_article", "commentable_id": "123"},
        {"type": "news", "targetId": "123"},
        {"type": "news", "target_id": "123"},
        {"targetId": "123"},
        {"target_id": "123"},
    ]
    
    for case in test_cases:
        print(f"\n--- GET /comments: {case} ---")
        res = requests.get(f"{BASE_URL}/comments", params=case, headers=headers)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.text}")

if __name__ == "__main__":
    test()
