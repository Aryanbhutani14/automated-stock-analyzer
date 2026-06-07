import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/api_client.dart';
import '../data/models/stock_model.dart';
import '../data/models/signal_model.dart';
import '../data/models/screener_result_model.dart';

// ── All active stocks ────────────────────────────────────────────────
final allStocksProvider = FutureProvider<List<StockModel>>((ref) async {
  final data = await ref.read(apiClientProvider).getAllStocks();
  return data.map((e) => StockModel.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Single stock detail ──────────────────────────────────────────────
final stockDetailProvider =
    FutureProvider.family<StockModel, String>((ref, symbol) async {
  final data = await ref.read(apiClientProvider).getStock(symbol);
  return StockModel.fromJson(data);
});

// ── Price history ────────────────────────────────────────────────────
final priceHistoryProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    ({String symbol, String from, String to})>((ref, params) async {
  final data = await ref
      .read(apiClientProvider)
      .getPriceHistory(params.symbol, params.from, params.to);
  return data.cast<Map<String, dynamic>>();
});

// ── Today's signals ──────────────────────────────────────────────────
final todaySignalsProvider = FutureProvider<List<SignalModel>>((ref) async {
  final today = DateTime.now().toIso8601String().split('T')[0];
  final data  = await ref.read(apiClientProvider).getSignalsByDate(today);
  return data
      .map((e) => SignalModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Signals for a stock ──────────────────────────────────────────────
final stockSignalsProvider =
    FutureProvider.family<List<SignalModel>, String>((ref, symbol) async {
  final data = await ref.read(apiClientProvider).getSignalsBySymbol(symbol);
  return data
      .map((e) => SignalModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Sectors list ─────────────────────────────────────────────────────
final sectorsProvider = FutureProvider<List<String>>((ref) async {
  final data = await ref.read(apiClientProvider).getSectors();
  return data.cast<String>();
});

// ── Screener ─────────────────────────────────────────────────────────
final screenerFilterProvider = StateProvider<String>((ref) => 'ALL');
final screenerExchangeProvider = StateProvider<String>((ref) => '');
final screenerSectorProvider   = StateProvider<String>((ref) => '');

final screenerResultsProvider =
    FutureProvider<List<ScreenerResultModel>>((ref) async {
  final filter   = ref.watch(screenerFilterProvider);
  final exchange = ref.watch(screenerExchangeProvider);
  final sector   = ref.watch(screenerSectorProvider);

  final data = await ref.read(apiClientProvider).screen(
    filter:   filter,
    exchange: exchange.isEmpty ? null : exchange,
    sector:   sector.isEmpty   ? null : sector,
  );
  return data
      .map((e) => ScreenerResultModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
