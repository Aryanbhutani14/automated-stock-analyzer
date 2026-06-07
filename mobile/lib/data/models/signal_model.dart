class SignalModel {
  final int?    id;
  final String  symbol;
  final String  stockName;
  final String  signalDate;
  final String  signalType;  // BUY | SELL | HOLD
  final String? strategy;
  final double? triggerPrice;
  final String? notes;

  const SignalModel({
    this.id,
    required this.symbol,
    required this.stockName,
    required this.signalDate,
    required this.signalType,
    this.strategy,
    this.triggerPrice,
    this.notes,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) => SignalModel(
    id:           json['id']           as int?,
    symbol:       (json['stock'] as Map<String, dynamic>?)?['symbol'] as String? ?? '',
    stockName:    (json['stock'] as Map<String, dynamic>?)?['name']   as String? ?? '',
    signalDate:   json['signalDate']   as String,
    signalType:   json['signalType']   as String,
    strategy:     json['strategy']     as String?,
    triggerPrice: (json['triggerPrice'] as num?)?.toDouble(),
    notes:        json['notes']        as String?,
  );

  bool get isBuy  => signalType == 'BUY';
  bool get isSell => signalType == 'SELL';
}
