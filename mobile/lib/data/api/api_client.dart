import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers:        {'Content-Type': 'application/json'},
    ));

    // Attach JWT token to every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ── Auth ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<void> register(String username, String email, String password) async {
    await _dio.post('/auth/register',
        data: {'username': username, 'email': email, 'password': password});
  }

  // ── Stocks ──────────────────────────────────────────────────────────
  Future<List<dynamic>> getAllStocks() async {
    final res = await _dio.get('/stocks');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getStock(String symbol) async {
    final res = await _dio.get('/stocks/$symbol');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPriceHistory(
      String symbol, String from, String to) async {
    final res = await _dio.get('/stocks/$symbol/price-history',
        queryParameters: {'from': from, 'to': to});
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getSectors() async {
    final res = await _dio.get('/stocks/sectors');
    return res.data as List<dynamic>;
  }

  // ── Screener ────────────────────────────────────────────────────────
  Future<List<dynamic>> screen(
      {String filter = 'ALL', String? exchange, String? sector}) async {
    final res = await _dio.get('/screener', queryParameters: {
      'filter': filter,
      if (exchange != null && exchange.isNotEmpty) 'exchange': exchange,
      if (sector   != null && sector.isNotEmpty)   'sector':   sector,
    });
    return res.data as List<dynamic>;
  }

  // ── Signals ─────────────────────────────────────────────────────────
  Future<List<dynamic>> getSignalsByDate(String date, {String? type}) async {
    final res = await _dio.get('/signals', queryParameters: {
      'date': date,
      if (type != null) 'type': type,
    });
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getSignalsBySymbol(String symbol) async {
    final res = await _dio.get('/signals/$symbol');
    return res.data as List<dynamic>;
  }

  // ── Watchlists ──────────────────────────────────────────────────────
  Future<List<dynamic>> getWatchlists() async {
    final res = await _dio.get('/watchlists');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createWatchlist(
      String name, String? description) async {
    final res = await _dio.post('/watchlists',
        data: {'name': name, 'description': description});
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteWatchlist(int id) async =>
      _dio.delete('/watchlists/$id');

  Future<Map<String, dynamic>> addStockToWatchlist(
      int id, String symbol) async {
    final res = await _dio.post('/watchlists/$id/stocks',
        data: {'symbol': symbol});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeStockFromWatchlist(
      int id, String symbol) async {
    final res = await _dio.delete('/watchlists/$id/stocks/$symbol');
    return res.data as Map<String, dynamic>;
  }

  // ── Alerts ──────────────────────────────────────────────────────────
  Future<List<dynamic>> getAlerts() async {
    final res = await _dio.get('/alerts');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAlert(
      String symbol, String alertType, double? threshold) async {
    final res = await _dio.post('/alerts', data: {
      'symbol':    symbol,
      'alertType': alertType,
      if (threshold != null) 'threshold': threshold,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteAlert(int id) async => _dio.delete('/alerts/$id');

  // ── AI Summary ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAiSummary(String symbol) async {
    final res = await _dio.get('/ai/summary/$symbol');
    return res.data as Map<String, dynamic>;
  }

  // ── Backtest ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> runBacktest(Map<String, dynamic> body) async {
    final res = await _dio.post('/backtest', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getBacktestHistory() async {
    final res = await _dio.get('/backtest/history');
    return res.data as List<dynamic>;
  }
}
