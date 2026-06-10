# Automated Stock Analyzer

A professional, full-stack stock market analytics application designed for tracking, screening, and generating buy/sell trading signals on NIFTY 100 stocks. The project integrates a robust Spring Boot REST API backend with a high-performance, dark-themed Flutter mobile client.

---

## 🛠️ Technology Stack

### Backend
- **Core Framework**: Spring Boot 3.2 (Java 17 target compiler)
- **Security**: Spring Security + Stateless JWT Authentication
- **Database**: PostgreSQL (relational database engine)
- **Data Access**: Spring Data JPA (Hibernate ORM)
- **Scheduling**: Spring `@Scheduled` cron jobs (daily pipelines)
- **APIs**: RestTemplate-based fetching (Yahoo Finance data syncing)

### Mobile Client
- **Framework**: Flutter SDK (Dart)
- **State Management**: Provider framework (`ChangeNotifierProvider`)
- **HTTP Client**: Dio (configured with interceptors for JWT bearer validation)
- **Persistence**: SharedPreferences (local session and secure token persistence)
- **UI & Custom Canvas**: CustomPaint-based vector sparkline graphing

---

## 🚀 Phase-Wise Roadmap & Implementation

### 🏁 Phase 1: Security Foundation & Authentication
- **Backend Setup**: Initialized PostgreSQL tables and schema mapping. Configured Spring Security stateless session rules.
- **JWT Authentication Flow**:
  - Implemented `JwtUtils` HS256-token generators.
  - Implemented custom `JwtAuthFilter` processing headers for `Authorization: Bearer <JWT_TOKEN>`.
  - Added endpoints `/api/auth/register`, `/api/auth/login`, and `/api/auth/me`.
- **Flutter Screens**: Constructed premium, interactive dark-themed **Register Screen** and **Login Screen** validation forms.

### 📈 Phase 2: Stock DB Seeding & Sparkline Dashboard
- **Database Seeding**: Created `DatabaseSeeder` executing on startup to wipe legacy mock data and seed official NIFTY 100 stock details.
- **Data Sync Pipeline**: Built `YahooFinanceService` utilizing custom User-Agents to fetch 1 year of daily historical prices (OHLCV) on-demand or in bulk.
- **Dashboard UI**:
  - Displays market indices (Nifty 50 and Sensex) with color-coded daily ticks.
  - Displays list of active tracked stocks with latest closing prices and daily price variations.
  - Implemented a custom CustomPaint `SparklinePainter` to draw interactive 1-year historical pricing charts directly inside stock details sheet.

### 🔍 Phase 3: Technical Indicators & Screener Engine
- **Calculations Pipeline**: Implemented `TechnicalIndicatorService` calculating daily indicators using historical series data:
  - **MA-50 & MA-220**: Simple Moving Averages.
  - **RSI-14**: Relative Strength Index smoothed via Wilder's algorithm.
  - **Volume Avg-20**: 20-day average volume baseline.
  - **52-Week High / Low**: Rolling 252-day peaks/troughs.
  - **Momentum Score**: 12-month trailing return %.
- **Buy/Sell Signal Generator**: Created `SignalService` evaluating crossovers:
  - `MA220_CROSSOVER` / `MA50_CROSSOVER`: Triggered on price crossing MA lines (checks yesterday vs. today).
  - `RSI_OVERSOLD` / `RSI_OVERBOUGHT`: Triggered when RSI < 35 or RSI > 70.
  - `WEEK_52_HIGH`: Triggered when closing within 2% of the rolling yearly high.
  - `VOLUME_BREAKOUT`: Triggered when trading volume exceeds 1.5x of the 20-day average under price appreciation.
- **Stock Screener**: Implemented `ScreenerService` and `ScreenerController` to filter stocks passing technical screeners.
- **Client Upgrade**: Restructured Flutter client into a 3-tab Bottom Navigation interface:
  - **Dashboard**: Tracked stocks overview & market metrics.
  - **Screener**: Filter stocks interactively using strategy tags, exchanges, and sectors list.
  - **Signals**: Real-time feed of signals triggered today with strategy metrics.
  - **Updated Details Sheet**: Displays a premium indicators grid showing current indicators status, and a chronological history of signals generated for the stock.

### 📅 Phase 4: Watchlists, Price Alerts, AI & Backtester [Completed]
- **Watchlists**: Enabled users to create multiple watchlists, adding/removing stocks dynamically with current indicators.
- **Custom Alerts**: Configured price/indicator thresholds (MA crossovers, RSI levels, volume breakouts) to trigger async HTML card-based email alerts with daily duplicate trigger checks.
- **AI Summary Profile**: Integrated OpenAI `gpt-4o-mini` to construct dynamic technical profiles from live parameters with offline mock fallbacks.
- **Strategy Backtester**: Simulates strategy trading returns on historical stock prices, computing total returns, win rates, max drawdown, and displaying transaction ledgers.
- **Flutter UI Upgrades**: Restructured client into a 5-tab Bottom Navigation bar, added dynamic AI summary cards to the detail view sheets, and implemented watchlist toggle check-sheets.

---

## 📂 Project Structure

```
automated-stock-analyzer/
│
├── backend/                       # Spring Boot REST API
│   ├── src/main/java/com/stockanalyzer/backend/
│   │   ├── config/                # Database/Startup configs
│   │   ├── controller/            # REST API Controllers (Auth, Stock, Screener, Signal, Admin)
│   │   ├── dto/                   # Data Transfer Objects
│   │   ├── model/                 # JPA Entities (User, Stock, StockPrice, TechnicalIndicator, Signal)
│   │   ├── repository/            # Spring Data JPA interfaces
│   │   ├── scheduler/             # Pipeline Scheduler
│   │   ├── security/              # Spring Security + JWT filter logic
│   │   └── service/               # Calculation & business service layers
│   └── src/main/resources/        # application.properties settings
│
├── mobile/                        # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/                  # Color configurations & UI theme
│   │   ├── data/
│   │   │   ├── api/               # Dio Client requests mapping
│   │   │   └── models/            # Dart data models parsing JSON
│   │   ├── providers/             # AuthProvider & StockProvider logic
│   │   ├── screens/               # Login, Register, & Dashboard (Bottom nav + modals)
│   │   └── main.dart              # Flutter run configurations
```

---

## 🚀 Running the Project

### Database Configuration
Ensure PostgreSQL is running locally and database named `stock_analyzer` exists. Open [application.properties](file:///c:/Users/ARYAN%20BHUTANI/Desktop/Automated_stock_analyzer/backend/src/main/resources/application.properties) and customize configuration:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/stock_analyzer
spring.datasource.username=postgres
spring.datasource.password=YOUR_PASSWORD
```

### Starting the Backend REST API
Navigate to the `backend` directory and compile/run via Maven wrapper:
```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

### Starting the Flutter Client
Make sure Flutter SDK and an Android/iOS emulator or device are configured:
```powershell
cd mobile
flutter pub get
flutter run
```

#### 📱 API Host Configuration (Emulator vs. Physical Device)
Depending on your development setup, make sure the `_host` variable in [auth_service.dart](file:///c:/Users/ARYAN%20BHUTANI/Desktop/Automated_stock_analyzer/mobile/lib/data/api/auth_service.dart) and [stock_provider.dart](file:///c:/Users/ARYAN%20BHUTANI/Desktop/Automated_stock_analyzer/mobile/lib/providers/stock_provider.dart) is configured correctly:

* **Android Emulator**: Set `_host` to `10.0.2.2` (routes to the computer's `localhost`).
* **Physical Android Device (Wi-Fi)**: Both your phone and computer must be on the same Wi-Fi network. Set `_host` to your computer's local IPv4 address (e.g., `192.168.1.12`).
* **Physical Android Device (USB / adb reverse)**: Connect your device via USB with USB debugging enabled. Set `_host` to `127.0.0.1` and run the following ADB command to forward port 8080:
  ```powershell
  adb reverse tcp:8080 tcp:8080
  ```
