class StockModel {
  final int?    id;
  final String  symbol;
  final String  name;
  final String? exchange;
  final String? sector;
  final String? industry;
  final double? closePrice;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final int?    volume;
  final double? ma50;
  final double? ma220;
  final double? rsi14;
  final int?    volumeAvg20;
  final double? week52High;
  final double? week52Low;
  final double? momentumScore;
  final String? tradeDate;

  const StockModel({
    this.id,
    required this.symbol,
    required this.name,
    this.exchange,
    this.sector,
    this.industry,
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
    this.tradeDate,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) => StockModel(
    id:            json['id']            as int?,
    symbol:        json['symbol']        as String,
    name:          json['name']          as String,
    exchange:      json['exchange']      as String?,
    sector:        json['sector']        as String?,
    industry:      json['industry']      as String?,
    closePrice:    (json['closePrice']   as num?)?.toDouble(),
    openPrice:     (json['openPrice']    as num?)?.toDouble(),
    highPrice:     (json['highPrice']    as num?)?.toDouble(),
    lowPrice:      (json['lowPrice']     as num?)?.toDouble(),
    volume:        json['volume']        as int?,
    ma50:          (json['ma50']         as num?)?.toDouble(),
    ma220:         (json['ma220']        as num?)?.toDouble(),
    rsi14:         (json['rsi14']        as num?)?.toDouble(),
    volumeAvg20:   json['volumeAvg20']   as int?,
    week52High:    (json['week52High']   as num?)?.toDouble(),
    week52Low:     (json['week52Low']    as num?)?.toDouble(),
    momentumScore: (json['momentumScore'] as num?)?.toDouble(),
    tradeDate:     json['tradeDate']     as String?,
  );

  /// Whether price is above its 220-day moving average
  bool get isAboveMa220 =>
      closePrice != null && ma220 != null && closePrice! > ma220!;

  /// RSI status label
  String get rsiLabel {
    if (rsi14 == null) return 'N/A';
    if (rsi14! < 35)   return 'Oversold';
    if (rsi14! > 70)   return 'Overbought';
    return 'Neutral';
  }
}
