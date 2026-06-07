-- =============================================================
-- Automated Stock Analyzer — Database Schema
-- =============================================================

-- Users & Auth
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    role        VARCHAR(20)  NOT NULL DEFAULT 'USER',
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Stocks (master list)
CREATE TABLE stocks (
    id           BIGSERIAL PRIMARY KEY,
    symbol       VARCHAR(20)  NOT NULL UNIQUE,
    name         VARCHAR(200) NOT NULL,
    exchange     VARCHAR(20),
    sector       VARCHAR(100),
    industry     VARCHAR(100),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Daily OHLCV price data
CREATE TABLE stock_prices (
    id            BIGSERIAL PRIMARY KEY,
    stock_id      BIGINT       NOT NULL REFERENCES stocks(id),
    trade_date    DATE         NOT NULL,
    open_price    NUMERIC(12,4),
    high_price    NUMERIC(12,4),
    low_price     NUMERIC(12,4),
    close_price   NUMERIC(12,4) NOT NULL,
    adj_close     NUMERIC(12,4),
    volume        BIGINT,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE (stock_id, trade_date)
);

-- Calculated technical indicators
CREATE TABLE technical_indicators (
    id             BIGSERIAL PRIMARY KEY,
    stock_id       BIGINT       NOT NULL REFERENCES stocks(id),
    trade_date     DATE         NOT NULL,
    ma_50          NUMERIC(12,4),
    ma_220         NUMERIC(12,4),
    rsi_14         NUMERIC(8,4),
    volume_avg_20  BIGINT,
    week_52_high   NUMERIC(12,4),
    week_52_low    NUMERIC(12,4),
    momentum_score NUMERIC(8,4),
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE (stock_id, trade_date)
);

-- Generated buy/sell signals
CREATE TABLE signals (
    id           BIGSERIAL PRIMARY KEY,
    stock_id     BIGINT      NOT NULL REFERENCES stocks(id),
    signal_date  DATE        NOT NULL,
    signal_type  VARCHAR(10) NOT NULL CHECK (signal_type IN ('BUY', 'SELL', 'HOLD')),
    strategy     VARCHAR(100),
    trigger_price NUMERIC(12,4),
    notes        TEXT,
    created_at   TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- User watchlists
CREATE TABLE watchlists (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT       NOT NULL REFERENCES users(id),
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE watchlist_stocks (
    id           BIGSERIAL PRIMARY KEY,
    watchlist_id BIGINT NOT NULL REFERENCES watchlists(id) ON DELETE CASCADE,
    stock_id     BIGINT NOT NULL REFERENCES stocks(id),
    added_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (watchlist_id, stock_id)
);

-- Alert thresholds set by users
CREATE TABLE alerts (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT       NOT NULL REFERENCES users(id),
    stock_id      BIGINT       NOT NULL REFERENCES stocks(id),
    alert_type    VARCHAR(20)  NOT NULL,  -- PRICE_ABOVE, PRICE_BELOW, MA_CROSSOVER, etc.
    threshold     NUMERIC(12,4),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    last_triggered TIMESTAMP,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- AI-generated stock summaries
CREATE TABLE ai_summaries (
    id           BIGSERIAL PRIMARY KEY,
    stock_id     BIGINT    NOT NULL REFERENCES stocks(id),
    summary_date DATE      NOT NULL,
    summary_text TEXT      NOT NULL,
    model_used   VARCHAR(50),
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (stock_id, summary_date)
);

-- Historical backtest results
CREATE TABLE backtest_results (
    id                BIGSERIAL PRIMARY KEY,
    user_id           BIGINT       NOT NULL REFERENCES users(id),
    strategy_name     VARCHAR(100) NOT NULL,
    stock_id          BIGINT       REFERENCES stocks(id),  -- NULL means portfolio-wide
    start_date        DATE         NOT NULL,
    end_date          DATE         NOT NULL,
    total_return_pct  NUMERIC(8,4),
    win_rate_pct      NUMERIC(8,4),
    total_trades      INT,
    max_drawdown_pct  NUMERIC(8,4),
    created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_stock_prices_stock_date ON stock_prices(stock_id, trade_date DESC);
CREATE INDEX idx_indicators_stock_date   ON technical_indicators(stock_id, trade_date DESC);
CREATE INDEX idx_signals_date            ON signals(signal_date DESC);
CREATE INDEX idx_signals_type            ON signals(signal_type);
