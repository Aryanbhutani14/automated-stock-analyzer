# Automated Stock Analyzer

> An AI-powered stock screening and portfolio monitoring platform — Flutter mobile app + Spring Boot REST API + PostgreSQL.

---

## Tech Stack

| Layer    | Technology                              |
|----------|-----------------------------------------|
| Mobile   | Flutter 3 (Dart) — iOS & Android        |
| Backend  | Java 21, Spring Boot 3, Spring Security |
| Database | PostgreSQL 15                           |
| APIs     | Alpha Vantage, Twelve Data, OpenAI      |
| Auth     | JWT (HS256)                             |

---

## Project Structure

```
Automated-Stock-Analyzer/
├── mobile/               # Flutter app
│   ├── lib/
│   │   ├── core/         # Theme, constants, DI
│   │   ├── data/         # API clients, models, repositories
│   │   ├── providers/    # Riverpod state providers
│   │   └── screens/      # UI screens
│   └── pubspec.yaml
├── backend/              # Spring Boot API
│   ├── src/main/java/com/stockanalyzer/
│   │   ├── config/       # Security, JWT, Async
│   │   ├── controller/   # REST controllers
│   │   ├── service/      # Business logic
│   │   ├── repository/   # JPA repositories
│   │   ├── entity/       # JPA entities
│   │   ├── dto/          # Request/Response DTOs
│   │   └── scheduler/    # Daily data pipeline
│   └── pom.xml
├── database/
│   ├── schema.sql
│   └── sample_data.sql
└── docs/
    ├── architecture.md
    └── api_documentation.md
```

---

## Getting Started

### Backend
```bash
cd backend
# Set env vars: DB_URL, DB_USERNAME, DB_PASSWORD, ALPHA_VANTAGE_KEY, OPENAI_API_KEY, JWT_SECRET
mvn spring-boot:run
```

### Flutter App
```bash
cd mobile
flutter pub get
flutter run
```

### Database
```bash
psql -U postgres -c "CREATE DATABASE stock_analyzer;"
psql -U postgres -d stock_analyzer -f database/schema.sql
psql -U postgres -d stock_analyzer -f database/sample_data.sql
```

---

## Features
- JWT login / registration
- Dashboard with live stock prices + indicators
- Stock Screener (7 filter strategies)
- Watchlist management
- Price & indicator alerts with push email notifications
- AI-generated stock analysis (OpenAI)
- Historical backtesting (return %, win rate, max drawdown)
- Interactive price charts (fl_chart)
- Daily automated data pipeline (scheduler)
