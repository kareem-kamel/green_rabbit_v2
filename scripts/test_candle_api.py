import requests
import json
import os
import time

BASE_URL = "https://virtuous-cooperation-production-6420.up.railway.app/api"
LOGIN_DATA = {
    "email": "ahmed411144@gmail.com",
    "password": "Ka#123456"
}
OUTPUT_DIR = "debug_responses"

def test_candle_api():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    session = requests.Session()
    headers = {"Content-Type": "application/json"}

    print("Logging in...")
    url = f"{BASE_URL}/auth/login"
    response = session.post(url, json=LOGIN_DATA, headers=headers)
    
    if response.status_code != 200:
        print(f"Login failed: {response.status_code}")
        print(response.text)
        return

    data = response.json()
    token = data.get("data", {}).get("accessToken")
    
    if not token:
        print("Token not found in response")
        return
        
    print("Login successful. Token acquired.")
    headers["Authorization"] = f"Bearer {token}"

    instrument_id = "inst_aapl"
    
    # Variations based on the matrix
    variations = [
        {"period": "1D", "interval": "1m"},   # Expected Free: 503 or 403?
        {"period": "1D", "interval": "5m"},
        {"period": "1W", "interval": "15m"},
        {"period": "1M", "interval": "1h"},   # Expected Free: 200 OK
        {"period": "1M", "interval": "1d"},   # Expected Free: 200 OK
        {"period": "1Y", "interval": "1d"},
        {"period": "ALL", "interval": "1M"},
    ]

    for var in variations:
        period = var["period"]
        interval = var["interval"]
        print(f"\nTesting period={period}, interval={interval} ...")
        
        url_chart = f"{BASE_URL}/market/instruments/{instrument_id}/chart?period={period}&interval={interval}"
        response = session.get(url_chart, headers=headers)
        
        filename = f"candle_api_{instrument_id.replace(':', '_')}_{period}_{interval}.json"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        with open(filepath, "w", encoding="utf-8") as f:
            if response.status_code == 200:
                try:
                    json.dump(response.json(), f, indent=4)
                    print(f"Success ({response.status_code}). Saved to {filename}")
                except Exception:
                    f.write(response.text)
            else:
                f.write(f"Status Code: {response.status_code}\n\n")
                try:
                    f.write(json.dumps(response.json(), indent=4))
                except Exception:
                    f.write(response.text)
                print(f"Failed ({response.status_code}). Saved to {filename}")

        # Sleep to avoid rate limiting
        time.sleep(2)

if __name__ == "__main__":
    test_candle_api()
