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

  StockDetailModel({
    required this.stock,
    required this.history,
  });

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    return StockDetailModel(
      stock: StockModel.fromJson(json['stock'] as Map<String, dynamic>),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => PricePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
