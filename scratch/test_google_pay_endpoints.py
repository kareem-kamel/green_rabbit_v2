import requests
import json
import base64
import uuid
import os
import sys

# Define the base URLs to try
BASE_URL = 'https://green-rabbit-backend-api.up.railway.app/api'

# Check if .env has an override
env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
if os.path.exists(env_path):
    with open(env_path, 'r') as f:
        for line in f:
            if line.startswith('API_BASE_URL='):
                val = line.split('=', 1)[1].strip().strip('"').strip("'")
                if val:
                    BASE_URL = val
                    break

def main():
    print("="*60)
    print("Green Rabbit - Google Play Payments Endpoint Tester")
    print(f"Target URL: {BASE_URL}")
    print("="*60)
    
    token = None
    
    # Check if token is passed via command line
    if len(sys.argv) > 1:
        token = sys.argv[1]
        print("Using token provided via command-line argument.")
    else:
        print("\nChoose an option to authenticate:")
        print("1. Enter a valid JWT Bearer Token (Recommended if already logged in on App)")
        print("2. Enter Email and Password of an existing verified account to log in")
        choice = input("Option (1/2): ").strip()
        
        if choice == "1":
            token = input("Enter JWT Token: ").strip()
        elif choice == "2":
            email = input("Email: ").strip()
            password = input("Password: ").strip()
            
            print("\nLogging in...")
            try:
                login_response = requests.post(f"{BASE_URL}/auth/login", json={
                    "email": email,
                    "password": password
                })
                print(f"Login Response Status: {login_response.status_code}")
                login_data = login_response.json()
                
                token = login_data.get("data", {}).get("accessToken") or login_data.get("accessToken")
                if not token:
                    print("Error: Could not retrieve access token. Check login response:")
                    print(json.dumps(login_data, indent=2))
                    return
            except Exception as e:
                print(f"Login request failed: {e}")
                return
        else:
            print("Invalid option.")
            return

    if not token:
        print("Error: Token is empty or invalid.")
        return
        
    print("\nAuthentication successful!")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # 1. Test Webhook
    # Create base64 encoded payload message for Google Play Pub/Sub
    mock_rtdn = {
        "version": "1.0",
        "packageName": "com.greenrabbit.app",
        "eventTimeMillis": "1718704800000",
        "subscriptionNotification": {
            "version": "1.0",
            "notificationType": 4, # SUBSCRIPTION_RENEWED
            "purchaseToken": "mock_purchase_token_rtdn_12345",
            "subscriptionId": "com.greenrabbit.pro.monthly"
        }
    }
    encoded_data = base64.b64encode(json.dumps(mock_rtdn).encode('utf-8')).decode('utf-8')
    
    print("\n[1] Testing Google Play RTDN Webhook (/payments/google/webhook)...")
    webhook_payload = {
        "message": {
            "data": encoded_data
        }
    }
    
    try:
        webhook_res = requests.post(
            f"{BASE_URL}/payments/google/webhook", 
            headers=headers, 
            json=webhook_payload
        )
        print(f"Status: {webhook_res.status_code}")
        print(f"Body: {webhook_res.text}")
    except Exception as e:
        print(f"Webhook request failed: {e}")

    # 2. Test Verify Purchase
    print("\n[2] Testing Verify Google Play Purchase (/payments/google/verify)...")
    verify_payload = {
        "purchaseToken": "mock_purchase_token_12345",
        "productId": "com.greenrabbit.pro.monthly",
        "isSubscription": True
    }
    
    try:
        verify_res = requests.post(
            f"{BASE_URL}/payments/google/verify", 
            headers=headers, 
            json=verify_payload
        )
        print(f"Status: {verify_res.status_code}")
        try:
            print(f"Body:\n{json.dumps(verify_res.json(), indent=2)}")
        except:
            print(f"Body: {verify_res.text}")
    except Exception as e:
        print(f"Verify request failed: {e}")

if __name__ == "__main__":
    main()
