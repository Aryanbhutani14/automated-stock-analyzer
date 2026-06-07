# API Documentation — Automated Stock Analyzer

Base URL: `http://localhost:8080/api`

All protected endpoints require: `Authorization: Bearer <JWT_TOKEN>`

---

## Authentication

### POST /api/auth/register
Register a new user.

**Request:**
```json
{ "username": "aryan", "email": "aryan@example.com", "password": "Test@1234" }
```
**Response:** `201 Created`
```json
{ "message": "User registered successfully" }
```

### POST /api/auth/login
Login and receive JWT.

**Request:**
```json
{ "email": "aryan@example.com", "password": "Test@1234" }
```
**Response:** `200 OK`
```json
{ "token": "eyJhbGci...", "type": "Bearer", "username": "aryan", "role": "USER" }
```

---

## Stocks

### GET /api/stocks
Get all active stocks.

### GET /api/stocks/{symbol}
Get stock details by symbol.

### GET /api/stocks/{symbol}/price-history?from=YYYY-MM-DD&to=YYYY-MM-DD
Get OHLCV history for a stock.

### GET /api/stocks/{symbol}/indicators?date=YYYY-MM-DD
Get technical indicators for a stock on a given date.

---

## Screener

### GET /api/screener
Run screener with filters.

**Query Params:**
| Param | Type | Description |
|---|---|---|
| `filter` | string | `MA220_CROSSOVER`, `MA50_CROSSOVER`, `52W_HIGH`, `VOLUME_BREAKOUT`, `RSI_OVERSOLD`, `MOMENTUM` |
| `exchange` | string | `NSE`, `BSE` |
| `sector` | string | Filter by sector |
| `page` | int | Page number (default 0) |
| `size` | int | Page size (default 20) |

**Response:** `200 OK`
```json
{
  "content": [ { "symbol": "TCS", "name": "...", "closePrice": 3800.0, "signal": "BUY", ... } ],
  "totalElements": 150,
  "page": 0,
  "size": 20
}
```

---

## Signals

### GET /api/signals?date=YYYY-MM-DD&type=BUY
Get buy/sell signals for a date.

### GET /api/signals/{stockSymbol}
Get all signals for a specific stock.

---

## Watchlist

### GET /api/watchlists
Get all watchlists for the authenticated user.

### POST /api/watchlists
Create a new watchlist.
```json
{ "name": "My Top Picks", "description": "High conviction stocks" }
```

### POST /api/watchlists/{id}/stocks
Add stock to watchlist.
```json
{ "symbol": "RELIANCE" }
```

### DELETE /api/watchlists/{id}/stocks/{symbol}
Remove stock from watchlist.

---

## Alerts

### GET /api/alerts
Get user's configured alerts.

### POST /api/alerts
Create a new alert.
```json
{ "symbol": "TCS", "alertType": "PRICE_ABOVE", "threshold": 4000.0 }
```

### DELETE /api/alerts/{id}
Delete an alert.

---

## AI Summary

### GET /api/ai/summary/{symbol}
Get AI-generated summary for a stock.

**Response:**
```json
{
  "symbol": "TCS",
  "date": "2026-06-07",
  "summary": "TCS is trading above its 220-Day Moving Average with increasing volume and strong momentum, indicating a bullish trend..."
}
```

---

## Backtest

### POST /api/backtest
Run a backtest.
```json
{
  "strategy": "MA220_CROSSOVER",
  "symbol": "RELIANCE",
  "startDate": "2022-01-01",
  "endDate": "2024-12-31",
  "initialCapital": 100000
}
```

**Response:**
```json
{
  "strategy": "MA220_CROSSOVER",
  "totalReturnPct": 34.5,
  "winRatePct": 62.0,
  "totalTrades": 8,
  "maxDrawdownPct": -12.3
}
```
