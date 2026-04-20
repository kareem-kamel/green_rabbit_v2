import requests
import json

BASE_URL = "https://virtuous-cooperation-production-6420.up.railway.app/api"
LOGIN_DATA = {
    "email": "ahmed411144@gmail.com",
    "password": "Ka#123456"
}

def check_apple_id():
    session = requests.Session()
    login_url = f"{BASE_URL}/auth/login"
    login_resp = session.post(login_url, json=LOGIN_DATA)
    if login_resp.status_code != 200:
        print("Login failed")
        return
        
    token = login_resp.json().get('data', {}).get('accessToken')
    headers = {"Authorization": f"Bearer {token}"}
    
    url = f"{BASE_URL}/market/overview/stocks"
    response = session.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        instruments = data.get('data', {}).get('instruments', [])
        for inst in instruments:
            if 'AAPL' in inst.get('symbol', ''):
                print(f"ID: {inst.get('id')}, Symbol: {inst.get('symbol')}")
                # return
        if not instruments:
             print("No instruments found")
    else:
        print(f"Failed to fetch overview: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    check_apple_id()
