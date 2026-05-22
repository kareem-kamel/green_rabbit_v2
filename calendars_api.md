# Calendars API Documentation

## Endpoint
**GET** `/api/calendars/{category}`

Returns calendar events for the specified category and time period.

### Path Parameters
* **`category`** (enum<string>, required): The calendar category to retrieve.
  * `earnings`
  * `dividends`
  * `splits`
  * `ipo`

### Query Parameters
* **`tab`** (enum<string>, optional): Time period selector. Valid values depend on the category (see Tab Rules below). Defaults to `this_week` for `earnings`/`dividends`/`splits`, and `recent` for `ipo`.
  * `yesterday`
  * `today`
  * `tomorrow`
  * `this_week`
  * `next_week`
  * `recent`
  * `upcoming`
* **`watchlist`** (boolean, optional): When `true`, returns only events for instruments present in any of the authenticated user's watchlists. Default is `false`. Not valid for the `ipo` category. Mutually exclusive with `symbol`. When active, the `country` filter is ignored.
* **`symbol`** (string, optional): Comma-separated list of ticker symbols to filter events (e.g. `AAPL,MSFT,GOOG`). Mutually exclusive with `watchlist`. When active, the `country` filter is ignored.
* **`country`** (string, optional): ISO 3166-1 alpha-2 country code (e.g. `US`, `GB`, `DE`) used to filter events by exchange country. Pass `all` to disable country filtering. When omitted, defaults to the authenticated user's profile country; if the user has no country set, defaults to `all`. This parameter is ignored when `watchlist` or `symbol` filters are active.

### Request Headers
* **`Authorization`** (string, required): JWT Bearer token.
  * Example: `Bearer <token>`

---

## Tab Rules

| Category | Valid Tabs | Default |
| :--- | :--- | :--- |
| **`earnings`** | `yesterday`, `today`, `tomorrow`, `this_week`, `next_week` | `this_week` |
| **`dividends`** | `yesterday`, `today`, `tomorrow`, `this_week`, `next_week` | `this_week` |
| **`splits`** | `yesterday`, `today`, `tomorrow`, `this_week`, `next_week` | `this_week` |
| **`ipo`** | `recent` (this week), `upcoming` (next week) | `recent` |

---

## Filter Priority
1. If `watchlist=true` → filter to user's watchlist instruments; `country` is ignored.
2. If `symbol` is set → filter to those symbols; `country` is ignored.
3. If neither → apply `country` filter (from query param, or user's profile country, or `all` if unset).

*Note: `watchlist` and `symbol` are mutually exclusive. `watchlist` is not valid for the `ipo` category.*

---

## Response Shapes

* **Week tabs** (`this_week`, `next_week`, `recent`, `upcoming`): returns a 7-day array (Monday–Sunday), each day containing an `events` array.
* **Day tabs** (`yesterday`, `today`, `tomorrow`): returns a single day with a flat `events` array.

Inside the `events` array, the shape of the objects varies by category (e.g., `EarningsEvent`, `DividendEvent`, `SplitEvent`, `IpoEvent`), but they all include a nested `instrument` object (except for `ipo` where it may be `null` if not matched).

---

## Example Responses

### 1. Earnings Calendar - Week Tab (this_week)
`GET /api/calendars/earnings?tab=this_week&country=US`

```json
{
    "success": true,
    "data": {
        "category": "earnings",
        "tab": "this_week",
        "startDate": "2026-04-13",
        "endDate": "2026-04-19",
        "totalEvents": 3,
        "days": [
            {
                "date": "2026-04-13",
                "dayName": "Monday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-14",
                "dayName": "Tuesday",
                "eventCount": 2,
                "events": [
                    {
                        "symbol": "AAPL",
                        "name": "Apple Inc",
                        "currency": "USD",
                        "exchange": "NASDAQ",
                        "time": "amc",
                        "epsEstimate": 1.72,
                        "epsActual": null,
                        "difference": null,
                        "surprisePercent": null,
                        "instrument": {
                            "id": "AAPL",
                            "name": "Apple Inc",
                            "symbol": "AAPL",
                            "type": "Common Stock",
                            "exchange": "NASDAQ",
                            "logoUrl": "https://storage.greenrabbit.app/logos/AAPL.png"
                        }
                    },
                    {
                        "symbol": "MSFT",
                        "name": "Microsoft Corporation",
                        "currency": "USD",
                        "exchange": "NASDAQ",
                        "time": "amc",
                        "epsEstimate": 2.83,
                        "epsActual": null,
                        "difference": null,
                        "surprisePercent": null,
                        "instrument": {
                            "id": "MSFT",
                            "name": "Microsoft Corporation",
                            "symbol": "MSFT",
                            "type": "Common Stock",
                            "exchange": "NASDAQ",
                            "logoUrl": "https://storage.greenrabbit.app/logos/MSFT.png"
                        }
                    }
                ]
            },
            {
                "date": "2026-04-15",
                "dayName": "Wednesday",
                "eventCount": 1,
                "events": [
                    {
                        "symbol": "JPM",
                        "name": "JPMorgan Chase & Co",
                        "currency": "USD",
                        "exchange": "NYSE",
                        "time": "bmo",
                        "epsEstimate": 4.11,
                        "epsActual": 4.44,
                        "difference": 0.33,
                        "surprisePercent": 8.03,
                        "instrument": {
                            "id": "JPM",
                            "name": "JPMorgan Chase & Co",
                            "symbol": "JPM",
                            "type": "Common Stock",
                            "exchange": "NYSE",
                            "logoUrl": "https://storage.greenrabbit.app/logos/JPM.png"
                        }
                    }
                ]
            },
            {
                "date": "2026-04-16",
                "dayName": "Thursday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-17",
                "dayName": "Friday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-18",
                "dayName": "Saturday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-19",
                "dayName": "Sunday",
                "eventCount": 0,
                "events": []
            }
        ]
    },
    "meta": {
        "appliedCountry": "US"
    }
}
```

### 2. Earnings Calendar - Day Tab (today)
`GET /api/calendars/earnings?tab=today&country=US`

```json
{
    "success": true,
    "data": {
        "category": "earnings",
        "tab": "today",
        "date": "2026-04-15",
        "dayName": "Wednesday",
        "totalEvents": 1,
        "events": [
            {
                "symbol": "JPM",
                "name": "JPMorgan Chase & Co",
                "currency": "USD",
                "exchange": "NYSE",
                "time": "bmo",
                "epsEstimate": 4.11,
                "epsActual": null,
                "difference": null,
                "surprisePercent": null,
                "instrument": {
                    "id": "JPM",
                    "name": "JPMorgan Chase & Co",
                    "symbol": "JPM",
                    "type": "Common Stock",
                    "exchange": "NYSE",
                    "logoUrl": "https://storage.greenrabbit.app/logos/JPM.png"
                }
            }
        ]
    },
    "meta": {
        "appliedCountry": "US"
    }
}
```

### 3. Dividends Calendar - Week Tab (this_week)
`GET /api/calendars/dividends?tab=this_week&country=US`

```json
{
    "success": true,
    "data": {
        "category": "dividends",
        "tab": "this_week",
        "startDate": "2026-04-13",
        "endDate": "2026-04-19",
        "totalEvents": 1,
        "days": [
            {
                "date": "2026-04-13",
                "dayName": "Monday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-14",
                "dayName": "Tuesday",
                "eventCount": 1,
                "events": [
                    {
                        "symbol": "MSFT",
                        "exchange": "NASDAQ",
                        "amount": 0.75,
                        "instrument": {
                            "id": "MSFT",
                            "name": "Microsoft Corporation",
                            "symbol": "MSFT",
                            "type": "Common Stock",
                            "exchange": "NASDAQ",
                            "logoUrl": "https://storage.greenrabbit.app/logos/MSFT.png"
                        }
                    }
                ]
            },
            {
                "date": "2026-04-15",
                "dayName": "Wednesday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-16",
                "dayName": "Thursday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-17",
                "dayName": "Friday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-18",
                "dayName": "Saturday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-19",
                "dayName": "Sunday",
                "eventCount": 0,
                "events": []
            }
        ]
    },
    "meta": {
        "appliedCountry": "US"
    }
}
```

### 4. Splits Calendar - Day Tab (today)
`GET /api/calendars/splits?tab=today&country=US`

```json
{
    "success": true,
    "data": {
        "category": "splits",
        "tab": "today",
        "date": "2026-04-15",
        "dayName": "Wednesday",
        "totalEvents": 1,
        "events": [
            {
                "symbol": "NVDA",
                "exchange": "NASDAQ",
                "description": "10-for-1 split",
                "ratio": 0.1,
                "fromFactor": 10,
                "toFactor": 1,
                "instrument": {
                    "id": "NVDA",
                    "name": "NVIDIA Corporation",
                    "symbol": "NVDA",
                    "type": "Common Stock",
                    "exchange": "NASDAQ",
                    "logoUrl": "https://storage.greenrabbit.app/logos/NVDA.png"
                }
            }
        ]
    },
    "meta": {
        "appliedCountry": "US"
    }
}
```

### 5. IPO Calendar - Week Tab (recent)
`GET /api/calendars/ipo?tab=recent&country=US`

```json
{
    "success": true,
    "data": {
        "category": "ipo",
        "tab": "recent",
        "startDate": "2026-04-13",
        "endDate": "2026-04-19",
        "totalEvents": 1,
        "days": [
            {
                "date": "2026-04-13",
                "dayName": "Monday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-14",
                "dayName": "Tuesday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-15",
                "dayName": "Wednesday",
                "eventCount": 1,
                "events": [
                    {
                        "symbol": "DWACU",
                        "name": "Digital World Acquisition Corp.",
                        "exchange": "NASDAQ",
                        "currency": "USD",
                        "priceRangeLow": 10,
                        "priceRangeHigh": 10,
                        "offerPrice": 0,
                        "shares": 0,
                        "instrument": null
                    }
                ]
            },
            {
                "date": "2026-04-16",
                "dayName": "Thursday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-17",
                "dayName": "Friday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-18",
                "dayName": "Saturday",
                "eventCount": 0,
                "events": []
            },
            {
                "date": "2026-04-19",
                "dayName": "Sunday",
                "eventCount": 0,
                "events": []
            }
        ]
    },
    "meta": {
        "appliedCountry": "US"
    }
}
```

### 6. Validation Error Example (e.g. invalid tab for IPO)
`GET /api/calendars/ipo?tab=yesterday`

```json
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Validation failed",
        "details": [
            {
                "field": "tab",
                "message": "IPO calendar only supports 'recent' and 'upcoming' tabs"
            }
        ]
    }
}
```
