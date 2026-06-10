class StockModel {
  final int id;
  final String symbol;
  final String name;
  final String exchange;
  final String sector;
  final String industry;
  final double? price;
  final double? change;
  final double? changePercent;
  final int? volume;

  StockModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.sector,
    required this.industry,
    this.price,
    this.change,
    this.changePercent,
    this.volume,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      exchange: json['exchange'] ?? '',
      sector: json['sector'] ?? '',
      industry: json['industry'] ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      change: json['change'] != null ? (json['change'] as num).toDouble() : null,
      changePercent: json['changePercent'] != null ? (json['changePercent'] as num).toDouble() : null,
      volume: json['volume'] != null ? (json['volume'] as num).toInt() : null,
    );
  }
}

class PricePoint {
  final DateTime date;
  final double? open;
  final double? high;
  final double? low;
  final double close;
  final int? volume;

  PricePoint({
    required this.date,
    this.open,
    this.high,
    this.low,
    required this.close,
    this.volume,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: DateTime.parse(json['date'] as String),
      open: json['open'] != null ? (json['open'] as num).toDouble() : null,
      high: json['high'] != null ? (json['high'] as num).toDouble() : null,
      low: json['low'] != null ? (json['low'] as num).toDouble() : null,
      close: (json['close'] as num).toDouble(),
      volume: json['volume'] != null ? (json['volume'] as num).toInt() : null,
    );
  }
}

class StockDetailModel {
  final StockModel stock;
  final List<PricePoint> history;
  final double? ma50;
  final double? ma220;
  final double? rsi14;
  final int? volumeAvg20;
  final double? week52High;
  final double? week52Low;
  final double? momentumScore;

  StockDetailModel({
    required this.stock,
    required this.history,
    this.ma50,
    this.ma220,
    this.rsi14,
    this.volumeAvg20,
    this.week52High,
    this.week52Low,
    this.momentumScore,
  });

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    return StockDetailModel(
      stock: StockModel.fromJson(json['stock'] as Map<String, dynamic>),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => PricePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ma50: json['ma50'] != null ? (json['ma50'] as num).toDouble() : null,
      ma220: json['ma220'] != null ? (json['ma220'] as num).toDouble() : null,
      rsi14: json['rsi14'] != null ? (json['rsi14'] as num).toDouble() : null,
      volumeAvg20: json['volumeAvg20'] != null ? (json['volumeAvg20'] as num).toInt() : null,
      week52High: json['week52High'] != null ? (json['week52High'] as num).toDouble() : null,
      week52Low: json['week52Low'] != null ? (json['week52Low'] as num).toDouble() : null,
      momentumScore: json['momentumScore'] != null ? (json['momentumScore'] as num).toDouble() : null,
    );
  }
}

class SignalModel {
  final int id;
  final String symbol;
  final DateTime signalDate;
  final String signalType; // BUY, SELL, HOLD
  final String strategy;
  final double triggerPrice;
  final String notes;

  SignalModel({
    required this.id,
    required this.symbol,
    required this.signalDate,
    required this.signalType,
    required this.strategy,
    required this.triggerPrice,
    required this.notes,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) {
    final stockJson = json['stock'] as Map<String, dynamic>;
    return SignalModel(
      id: json['id'] as int,
      symbol: stockJson['symbol'] as String,
      signalDate: DateTime.parse(json['signalDate'] as String),
      signalType: json['signalType'] as String,
      strategy: json['strategy'] ?? '',
      triggerPrice: (json['triggerPrice'] as num).toDouble(),
      notes: json['notes'] ?? '',
    );
  }
}

class ScreenerResultModel {
  final String symbol;
  final String name;
  final String exchange;
  final String sector;
  final DateTime? tradeDate;
  final double? closePrice;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final int? volume;
  final double? ma50;
  final double? ma220;
  final double? rsi14;
  final int? volumeAvg20;
  final double? week52High;
  final double? week52Low;
  final double? momentumScore;
  final String matchedFilters;

  ScreenerResultModel({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.sector,
    this.tradeDate,
    this.closePrice,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.ma50,
    this.ma220,
    this.rsi14,
    this.volumeAvg20,
    this.week52High,
    this.week52Low,
    this.momentumScore,
    required this.matchedFilters,
  });

  factory ScreenerResultModel.fromJson(Map<String, dynamic> json) {
    return ScreenerResultModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      exchange: json['exchange'] ?? '',
      sector: json['sector'] ?? '',
      tradeDate: json['tradeDate'] != null ? DateTime.parse(json['tradeDate'] as String) : null,
      closePrice: json['closePrice'] != null ? (json['closePrice'] as num).toDouble() : null,
      openPrice: json['openPrice'] != null ? (json['openPrice'] as num).toDouble() : null,
      highPrice: json['highPrice'] != null ? (json['highPrice'] as num).toDouble() : null,
      lowPrice: json['lowPrice'] != null ? (json['lowPrice'] as num).toDouble() : null,
      volume: json['volume'] != null ? (json['volume'] as num).toInt() : null,
      ma50: json['ma50'] != null ? (json['ma50'] as num).toDouble() : null,
      ma220: json['ma220'] != null ? (json['ma220'] as num).toDouble() : null,
      rsi14: json['rsi14'] != null ? (json['rsi14'] as num).toDouble() : null,
      volumeAvg20: json['volumeAvg20'] != null ? (json['volumeAvg20'] as num).toInt() : null,
      week52High: json['week52High'] != null ? (json['week52High'] as num).toDouble() : null,
      week52Low: json['week52Low'] != null ? (json['week52Low'] as num).toDouble() : null,
      momentumScore: json['momentumScore'] != null ? (json['momentumScore'] as num).toDouble() : null,
      matchedFilters: json['matchedFilters'] ?? '',
    );
  }
}

class WatchlistModel {
  final int id;
  final String name;
  final String description;
  final List<StockModel> stocks;
  final DateTime createdAt;

  WatchlistModel({
    required this.id,
    required this.name,
    required this.description,
    required this.stocks,
    required this.createdAt,
  });

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    return WatchlistModel(
      id: json['id'] as int,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stocks: (json['stocks'] as List<dynamic>?)
              ?.map((e) => StockModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AlertModel {
  final int id;
  final String symbol;
  final String name;
  final String alertType;
  final double? threshold;
  final bool active;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.alertType,
    this.threshold,
    required this.active,
    this.lastTriggered,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      alertType: json['alertType'] ?? '',
      threshold: json['threshold'] != null ? (json['threshold'] as num).toDouble() : null,
      active: json['active'] as bool? ?? true,
      lastTriggered: json['lastTriggered'] != null ? DateTime.parse(json['lastTriggered'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AiSummaryModel {
  final String symbol;
  final String summaryText;
  final DateTime summaryDate;
  final String modelUsed;

  AiSummaryModel({
    required this.symbol,
    required this.summaryText,
    required this.summaryDate,
    required this.modelUsed,
  });

  factory AiSummaryModel.fromJson(Map<String, dynamic> json) {
    return AiSummaryModel(
      symbol: json['symbol'] ?? '',
      summaryText: json['summaryText'] ?? '',
      summaryDate: DateTime.parse(json['summaryDate'] as String),
      modelUsed: json['modelUsed'] ?? '',
    );
  }
}

class TradeLogModel {
  final String type;
  final DateTime date;
  final double price;
  final double shares;
  final double value;
  final double? profitPct;

  TradeLogModel({
    required this.type,
    required this.date,
    required this.price,
    required this.shares,
    required this.value,
    this.profitPct,
  });

  factory TradeLogModel.fromJson(Map<String, dynamic> json) {
    return TradeLogModel(
      type: json['type'] ?? '',
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
      shares: (json['shares'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      profitPct: json['profitPct'] != null ? (json['profitPct'] as num).toDouble() : null,
    );
  }
}

class BacktestResultModel {
  final int? id;
  final String strategyName;
  final String symbol;
  final DateTime startDate;
  final DateTime endDate;
  final double? totalReturnPct;
  final double? winRatePct;
  final int? totalTrades;
  final double? maxDrawdownPct;
  final List<TradeLogModel> trades;
  final DateTime? createdAt;

  BacktestResultModel({
    this.id,
    required this.strategyName,
    required this.symbol,
    required this.startDate,
    required this.endDate,
    this.totalReturnPct,
    this.winRatePct,
    this.totalTrades,
    this.maxDrawdownPct,
    required this.trades,
    this.createdAt,
  });

  factory BacktestResultModel.fromJson(Map<String, dynamic> json) {
    return BacktestResultModel(
      id: json['id'] as int?,
      strategyName: json['strategyName'] ?? '',
      symbol: json['symbol'] ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalReturnPct: json['totalReturnPct'] != null ? (json['totalReturnPct'] as num).toDouble() : null,
      winRatePct: json['winRatePct'] != null ? (json['winRatePct'] as num).toDouble() : null,
      totalTrades: json['totalTrades'] != null ? (json['totalTrades'] as num).toInt() : null,
      maxDrawdownPct: json['maxDrawdownPct'] != null ? (json['maxDrawdownPct'] as num).toDouble() : null,
      trades: (json['trades'] as List<dynamic>?)
              ?.map((e) => TradeLogModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}
