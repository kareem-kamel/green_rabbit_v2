# Subscription API Documentation

This document describes the Subscription API endpoints for Green Rabbit.

## 1. List Subscription Plans
**GET** `/subscriptions/plans`

Retrieve all available subscription plans with pricing and features.

### Responses
- **200 OK**: Plans retrieved successfully.
```json
{
    "success": true,
    "data": [
        {
            "id": "plan_premium_monthly",
            "name": "Premium Monthly",
            "description": "Full access to all premium features with monthly billing",
            "tier": "premium",
            "billingPeriod": "monthly",
            "price": 9.99,
            "currency": "KWD",
            "originalPrice": 12.99,
            "discount": {
                "percentage": 23,
                "validUntil": "2024-02-01T00:00:00Z"
            },
            "features": [
                {
                    "id": "unlimited_ai_chat",
                    "name": "Unlimited AI Chat",
                    "description": "Chat with Meyka AI without any message limits",
                    "included": true
                }
            ],
            "trialDays": 7,
            "popular": true,
            "active": true
        }
    ]
}
```

---

## 2. Get Current Subscription
**GET** `/subscriptions/current`

Retrieve the authenticated user's current subscription details.

### Responses
- **200 OK**: Current subscription retrieved successfully.
```json
{
    "success": true,
    "data": {
        "id": "sub_abc123",
        "planId": "plan_premium_monthly",
        "planName": "Premium Monthly",
        "status": "active",
        "currentPeriodStart": "2024-01-01T00:00:00Z",
        "currentPeriodEnd": "2024-02-01T00:00:00Z",
        "cancelAtPeriodEnd": false,
        "features": [
            "unlimited_ai_chat",
            "advanced_analytics",
            "no_ads",
            "priority_support"
        ],
        "paymentMethod": {
            "type": "card",
            "last4": "4242",
            "brand": "visa"
        }
    }
}
```

---

## 3. Create Checkout Session
**POST** `/subscriptions/checkout`

Generate a MyFatoorah payment URL for subscription checkout.

### Body Params
- `planId`: string (Required)
- `successUrl`: string (Optional)
- `cancelUrl`: string (Optional)
- `promoCode`: string (Optional)

### Responses
- **200 OK**: Checkout session created successfully.
```json
{
    "success": true,
    "data": {
        "checkoutId": "chk_mf_abc123xyz",
        "paymentUrl": "https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=100202312345678",
        "expiresAt": "2024-01-15T17:30:00Z",
        "plan": {
            "id": "plan_premium_monthly",
            "name": "Premium Monthly",
            "price": 9.99,
            "currency": "KWD"
        },
        "discount": {
            "code": "SAVE20",
            "amount": 2,
            "percentage": 20
        },
        "totalAmount": 7.99
    }
}
```

---

## 4. Cancel Subscription
**POST** `/subscriptions/cancel`

Cancel the current subscription.

### Body Params
- `reason`: enum (too_expensive, not_using, missing_features, switching_service, other)
- `feedback`: string (Optional)
- `immediate`: boolean (Default: false)

### Responses
- **200 OK**: Subscription canceled successfully.
```json
{
    "success": true,
    "data": {
        "subscriptionId": "sub_abc123",
        "status": "canceled",
        "cancelAtPeriodEnd": true,
        "currentPeriodEnd": "2024-02-01T00:00:00Z",
        "message": "Your subscription has been canceled. You will retain access until February 1, 2024."
    }
}
```
