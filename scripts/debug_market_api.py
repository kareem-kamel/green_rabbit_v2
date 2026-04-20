import requests
import json
import os
import time

# --- Configuration ---
BASE_URL = "https://virtuous-cooperation-production-6420.up.railway.app/api"
LOGIN_DATA = {
    "email": "ahmed411144@gmail.com",
    "password": "Ka#123456"
}
OUTPUT_DIR = "debug_responses"

class MarketDebugger:
    def __init__(self):
        self.session = requests.Session()
        self.token = None
        self.headers = {"Content-Type": "application/json"}
        self.manifest = {} # Map filename to endpoint
        
        if not os.path.exists(OUTPUT_DIR):
            os.makedirs(OUTPUT_DIR)
            print(f"Created directory: {OUTPUT_DIR}")

    def save_raw(self, name, text, url):
        filename = f"{name}.json"
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(text)
        
        self.manifest[filename] = url
        print(f"✅ Saved Raw: {filepath}")
        print(f"   Endpoint: {url}")

    def save_manifest(self):
        manifest_path = os.path.join(OUTPUT_DIR, "00_manifest.json")
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(self.manifest, f, indent=4)
        print(f"\n📑 Manifest saved: {manifest_path}")

    def login(self):
        print("\n🔑 Logging in...")
        url = f"{BASE_URL}/auth/login"
        response = self.session.post(url, json=LOGIN_DATA, headers=self.headers)
        
        if response.status_code == 200:
            self.save_raw("01_auth_login", response.text, url)
            data = response.json()
            self.token = data.get("data", {}).get("accessToken")
            if self.token:
                self.headers["Authorization"] = f"Bearer {self.token}"
                print("✅ Login successful. Token captured.")
                return True
        print(f"❌ Login failed: {response.status_code} - {response.text}")
        return False

    def fetch_overview(self, asset_type):
        url = f"{BASE_URL}/market/overview/{asset_type}"
        print(f"\n📊 Fetching basic overview: {asset_type}...")
        response = self.session.get(url, headers=self.headers)
        
        if response.status_code == 200:
            self.save_raw(f"02_overview_{asset_type}", response.text, url)
            data = response.json()
            instruments = data.get("data", {}).get("instruments", [])
            return instruments[0].get("id") if instruments else None
        else:
            print(f"❌ Failed to fetch {asset_type} overview: {response.status_code}")
        return None

    def fetch_overview_advanced(self, asset_type):
        print(f"\n⚖️ Testing Advanced Overview: {asset_type}...")
        
        # 1. Search (e.g., search for APPLE if stocks, or BTC if crypto)
        search_query = "apple" if asset_type == "stocks" else ("btc" if asset_type == "crypto" else "eur")
        url_search = f"{BASE_URL}/market/overview/{asset_type}?search={search_query}"
        res = self.session.get(url_search, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"02_overview_{asset_type}_search", res.text, url_search)

        # 2. Pagination & Sorting
        url_paginated = f"{BASE_URL}/market/overview/{asset_type}?page=1&limit=5&sort=change_desc"
        res = self.session.get(url_paginated, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"02_overview_{asset_type}_paginated", res.text, url_paginated)

        # 3. Sector (Stocks Only)
        if asset_type == "stocks":
            url_sector = f"{BASE_URL}/market/overview/{asset_type}?sector=technology"
            res = self.session.get(url_sector, headers=self.headers)
            if res.status_code == 200: self.save_raw(f"02_overview_{asset_type}_sector", res.text, url_sector)

    def fetch_trending(self):
        print("\n🔥 Testing Trending Instruments...")
        
        # 1. Basic (All)
        url_basic = f"{BASE_URL}/market/trending"
        res = self.session.get(url_basic, headers=self.headers)
        if res.status_code == 200: self.save_raw("03_market_trending_basic", res.text, url_basic)

        # 2. Filtered (Crypto, 7d)
        url_adv = f"{BASE_URL}/market/trending?type=crypto&period=7d&limit=5"
        res = self.session.get(url_adv, headers=self.headers)
        if res.status_code == 200: self.save_raw("03_market_trending_crypto_7d", res.text, url_adv)

    def test_instrument_advanced(self, instrument_id):
        if not instrument_id:
            return

        print(f"\n🔍 Deep Testing Instrument: {instrument_id}")
        sanitized_id = instrument_id.replace(":", "_")
        
        # 1. Basic Details
        url_detail = f"{BASE_URL}/market/instruments/{instrument_id}"
        res = self.session.get(url_detail, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"detail_{sanitized_id}", res.text, url_detail)
        
        # 2. Chart (1D/5m vs 1W/1h)
        url_chart_1d = f"{BASE_URL}/market/instruments/{instrument_id}/chart?period=1D&interval=5m"
        res = self.session.get(url_chart_1d, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"chart_{sanitized_id}_1D_5m", res.text, url_chart_1d)

        url_chart_1w = f"{BASE_URL}/market/instruments/{instrument_id}/chart?period=1W&interval=1h"
        res = self.session.get(url_chart_1w, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"chart_{sanitized_id}_1W_1h", res.text, url_chart_1w)

        # 3. Stats (15m interval)
        url_stats = f"{BASE_URL}/market/instruments/{instrument_id}/stats?interval=15m"
        res = self.session.get(url_stats, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"stats_{sanitized_id}_15m", res.text, url_stats)

        # 4. News (Bullish Sentiment)
        url_news = f"{BASE_URL}/market/instruments/{instrument_id}/news"
        res = self.session.get(url_news, headers=self.headers)
        if res.status_code == 200: self.save_raw(f"news_{sanitized_id}_bullish", res.text, url_news)

    def test_market_stream(self, instruments):
        print(f"\n📡 Testing Real-time Stream (SSE) for 15 seconds...")
        url = f"{BASE_URL}/market/stream?instruments={','.join(instruments)}"
        headers = self.headers.copy()
        headers["Accept"] = "text/event-stream"
        
        filepath = os.path.join(OUTPUT_DIR, "04_market_stream.txt")
        self.manifest["04_market_stream.txt"] = url
        
        try:
            # We use a smaller timeout to ensure we don't hang forever
            with self.session.get(url, headers=headers, stream=True, timeout=20) as res:
                if res.status_code == 200:
                    print(f"✅ SSE Connected. Capturing events...")
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(f"--- STREAM CAPTURE START: {url} ---\n\n")
                        count = 0
                        start_time = time.time()
                        for line in res.iter_lines():
                            if line:
                                decoded_line = line.decode('utf-8')
                                f.write(decoded_line + "\n")
                                print(f"   [SSE] {decoded_line[:80]}...")
                                count += 1
                            if count >= 15 or (time.time() - start_time) > 15:
                                break
                    print(f"✅ Saved Stream Capture: {filepath}")
                else:
                    print(f"❌ SSE Connection failed: {res.status_code}")
        except Exception as e:
            print(f"ℹ️ SSE session finished: {e}")

def main():
    debugger = MarketDebugger()
    if not debugger.login():
        return

    # 1. Trending (Advanced)
    debugger.fetch_trending()

    # 2. Dynamic Instrument Discovery & Testing
    test_instruments = []
    for asset_type in ["stocks", "crypto", "forex"]:
        # Basic Overview
        instr_id = debugger.fetch_overview(asset_type)
        if instr_id:
            test_instruments.append(instr_id)
            # Advanced Overview (Search, Pagination, etc)
            debugger.fetch_overview_advanced(asset_type)
            # Drill down into the specific instrument
            debugger.test_instrument_advanced(instr_id)
        
        time.sleep(1) # Rate limit protection

    # 3. Real-time Stream Capture
    if test_instruments:
        # Use first few discovered instruments
        debugger.test_market_stream(test_instruments[:5])

    # 4. Save Final Manifest
    debugger.save_manifest()
    print("\n✨ ALL COMPREHENSIVE TESTS COMPLETED.")
    print(f"Review your responses here: {os.path.abspath(OUTPUT_DIR)}")

if __name__ == "__main__":
    main()
