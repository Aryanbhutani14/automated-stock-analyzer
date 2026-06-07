class AlertModel {
  final int     id;
  final String  symbol;
  final String  stockName;
  final String  alertType;
  final double? threshold;
  final bool    active;
  final String? lastTriggered;
  final String? createdAt;

  const AlertModel({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.alertType,
    this.threshold,
    required this.active,
    this.lastTriggered,
    this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id:            json['id']            as int,
    symbol:        json['symbol']        as String,
    stockName:     json['stockName']     as String,
    alertType:     json['alertType']     as String,
    threshold:     (json['threshold']    as num?)?.toDouble(),
    active:        json['active']        as bool,
    lastTriggered: json['lastTriggered'] as String?,
    createdAt:     json['createdAt']     as String?,
  );

  String get displayType => alertType.replaceAll('_', ' ');
}
