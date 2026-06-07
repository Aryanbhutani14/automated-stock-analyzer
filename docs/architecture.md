# System Architecture — Automated Stock Analyzer

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                         │
│                 React.js + Tailwind CSS                     │
│         (Dashboard / Screener / Watchlist / Backtest)       │
└─────────────────────┬───────────────────────────────────────┘
                      │  HTTPS / REST + JWT
┌─────────────────────▼───────────────────────────────────────┐
│                      API GATEWAY LAYER                      │
│              Spring Boot REST Controllers                   │
│            (Auth / Stock / Signal / Watchlist)              │
└──────────┬──────────────────────┬──────────────────────────-┘
           │                      │
┌──────────▼──────┐    ┌──────────▼───────────────────────────┐
│  Business Layer │    │          Scheduler Layer              │
│  Spring Services│    │  Spring @Scheduled (daily cron job)   │
│  - ScreenerSvc  │    │  1. Fetch OHLCV from APIs             │
│  - SignalSvc    │    │  2. Calculate indicators              │
│  - BacktestSvc  │    │  3. Run screener                      │
│  - AI Summary   │    │  4. Generate signals                  │
│  - EmailSvc     │    │  5. Send email alerts                 │
└──────────┬──────┘    │  6. Generate AI summaries             │
           │           └──────────────────────────────────────┘
┌──────────▼──────────────────────────────────────────────────┐
│                     PERSISTENCE LAYER                       │
│               Spring Data JPA + PostgreSQL                  │
│  Tables: stocks | stock_prices | technical_indicators       │
│          signals | watchlists | alerts | ai_summaries       │
│          backtest_results | users                           │
└─────────────────────────────────────────────────────────────┘
           │
┌──────────▼──────────────────────────────────────────────────┐
│                    EXTERNAL APIs                            │
│   Yahoo Finance | Alpha Vantage | Twelve Data | OpenAI      │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Daily Scheduler Workflow
1. **6:30 PM IST** — Cron job triggers after market close
2. **Data Fetch** — Pull OHLCV for all active stocks
3. **Store** — Persist to `stock_prices` table
4. **Indicators** — Calculate MA50, MA220, RSI14, volume avg, 52-wk high/low
5. **Screening** — Apply filter rules, persist results to `signals`
6. **Alerts** — Query `alerts` table, send emails via Spring Mail
7. **AI Summary** — Call OpenAI API per stock, store in `ai_summaries`
8. **Dashboard** — Frontend polls updated data on next load

## Authentication Flow
- User logs in → `/api/auth/login` → returns JWT
- Frontend stores JWT in `localStorage`
- All subsequent requests include `Authorization: Bearer <token>`
- Spring Security filter validates JWT on each request

## Technical Indicator Calculations
| Indicator | Window | Description |
|---|---|---|
| MA-50 | 50 days | Simple Moving Average |
| MA-220 | 220 days | Simple Moving Average |
| RSI | 14 days | Relative Strength Index |
| Volume Avg | 20 days | Average volume baseline |
| 52-Week High/Low | 252 days | Rolling high/low |
| Momentum Score | 12 months | Price return % |
