# GreenRabbit API Documentation - Market Features

## 1. Get market overview by type
**GET** `/market/overview/{type}`

Returns a paginated list of market instruments.

### Path Params
- `type`: `stocks`, `crypto`, `forex` (Required)

### Query Params
- `page`: integer (Default: 1)
- `limit`: integer (Default: 20, Max: 50)
- `sort`: `default`, `price_asc`, `price_desc`, `change_asc`, `change_desc`, `name_asc`, `name_desc`
- `search`: string
- `sector`: `technology`, `healthcare`, etc. (stocks only)
- `currency`: string (ISO 4217)

### Response Example
```json
{
    "success": true,
    "data": {
        "type": "stocks",
        "marketStatus": "open",
        "lastUpdatedAt": "2025-03-08T14:30:00.000Z",
        "instruments": [
            {
                "id": "stock:AAPL",
                "symbol": "AAPL",
                "name": "Apple Inc.",
                "type": "stock",
                "exchange": "NASDAQ",
                "sector": "technology",
                "currency": "USD",
                "price": 178.72,
                "previousClose": 175.1,
                "change": 3.62,
                "changePercent": 2.07,
                "dayHigh": 179.43,
                "dayLow": 175.82,
                "volume": 58432100,
                "marketCap": 2780000000000,
                "logoUrl": "https://cdn.greenrabbit.app/logos/stocks/AAPL.png",
                "sparkline7d": [172.5, 173.2, 174.8, 175.1, 176.3, 177.9, 178.72]
            }
        ]
    },
    "meta": {
        "page": 1,
        "limit": 20,
        "totalItems": 156,
        "totalPages": 8,
        "hasNext": true,
        "hasPrev": false
    }
}
```

## 2. Get instrument details
**GET** `/market/instruments/{id}`

Returns detailed information for a single market instrument.

### Path Params
- `id`: Namespaced instrument ID (e.g., `stock:AAPL`, `crypto:BTC-USD`)

### Response Example
```json
{
    "success": true,
    "data": {
        "instrument": {
            "id": "stock:AAPL",
            "symbol": "AAPL",
            "name": "Apple Inc.",
            "type": "stock",
            "exchange": "NASDAQ",
            "sector": "technology",
            "industry": "Consumer Electronics",
            "currency": "USD",
            "description": "...",
            "website": "https://www.apple.com",
            "logoUrl": "...",
            "country": "US",
            "price": {
                "current": 178.72,
                "previousClose": 175.1,
                "open": 176.15,
                "dayHigh": 179.43,
                "dayLow": 175.82,
                "week52High": 199.62,
                "week52Low": 143.9,
                "change": 3.62,
                "changePercent": 2.07,
                "lastUpdatedAt": "2025-03-08T14:30:00.000Z"
            },
            "volume": {
                "current": 58432100,
                "average10d": 52100000,
                "average3m": 48700000
            },
            "fundamentals": {
                "marketCap": 2780000000000,
                "enterpriseValue": 2850000000000,
                "peRatio": 28.45,
                "forwardPeRatio": 26.12,
                "pegRatio": 1.85,
                "priceToBook": 45.2,
                "priceToSales": 7.35,
                "eps": 6.28,
                "dividendYield": 0.55,
                "dividendPerShare": 0.96,
                "beta": 1.24,
                "sharesOutstanding": 15550000000,
                "floatShares": 15480000000,
                "revenue": 383290000000,
                "revenueGrowth": 2.07,
                "grossMargin": 45.96,
                "operatingMargin": 30.74,
                "profitMargin": 25.31,
                "earningsDate": "2025-04-24T00:00:00.000Z",
                "exDividendDate": "2025-02-10T00:00:00.000Z"
            },
            "marketStatus": "open",
            "tradingHours": {
                "timezone": "America/New_York",
                "regularOpen": "09:30",
                "regularClose": "16:00",
                "preMarketOpen": "04:00",
                "afterHoursClose": "20:00"
            },
            "relatedInstruments": [
                {
                    "id": "stock:MSFT",
                    "symbol": "MSFT",
                    "name": "Microsoft Corporation",
                    "changePercent": 0.79
                }
            ]
        }
    }
}
```

## 3. Get instrument chart data (OHLCV)
**GET** `/market/instruments/{id}/chart`

### Response Example
```json
{
    "success": true,
    "data": {
        "instrumentId": "stock:AAPL",
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "currency": "USD",
        "period": "1D",
        "interval": "5m",
        "marketStatus": "open",
        "dataPoints": 78,
        "startTime": "2025-03-08T09:30:00.000Z",
        "endTime": "2025-03-08T16:00:00.000Z",
        "lastUpdatedAt": "2025-03-08T14:30:00.000Z",
        "summary": {
            "open": 176.15,
            "high": 179.43,
            "low": 175.82,
            "close": 178.72,
            "volume": 58432100,
            "change": 3.62,
            "changePercent": 2.07,
            "vwap": 177.85
        },
        "candles": [
            {
                "timestamp": "2025-03-08T09:30:00.000Z",
                "open": 176.15,
                "high": 176.82,
                "low": 175.9,
                "close": 176.5,
                "volume": 2145600
            }
        ]
    }
}
```

## 4. Get instrument statistics
**GET** `/market/instruments/{id}/stats`

... (Detailed structure containing performance, volatility, technicals, analyst ratings, dividends, earnings)

## 5. Get instrument news
**GET** `/market/instruments/{id}/news`

### Response Example
```json
{
    "success": true,
    "data": {
        "instrumentId": "stock:AAPL",
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "articles": [
            {
                "id": "news:a1b2c3d4-e5f6-7890-abcd-000000000001",
                "title": "...",
                "summary": "...",
                "source": { "name": "Reuters", "id": "reuters", "logoUrl": "..." },
                "publishedAt": "2025-03-08T13:45:00.000Z"
            }
        ]
    }
}
```

## 6. Get trending instruments
**GET** `/market/trending`

### Response Example
```json
{
    "success": true,
    "data": {
        "trending": [
            {
                "rank": 1,
                "instrument": { "id": "crypto:BTC-USD", ... }
            }
        ]
    }
}
```

## 7. Real-time market data stream (SSE)
**GET** `/market/stream`

Establishes a Server-Sent Events (SSE) connection.

## 8. Get All Watchlists
**GET** `/watchlists`

Retrieves all watchlists belonging to the authenticated user.

### Response Example
```json
{
    "success": true,
    "data": {
        "watchlists": [
            {
                "id": "wl_a1b2c3d4e5f6",
                "name": "Tech Giants",
                "description": "Major technology companies",
                "is_default": true,
                "instruments_count": 5,
                "instruments": [
                    {
                        "id": "inst_001",
                        "symbol": "AAPL",
                        "name": "Apple Inc.",
                        "type": "stock",
                        "exchange": "NASDAQ",
                        "logo_url": "https://cdn.greenrabbit.app/logos/aapl.png",
                        "current_price": 196.45,
                        "price_change": 3.25,
                        "price_change_percent": 1.68,
                        "display_order": 1
                    }
                ],
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-07-31T14:20:00Z"
            }
        ]
    },
    "meta": {
        "total": 1
    }
}
```

## 9. Create Watchlist
**POST** `/watchlists`

### Body Params
- `name`: string (Required)
- `description`: string (Optional)

## 10. Update Watchlist
**PUT** `/watchlists/{id}`

## 11. Delete Watchlist
**DELETE** `/watchlists/{id}`

## 12. Add Instrument to Watchlist
**POST** `/watchlists/{id}/instruments`

### Body Params
- `instrumentId`: string (Required)

## 13. Remove Instrument from Watchlist
**DELETE** `/watchlists/{id}/instruments/{instrumentId}`

## 15. Get All Alerts
**GET** `/alerts`

Retrieves all price alerts for the authenticated user with optional status filtering and pagination.

### Query Params
- `status`: `all`, `active`, `triggered` (Default: `all`)
- `page`: integer (Default: 1)
- `limit`: integer (Default: 10, Max: 50)

### Response Example
```json
{
    "success": true,
    "data": {
        "alerts": [
            {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef0123456789",
                "instrument": {
                    "id": "AAPL",
                    "symbol": "AAPL",
                    "name": "Apple Inc.",
                    "type": "stock",
                    "exchange": "NASDAQ",
                    "logoUrl": "https://cdn.greenrabbit.app/logos/aapl.png",
                    "currentPrice": 196.45
                },
                "targetPrice": 200,
                "type": "price_above",
                "typeDisplay": "Price goes above $200.00",
                "status": "active",
                "createdAt": "2024-07-15T10:30:00Z",
                "updatedAt": "2024-07-15T10:30:00Z",
                "triggeredAt": null,
                "triggeredPrice": null
            }
        ],
        "summary": { "total": 5, "active": 3, "triggered": 2 },
        "meta": { "page": 1, "limit": 10, "total": 5, "totalPages": 1, "hasNext": false, "hasPrevious": false }
    }
}
```

## 16. Create Alert
**POST** `/alerts`

### Body Params
- `instrumentId`: string (Required)
- `targetPrice`: number (Required)
- `type`: `price_above`, `price_below` (Required)

## 17. Delete Alert
**DELETE** `/alerts/{id}`

## 18. List Notifications
**GET** `/notifications`

### Query Params
- `page`: integer (Default: 1)
- `limit`: integer (Default: 20, Max: 100)
- `type`: `all`, `price_alert`, `news`, `system`, `ai_insight` (Default: `all`)
- `isRead`: boolean

### Response Example
```json
{
    "success": true,
    "data": {
        "notifications": [
            {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef0123456789",
                "type": "price_alert",
                "title": "AAPL Price Alert",
                "body": "AAPL reached $250.50 — above your $200.00 target",
                "data": {
                    "alertId": "b2c3d4e5-f6a7-8901-bcde-f01234567890",
                    "instrumentId": "inst_001",
                    "instrumentSymbol": "AAPL",
                    "type": "price_alert",
                    "deepLink": "/instruments/inst_001"
                },
                "isRead": false,
                "createdAt": "2024-07-20T14:30:00Z"
            }
        ]
    },
    "meta": { "page": 1, "limit": 20, "total": 5, "totalPages": 1, "hasNext": false, "hasPrevious": false }
}
```

## 19. Mark Notification as Read
**PUT** `/notifications/{id}/read`

## 20. Mark All Notifications as Read
**PUT** `/notifications/read-all`

## 21. Delete Notification
**DELETE** `/notifications/{id}`

## 22. Get Unread Notification Count
**GET** `/notifications/unread-count`
