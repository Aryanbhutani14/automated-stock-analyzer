import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/stock_model.dart';

class StockProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  
  static final String _host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  final String _baseUrl = 'http://$_host:8080/api/stocks';

  List<StockModel> _stocks = [];
  List<ScreenerResultModel> _screenerResults = [];
  List<SignalModel> _signals = [];
  List<String> _sectors = [];
  List<WatchlistModel> _watchlists = [];
  List<AlertModel> _alerts = [];
  List<BacktestResultModel> _backtestHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StockModel> get stocks => _stocks;
  List<ScreenerResultModel> get screenerResults => _screenerResults;
  List<SignalModel> get signals => _signals;
  List<String> get sectors => _sectors;
  List<WatchlistModel> get watchlists => _watchlists;
  List<AlertModel> get alerts => _alerts;
  List<BacktestResultModel> get backtestHistory => _backtestHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  Future<void> fetchStocks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        _baseUrl,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _stocks = data.map((json) => StockModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load stocks';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load stocks from server';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while fetching stocks';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StockDetailModel?> fetchStockDetail(String symbol) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '$_baseUrl/$symbol',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return StockDetailModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('Error fetching stock detail for $symbol: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching stock detail for $symbol: $e');
    }
    return null;
  }

  Future<void> fetchScreenerResults(String filter, {String? exchange, String? sector}) async {
    _isLoading = true;
    _errorMessage = null;
    _screenerResults = [];
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, dynamic>{'filter': filter};
      if (exchange != null && exchange.isNotEmpty) {
        queryParams['exchange'] = exchange;
      }
      if (sector != null && sector.isNotEmpty) {
        queryParams['sector'] = sector;
      }

      final response = await _dio.get(
        'http://$_host:8080/api/screener',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _screenerResults = data.map((json) => ScreenerResultModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load screener results';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to query screener';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while running screener';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSignals({String? type, String? date}) async {
    _isLoading = true;
    _errorMessage = null;
    _signals = [];
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        'http://$_host:8080/api/signals',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _signals = data.map((json) => SignalModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load signals feed';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load signals';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while loading signals';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<SignalModel>> fetchStockSignals(String symbol) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        'http://$_host:8080/api/signals/$symbol',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SignalModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      debugPrint('Error fetching signals for $symbol: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching signals for $symbol: $e');
    }
    return [];
  }

  Future<void> fetchSectors() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '$_baseUrl/sectors',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _sectors = data.map((e) => e.toString()).toList();
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('Error fetching active sectors: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching sectors: $e');
    }
  }

  Future<bool> triggerSync() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        '$_baseUrl/sync',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Error triggering sync: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error triggering sync: $e');
    }
    return false;
  }

  // Watchlists API
  Future<void> fetchWatchlists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        'http://$_host:8080/api/watchlists',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _watchlists = data.map((json) => WatchlistModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load watchlists';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load watchlists';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while fetching watchlists';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WatchlistModel?> createWatchlist(String name, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        'http://$_host:8080/api/watchlists',
        data: {'name': name, 'description': description},
        options: Options(headers: headers),
      );

      if (response.statusCode == 201) {
        final watchlist = WatchlistModel.fromJson(response.data);
        _watchlists.insert(0, watchlist);
        return watchlist;
      }
    } on DioException catch (e) {
      debugPrint('Error creating watchlist: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> deleteWatchlist(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        'http://$_host:8080/api/watchlists/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        _watchlists.removeWhere((w) => w.id == id);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Error deleting watchlist: ${e.message}');
    }
    return false;
  }

  Future<WatchlistModel?> addStockToWatchlist(int watchlistId, String symbol) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        'http://$_host:8080/api/watchlists/$watchlistId/stocks',
        data: {'symbol': symbol},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updated = WatchlistModel.fromJson(response.data);
        final index = _watchlists.indexWhere((w) => w.id == watchlistId);
        if (index != -1) {
          _watchlists[index] = updated;
          notifyListeners();
        }
        return updated;
      }
    } on DioException catch (e) {
      debugPrint('Error adding stock to watchlist: ${e.message}');
    }
    return null;
  }

  Future<WatchlistModel?> removeStockFromWatchlist(int watchlistId, String symbol) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        'http://$_host:8080/api/watchlists/$watchlistId/stocks/$symbol',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final updated = WatchlistModel.fromJson(response.data);
        final index = _watchlists.indexWhere((w) => w.id == watchlistId);
        if (index != -1) {
          _watchlists[index] = updated;
          notifyListeners();
        }
        return updated;
      }
    } on DioException catch (e) {
      debugPrint('Error removing stock from watchlist: ${e.message}');
    }
    return null;
  }

  // Alerts API
  Future<void> fetchAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        'http://$_host:8080/api/alerts',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _alerts = data.map((json) => AlertModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load alerts';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load alerts';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while fetching alerts';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AlertModel?> createAlert(String symbol, String alertType, double? threshold) async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        'http://$_host:8080/api/alerts',
        data: {'symbol': symbol, 'alertType': alertType, 'threshold': threshold},
        options: Options(headers: headers),
      );

      if (response.statusCode == 201) {
        final alert = AlertModel.fromJson(response.data);
        _alerts.add(alert);
        return alert;
      }
    } on DioException catch (e) {
      debugPrint('Error creating alert: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> deleteAlert(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        'http://$_host:8080/api/alerts/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        _alerts.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Error deleting alert: ${e.message}');
    }
    return false;
  }

  // AI Summary API
  Future<AiSummaryModel?> fetchAiSummary(String symbol) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        'http://$_host:8080/api/ai/summary/$symbol',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return AiSummaryModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('Error fetching AI summary for $symbol: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching AI summary for $symbol: $e');
    }
    return null;
  }

  // Backtester API
  Future<BacktestResultModel?> runBacktest(String strategyName, String symbol, String startDate, String endDate, double capital) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        'http://$_host:8080/api/backtest',
        data: {
          'strategyName': strategyName,
          'symbol': symbol,
          'startDate': startDate,
          'endDate': endDate,
          'initialCapital': capital,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return BacktestResultModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to execute backtest';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while running backtest';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> fetchBacktestHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        'http://$_host:8080/api/backtest/history',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _backtestHistory = data.map((json) => BacktestResultModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to load backtest history';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Failed to load backtest history';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred while loading backtest history';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

