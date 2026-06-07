class WatchlistModel {
  final int    id;
  final String name;
  final String? description;
  final List<String> symbols;
  final String? createdAt;

  const WatchlistModel({
    required this.id,
    required this.name,
    this.description,
    required this.symbols,
    this.createdAt,
  });

  factory WatchlistModel.fromJson(Map<String, dynamic> json) => WatchlistModel(
    id:          json['id']          as int,
    name:        json['name']        as String,
    description: json['description'] as String?,
    symbols:     (json['symbols'] as List<dynamic>?)
                   ?.map((e) => e as String)
                   .toList() ?? [],
    createdAt:   json['createdAt']   as String?,
  );
}
