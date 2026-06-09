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
  bool _isLoading = false;
  String? _errorMessage;

  List<StockModel> get stocks => _stocks;
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
}
