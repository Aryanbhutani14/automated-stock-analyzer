class TradeRecord {
  final String? entryDate;
  final String? exitDate;
  final double? entryPrice;
  final double? exitPrice;
  final double? returnPct;

  const TradeRecord({
    this.entryDate,
    this.exitDate,
    this.entryPrice,
    this.exitPrice,
    this.returnPct,
  });

  factory TradeRecord.fromJson(Map<String, dynamic> json) => TradeRecord(
    entryDate:  json['entryDate']  as String?,
    exitDate:   json['exitDate']   as String?,
    entryPrice: (json['entryPrice'] as num?)?.toDouble(),
    exitPrice:  (json['exitPrice']  as num?)?.toDouble(),
    returnPct:  (json['returnPct']  as num?)?.toDouble(),
  );

  bool get isWin => (returnPct ?? 0) > 0;
}

class BacktestResultModel {
  final String? symbol;
  final String? strategy;
  final String? startDate;
  final String? endDate;
  final double? totalReturnPct;
  final double? winRatePct;
  final int?    totalTrades;
  final double? maxDrawdownPct;
  final List<TradeRecord> trades;
  final String? message;

  const BacktestResultModel({
    this.symbol,
    this.strategy,
    this.startDate,
    this.endDate,
    this.totalReturnPct,
    this.winRatePct,
    this.totalTrades,
    this.maxDrawdownPct,
    this.trades = const [],
    this.message,
  });

  factory BacktestResultModel.fromJson(Map<String, dynamic> json) =>
      BacktestResultModel(
        symbol:         json['symbol']         as String?,
        strategy:       json['strategy']       as String?,
        startDate:      json['startDate']      as String?,
        endDate:        json['endDate']        as String?,
        totalReturnPct: (json['totalReturnPct'] as num?)?.toDouble(),
        winRatePct:     (json['winRatePct']     as num?)?.toDouble(),
        totalTrades:    json['totalTrades']    as int?,
        maxDrawdownPct: (json['maxDrawdownPct'] as num?)?.toDouble(),
        trades: (json['trades'] as List<dynamic>?)
                  ?.map((t) => TradeRecord.fromJson(t as Map<String, dynamic>))
                  .toList() ?? [],
        message: json['message'] as String?,
      );
}
