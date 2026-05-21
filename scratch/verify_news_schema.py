import requests

BASE_URL = 'https://green-rabbit-backend-api.up.railway.app/api'
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJwcm8iLCJsYW5nIjoiZW4iLCJ0diI6MSwiaWF0IjoxNzc2NjMwOTI0LCJleHAiOjE3NzY2MzQ1MjR9.-A1zSVSn8BIJi9EqWyQM2G8G2MgTaaDUV_7xii7qkzg"

def verify_news():
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }
    
    print("--- GET /news ---")
    res = requests.get(f"{BASE_URL}/news", headers=headers)
    print(f"Status: {res.status_code}")
    if res.status_code != 200:
        print(f"Error: {res.text}")
        return
        
    data = res.json()
    print("Top level keys:", list(data.keys()))
    
    if data.get('success'):
        inner_data = data.get('data', {})
        print("data keys:", list(inner_data.keys()))
        news_data = inner_data.get('news', {})
        print("news keys:", list(news_data.keys()))
        articles = news_data.get('articles', [])
        print(f"Found {len(articles)} articles.")
        
        if articles:
            first_article = articles[0]
            print("\nFirst article schema:")
            for key, val in first_article.items():
                print(f" - {key}: {type(val)} (sample: {str(val)[:100]})")
                
            article_id = first_article.get('id')
            if article_id:
                print(f"\n--- GET /news/{article_id} ---")
                detail_res = requests.get(f"{BASE_URL}/news/{article_id}", headers=headers)
                print(f"Status: {detail_res.status_code}")
                if detail_res.status_code == 200:
                    detail_data = detail_res.json()
                    print("Detail keys:", list(detail_data.keys()))
                    if detail_data.get('success'):
                        detail_inner = detail_data.get('data', {})
                        print("detail data keys:", list(detail_inner.keys()))
                        article_detail = detail_inner.get('article', {})
                        print("\nArticle detail keys:")
                        for k, v in article_detail.items():
                            print(f" - {k}: {type(v)}")
                
                print(f"\n--- GET /news/{article_id}/related ---")
                related_res = requests.get(f"{BASE_URL}/news/{article_id}/related", headers=headers)
                print(f"Status: {related_res.status_code}")
                if related_res.status_code == 200:
                    related_data = related_res.json()
                    print("Related keys:", list(related_data.keys()))
                    if related_data.get('success'):
                        related_inner = related_data.get('data', {})
                        print("related data keys:", list(related_inner.keys()))

if __name__ == "__main__":
    verify_news()
