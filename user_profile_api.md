# User Profile API Documentation

This document outlines the API endpoints for user profile management in the Green Rabbit application.

## Table of Contents
- [Get Current User Profile](#get-current-user-profile)
- [Update User Profile](#update-user-profile)
- [Upload or Replace Avatar](#upload-or-replace-avatar)
- [Update User Preferences](#update-user-preferences)
- [Submit Onboarding Questionnaire](#submit-onboarding-questionnaire)
- [Delete User Account](#delete-user-account)
- [Register or Update FCM Device Token](#register-or-update-fcm-device-token)

---

## Get Current User Profile
Returns the complete profile of the currently authenticated user, including personal details, preferences, subscription tier, onboarding status, notification settings, and usage stats.

- **URL:** `/users/me`
- **Method:** `GET`
- **Rate Limit:** 60 requests per minute
- **Auth Required:** YES (JWT Bearer)

### Request
| Parameter | Type | Location | Description |
| :--- | :--- | :--- | :--- |
| `Authorization` | `string` | Header | `Bearer <token>` |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "user": {
            "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "fullName": "Omar Al-Rashid",
            "email": "omar.rashid@example.com",
            "country": "AE",
            "phone": "+971501234567",
            "avatarUrl": "https://cdn.greenrabbit.app/avatars/f47ac10b-58cc-4372-a567-0e02b2c3d479/profile_1710000000.jpg",
            "emailVerified": "true",
            "onboardingDone": "true",
            "status": "active",
            "preferences": {
                "language": "en",
                "theme": "dark",
                "currency": "AED",
                "notifications": {
                    "push": true,
                    "smart-alerts": true
                }
            },
            "subscription": {
                "tier": "free",
                "expiresAt": null,
                "autoRenew": false
            },
            "stats": {
                "totalComments": 142,
                "totalWatchlists": 2,
                "memberSinceDays": 7
            },
            "createdAt": "2025-03-01T10:00:00.000Z",
            "updatedAt": "2025-03-08T14:00:00.000Z",
            "lastLoginAt": "2025-03-08T14:30:00.000Z"
        }
    }
}
```

---

## Update User Profile
Updates the authenticated user's core profile fields (name, country, phone). Email changes are not supported.

- **URL:** `/users/me`
- **Method:** `PUT`
- **Rate Limit:** 30 requests per minute
- **Auth Required:** YES (JWT Bearer)

### Request Body (`application/json`)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `fullName` | `string` | No | 2–100 characters |
| `country` | `string` | No | ISO 3166-1 alpha-2 code (e.g., `SA`, `AE`) |
| `phone` | `string` | No | E.164 format (e.g., `+966501234567`) or `null` |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "user": {
            "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "fullName": "Omar K. Al-Rashid",
             "email": "omar.rashid@example.com",
            "country": "SA",
            "phone": "+966501234567",
            "avatarUrl": "https://cdn.greenrabbit.app/avatars/f47ac10b-58cc-4372-a567-0e02b2c3d479/profile_1710000000.jpg",
            "emailVerified": "true",
            "onboardingDone": "true",
            "status": "active",
            "preferences": {
                "language": "en",
                "theme": "dark",
                "currency": "AED",
                "notifications": {
                    "push": true,
                    "smart-alerts": true
                }
            },
            "subscription": {
                "tier": "free",
                "expiresAt": null,
                "autoRenew": false
            },
            "createdAt": "2025-03-01T10:00:00.000Z",
            "updatedAt": "2025-03-08T14:00:00.000Z",
            "lastLoginAt": "2025-03-08T14:30:00.000Z"
        },
        "message": "Profile Updated Successfully"
    }
}
```

---

## Upload or Replace Avatar
Uploads or replaces the authenticated user's profile avatar.

- **URL:** `/users/me/avatar`
- **Method:** `PUT`
- **Rate Limit:** 10 requests per minute
- **Content-Type:** `multipart/form-data`

### Request Body
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `avatar` | `file` | Yes | image/jpeg, image/png, or image/webp. Max 5 MB. |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "avatarUrl": "https://cdn.greenrabbit.app/avatars/f47ac10b-58cc-4372-a567-0e02b2c3d479/profile_1710003600.webp",
        "message": "Avatar updated successfully."
    }
}
```

---

## Update User Preferences
Updates app settings like language, theme, and notifications.

- **URL:** `/users/me/preferences`
- **Method:** `PUT`
- **Rate Limit:** 30 requests per minute

### Request Body (`application/json`)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `language` | `enum` | No | `en`, `ar` |
| `theme` | `enum` | No | `system`, `light`, `dark` |
| `currency` | `string` | No | ISO 4217 code (e.g., `AED`, `SAR`, `USD`) |
| `notifications`| `object`| No | `{ "push": bool, "smart-alerts": bool }` |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "preferences": {
            "language": "ar",
            "theme": "light",
            "currency": "SAR",
            "notifications": {
                "push": true,
                "smart-alerts": true
            }
        },
        "message": "Preferences updated successfully."
    }
}
```

---

## Submit Onboarding Questionnaire
Submits the initial questionnaire and activates the user account. Can only be called once.

- **URL:** `/users/me/onboarding`
- **Method:** `POST`
- **Rate Limit:** 10 requests per minute

### Request Body (`application/json`)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `experienceLevel`| `string`| Yes | `Beginner`, `Intermediate`, `Expert` |
| `interestedIn` | `string` | No | e.g., `Crypto,Forex,Stock` |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "message": "Onboarding completed successfully. Welcome to Green Rabbit!",
        "user": {
            "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "fullName": "Omar Al-Rashid",
            "email": "omar.rashid@example.com",
            "emailVerified": true,
            "onboardingDone": true,
            "status": "active"
        }
    }
}
```

---

## Delete User Account
Initiates account deletion with a 30-day grace period.

- **URL:** `/users/me`
- **Method:** `DELETE`
- **Rate Limit:** 5 requests per minute

### Request Body (`application/json`)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `password` | `string` | Yes | Current password for re-authentication |
| `reason` | `string` | Yes | Reason enum (e.g., `no_longer_needed`, `found_alternative`) |
| `feedback` | `string` | No | Optional text feedback |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "message": "Your account has been scheduled for deletion. You have 30 days to recover your account...",
        "deletionScheduledAt": "2025-03-08T15:30:00.000Z",
        "permanentDeletionAt": "2025-04-07T15:30:00.000Z",
        "gracePeriodDays": 30
    }
}
```

---

## Register or Update FCM Device Token
Registers a Firebase Cloud Messaging token for push notifications.

- **URL:** `/users/me/fcm-token`
- **Method:** `POST`
- **Rate Limit:** 30 requests per minute

### Request Body (`application/json`)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `fcmToken` | `string` | Yes | Firebase registration token |
| `deviceType` | `string` | Yes | `ios`, `android` |
| `deviceId` | `uuid` | Yes | Unique device identifier |
| `deviceName` | `string` | No | e.g., `Samsung Galaxy S24 Ultra` |
| `appVersion` | `string` | No | Semantic version (e.g., `1.2.0`) |
| `osVersion` | `string` | No | Device OS version string |

### Response (`200 OK`)
```json
{
    "success": true,
    "data": {
        "message": "FCM token registered successfully.",
        "device": {
            "deviceId": "a1b2c3d4-e5f6-7890-abcd-ef0123456789",
            "deviceType": "android",
            "deviceName": "Samsung Galaxy S24 Ultra",
            "appVersion": "1.2.0",
            "osVersion": "Android 15",
            "registeredAt": "2025-03-08T15:00:00.000Z",
            "updatedAt": "2025-03-08T15:00:00.000Z"
        }
    }
}
```
