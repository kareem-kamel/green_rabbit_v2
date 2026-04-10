# GreenRabbit Backend Endpoints Documentation

This document provides a comprehensive overview of the backend endpoints for the GreenRabbit Trading App.

## Table of Contents
1. [Authentication](#authentication)
2. [Users & Profile](#users--profile)
3. [Market Data](#market-data)
4. [Watchlists](#watchlists)
5. [Comments](#comments)
6. [News](#news)
7. [Search](#search)
8. [Alerts](#alerts)
9. [Notifications](#notifications)
10. [AI Features](#ai-features)
11. [Subscriptions & Payments](#subscriptions--payments)
12. [App Configuration](#app-configuration)
13. [Health Check](#health-check)

---

## Authentication <a name="authentication"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Register** | `POST` | `/auth/register` | Registers a new user. Sends a 6-digit OTP. User status starts as `pending_verification`. |
| **Login** | `POST` | `/auth/login` | Authenticates user. Returns access (1h) and refresh tokens. |
| **Refresh Token** | `POST` | `/auth/refresh` | Issues a new access token using a valid refresh token. |
| **Logout** | `POST` | `/auth/logout` | Blacklists the current refresh token in Redis. |
| **Verify Email** | `POST` | `/auth/verify-email` | Verifies email using the 6-digit OTP. |
| **Resend OTP** | `POST` | `/auth/resend-otp` | Resends verification OTP to user's email. |
| **Request Password Reset** | `POST` | `/auth/password-reset/request` | Initiates reset flow via OTP. |
| **Reset Password** | `POST` | `/auth/password-reset/reset` | Resets password using OTP. |
| **Change Password** | `POST` | `/auth/password-change` | Allows authenticated users to change password. |

### Auth Flow States
- `pending_verification`: Email not verified. No tokens issued on login.
- `pending_onboarding`: Email verified, but questionnaire not submitted. Tokens issued.
- `active`: Full access.

---

## Users & Profile <a name="users--profile"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Get Profile** | `GET` | `/users/me` | Returns complete user profile including stats and preferences. |
| **Update Profile** | `PATCH` | `/users/profile` | Updates name, country, phone. |
| **Update Avatar** | `POST` | `/users/avatar` | Uploads/replaces user avatar (`multipart/form-data`). |
| **Update Preferences** | `PATCH` | `/users/preferences` | Updates language, theme, currency, notifications. |
| **Submit Onboarding** | `POST` | `/users/onboarding` | Submits onboarding questionnaire. Only callable once. |
| **Delete Account** | `DELETE` | `/users/account` | Initiates account deletion. |
| **Update FCM Token** | `POST` | `/users/fcm-token` | Registers/updates Firebase Cloud Messaging token. |

---

## Market Data <a name="market-data"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Market Overview** | `GET` | `/market/overview/{type}` | Paginated list of instruments (stocks, crypto, forex). |
| **Instrument Details** | `GET` | `/market/instrument/{id}` | Detailed info, financials (stocks), metrics (crypto). |
| **Chart Data (OHLCV)** | `GET` | `/market/chart/{id}` | Candlestick data for charting. |
| **Instrument Stats** | `GET` | `/market/statistics/{id}` | Technical indicators (RSI, MACD), analyst ratings. |
| **Instrument News** | `GET` | `/market/news/{id}` | Relevant news for a specific instrument. |
| **Trending** | `GET` | `/market/trending` | Top trending instruments across types (momentum-based). |
| **Real-time (SSE)** | `GET` | `/market/stream` | Server-Sent Events for real-time price updates. |

---

## Watchlists <a name="watchlists"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **List Watchlists** | `GET` | `/watchlists` | Retrieves all watchlists for the user. |
| **Create Watchlist** | `POST` | `/watchlists` | Creates a new empty or populated watchlist. |
| **Update Watchlist** | `PATCH` | `/watchlists/{id}` | Updates metadata (name, description). |
| **Delete Watchlist** | `DELETE` | `/watchlists/{id}` | Deletes the watchlist and associations. |
| **Add Instrument** | `POST` | `/watchlists/{id}/instruments` | Adds an instrument to the watchlist. |
| **Remove Instrument**| `DELETE`| `/watchlists/{id}/instruments/{inst_id}` | Removes an instrument from the watchlist. |
| **Reorder** | `PUT` | `/watchlists/{id}/reorder` | Updates display order of instruments. |

---

## Comments <a name="comments"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Get Comments** | `GET` | `/comments` | Fetches comments for an `instrument` or `news_article`. |
| **Create Comment** | `POST` | `/comments` | Adds a new comment. |
| **Delete Comment** | `DELETE` | `/comments/{id}` | Deletes the user's own comment. |
| **Like Comment** | `POST` | `/comments/{id}/like` | Adds a like to a comment. |
| **Unlike Comment** | `DELETE` | `/comments/{id}/like` | Removes a like from a comment. |

---

## News <a name="news"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **News Feed** | `GET` | `/news/feed` | Returns the full main news screen feed. |
| **Article Details** | `GET` | `/news/article/{id}` | Retrieves full article content (including archived content). |
| **Favorite Article** | `POST` | `/news/favorites` | Adds article to favorites (triggers auto-archiving). |
| **Unfavorite** | `DELETE` | `/news/favorites/{id}` | Removes article from favorites. |
| **List Favorites** | `GET` | `/news/favorites` | Retrieves all favorited articles. |
| **Related Articles** | `GET` | `/news/related/{id}` | Fetches articles with similar topics/symbols. |

---

## Search <a name="search"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Global Search** | `GET` | `/search` | Global search across instruments and news. |
| **Search History** | `GET` | `/search/history` | Retrieves recent search queries. |
| **Clear History** | `DELETE` | `/search/history` | Clears all search history. |
| **Trending Search** | `GET` | `/search/trending` | Returns popular search queries. |

---

## Alerts <a name="alerts"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **List Alerts** | `GET` | `/alerts` | Retrieves all price alerts. |
| **Create Alert** | `POST` | `/alerts` | Sets a new price threshold alert. |
| **Toggle Alert** | `PATCH` | `/alerts/{id}/toggle` | Enables/disables an alert. |
| **Delete Alert** | `DELETE` | `/alerts/{id}` | Removes an alert. |

---

## Notifications <a name="notifications"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **List** | `GET` | `/notifications` | Paginated list of user notifications. |
| **Mark Read** | `PATCH` | `/notifications/{id}/read` | Marks a single notification as read. |
| **Mark All Read** | `PATCH` | `/notifications/read-all` | Marks all notifications as read. |
| **Delete** | `DELETE` | `/notifications/{id}` | Deletes a notification. |
| **Unread Count** | `GET` | `/notifications/unread-count`| Returns count of unread items. |

---

## AI Features <a name="ai-features"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Summarize** | `POST` | `/ai/summarize` | Generates bullet-point summaries of financial text. |
| **Usage Stats** | `GET` | `/ai/usage` | Token consumption and request counts. |
| **List Chats** | `GET` | `/ai/chats` | Retrieves Meyka AI chat threads. |
| **New Conversation**| `POST` | `/ai/chats` | Starts a new AI conversation. |
| **Get Messages** | `GET` | `/ai/chats/{id}/messages` | Retrieves messages in a thread. |
| **Send Message** | `POST` | `/ai/chats/{id}/messages` | Sends message and gets AI response. |
| **Delete Chat** | `DELETE` | `/ai/chats/{id}` | Deletes a conversation thread. |
| **Feedback** | `POST` | `/ai/feedback` | Thumbs up/down on AI responses. |

---

## Subscriptions & Payments <a name="subscriptions--payments"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **List Plans** | `GET` | `/subscriptions/plans` | Available plans, pricing, and features. |
| **Current Sub** | `GET` | `/subscriptions/current`| Active subscription details. |
| **Checkout** | `POST` | `/subscriptions/checkout`| Generates MyFatoorah payment URL. |
| **Webhook** | `POST` | `/webhooks/myfatoorah` | **PUBLIC.** Payment status callbacks. |
| **Cancel Sub** | `POST` | `/subscriptions/cancel` | Cancels subscription (remains active until EOP). |

---

## App Configuration <a name="app-configuration"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **App Config** | `GET` | `/config/app` | **PUBLIC.** Feature flags, versions, maintenance. |
| **Ad Config** | `GET` | `/config/ads` | **PUBLIC.** Tier-aware ad units (AdMob IDs). |
| **Privacy Policy** | `GET` | `/config/privacy` | **PUBLIC.** Current privacy policy document. |
| **Terms** | `GET` | `/config/terms` | **PUBLIC.** Current terms of service. |

---

## Health Check <a name="health-check"></a>

| Endpoint | Method | Path | Description |
| :--- | :--- | :--- | :--- |
| **Health Check** | `GET` | `/health` | **PUBLIC.** Service health status. |

---

> [!NOTE]
> All endpoints (except those marked **PUBLIC**) require a `Bearer <token>` in the `Authorization` header.
> The API base URL is derived from the environment configuration in the Flutter app.
