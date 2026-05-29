import urllib.request
import urllib.parse
import json
import time

url = "https://green-rabbit-backend-api.up.railway.app/api/market/stream"
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJmcmVlIiwibGFuZyI6ImVuIiwidHYiOjEsImlhdCI6MTc3NjIxMjE4MiwiZXhwIjoxNzc2MjE1NzgyfQ.2TYV_VMZ9yZeMfT5KHKHtkhUZRqp4lQFU9hHsK7mUWo"

params = {
    'instruments': 'stock:ABT,stock:ABBV,stock:ACN',
    'fields': 'price,change,changePercent,volume,dayHigh,dayLow,timestamp'
}

query_string = urllib.parse.urlencode(params)
full_url = f"{url}?{query_string}"

print(f"Connecting to: {full_url}")

req = urllib.request.Request(
    full_url,
    headers={
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Authorization': f'Bearer {token}'
    }
)

try:
    with urllib.request.urlopen(req, timeout=10) as response:
        print(f"Response code: {response.status}")
        print("Headers:")
        for k, v in response.getheaders():
            print(f"  {k}: {v}")
        
        print("\nReading first 10 lines of stream...")
        for i in range(20):
            line = response.readline().decode('utf-8').strip()
            print(f"Line {i}: {line}")
            if not line and i > 5:
                # If we get empty lines continuously, maybe sleep a bit
                time.sleep(0.5)
except Exception as e:
    print(f"Error: {e}")
