package com.stockanalyzer.backend.model;

public enum AlertType {
    PRICE_ABOVE,
    PRICE_BELOW,
    MA50_CROSSOVER_UP,
    MA50_CROSSOVER_DOWN,
    MA220_CROSSOVER_UP,
    MA220_CROSSOVER_DOWN,
    RSI_OVERBOUGHT,
    RSI_OVERSOLD,
    VOLUME_BREAKOUT,
    WEEK_52_HIGH
}
