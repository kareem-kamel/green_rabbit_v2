
import requests
import json

BASE_URL = "https://virtuous-cooperation-production-6420.up.railway.app/api"
LOGIN_DATA = {
    "email": "ahmed411144@gmail.com",
    "password": "Ka#123456"
}

session = requests.Session()
res = session.post(f"{BASE_URL}/auth/login", json=LOGIN_DATA)
token = res.json()["data"]["accessToken"]
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# Test NVDA 1W 1h
url = f"{BASE_URL}/market/instruments/inst_nvda/chart?period=1W&interval=1h"
print(f"Testing URL: {url}")
res = session.get(url, headers=headers)
print(f"Status Code: {res.status_code}")
try:
    print(f"Response Body: {res.text[:200]}...")
except:
    print("Could not print body")
