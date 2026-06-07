class ScreenerResultModel {
  final String  symbol;
  final String  name;
  final String? exchange;
  final String? sector;
  final double? closePrice;
  final double? ma50;
  final double? ma220;
  final double? rsi14;
  final double? momentumScore;
  final String? matchedFilters;

  const ScreenerResultModel({
    required this.symbol,
    required this.name,
    this.exchange,
    this.sector,
    this.closePrice,
    this.ma50,
    this.ma220,
    this.rsi14,
    this.momentumScore,
    this.matchedFilters,
  });

  factory ScreenerResultModel.fromJson(Map<String, dynamic> json) =>
      ScreenerResultModel(
        symbol:         json['symbol']         as String,
        name:           json['name']           as String,
        exchange:       json['exchange']       as String?,
        sector:         json['sector']         as String?,
        closePrice:     (json['closePrice']    as num?)?.toDouble(),
        ma50:           (json['ma50']          as num?)?.toDouble(),
        ma220:          (json['ma220']         as num?)?.toDouble(),
        rsi14:          (json['rsi14']         as num?)?.toDouble(),
        momentumScore:  (json['momentumScore'] as num?)?.toDouble(),
        matchedFilters: json['matchedFilters'] as String?,
      );

  List<String> get filterList =>
      matchedFilters?.split(', ').where((f) => f.isNotEmpty).toList() ?? [];
}
