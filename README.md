# Automated Stock Analyzer

> An AI-powered stock screening and portfolio monitoring platform that automatically analyzes market data, identifies trading opportunities using technical indicators, generates entry/exit alerts, provides AI-based stock insights, and evaluates strategies through historical backtesting.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)

---

## Overview
Automated Stock Analyzer is a full-stack web application that:
- Collects daily stock market data from external APIs
- Stores data in a PostgreSQL database
- Calculates technical indicators (MA, RSI, Volume, Momentum)
- Applies screening filters to identify trading opportunities
- Sends email alerts for buy/sell signals
- Provides AI-generated stock summaries
- Supports historical backtesting of trading strategies

---

## Features
| Feature | Description |
|---|---|
| **Stock Screener** | Filter stocks by 220-DMA, 50-DMA, 52-week high, volume breakout, RSI |
| **Watchlist** | Add and track personal stock watchlists |
| **Entry/Exit Alerts** | Buy/Sell signal generation with threshold-based triggers |
| **Email Notifications** | Automated alerts via Spring Mail |
| **AI Stock Summary** | OpenAI-powered natural language stock analysis |
| **Historical Backtesting** | Strategy evaluation with return, win rate, drawdown metrics |

---

## Tech Stack

### Frontend
- React.js + Tailwind CSS
- React Router, Axios
- Chart.js / Recharts

### Backend
- Java 17, Spring Boot 3
- Spring Data JPA, Spring Scheduler, Spring Mail
- JWT Authentication

### Database
- PostgreSQL

### APIs
- Yahoo Finance API
- Alpha Vantage API
- Twelve Data API
- OpenAI API

---

## Project Structure
```
Automated-Stock-Analyzer/
├── frontend/               # React frontend
│   └── src/
│       ├── components/     # Reusable UI components
│       ├── pages/          # Page-level views
│       └── services/       # Axios API calls
├── backend/                # Spring Boot backend
│   └── src/main/java/
│       ├── controller/     # REST controllers
│       ├── service/        # Business logic
│       ├── repository/     # JPA repositories
│       ├── entity/         # JPA entities
│       ├── dto/            # Data Transfer Objects
│       ├── config/         # App configuration
│       └── scheduler/      # Scheduled jobs
├── database/
│   ├── schema.sql          # Table definitions
│   └── sample_data.sql     # Seed data
└── docs/
    ├── architecture.md     # System architecture
    └── api_documentation.md
```

---

## Getting Started

### Prerequisites
- Java 17+
- Node.js 18+
- PostgreSQL 14+
- Maven 3.8+

### Backend
```bash
cd backend
cp src/main/resources/application.properties.example src/main/resources/application.properties
# fill in your DB credentials and API keys
mvn spring-boot:run
```

### Frontend
```bash
cd frontend
npm install
npm start
```

### Database
```bash
psql -U postgres -c "CREATE DATABASE stock_analyzer;"
psql -U postgres -d stock_analyzer -f database/schema.sql
psql -U postgres -d stock_analyzer -f database/sample_data.sql
```

---

## Environment Variables

| Variable | Description |
|---|---|
| `DB_URL` | PostgreSQL JDBC URL |
| `DB_USERNAME` | Database username |
| `DB_PASSWORD` | Database password |
| `ALPHA_VANTAGE_KEY` | Alpha Vantage API key |
| `TWELVE_DATA_KEY` | Twelve Data API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `MAIL_USERNAME` | SMTP email address |
| `MAIL_PASSWORD` | SMTP email password |
| `JWT_SECRET` | JWT signing secret |

---

## API Documentation
See [docs/api_documentation.md](docs/api_documentation.md) for full REST API reference.

---

## Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes
4. Push and open a Pull Request
