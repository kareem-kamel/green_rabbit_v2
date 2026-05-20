import requests
import uuid

BASE_URL = 'https://green-rabbit-backend-api.up.railway.app/api'

def test():
    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    requests.post(f"{BASE_URL}/auth/register", json={
        "email": email,
        "password": "Password123!",
        "fullName": "Test User",
        "phone": "+1234567890",
        "country": "US",
        "acceptTerms": True,
        "acceptPrivacy": True
    })
    
    for code in ["123456", "111111", "000000", "12345"]:
        res = requests.post(f"{BASE_URL}/auth/verify-email", json={
            "email": email,
            "otp": code
        })
        print(f"Code {code}: Status {res.status_code}, Body {res.text}")

if __name__ == "__main__":
    test()
