import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/api_client.dart';
import '../data/models/alert_model.dart';

final alertsProvider =
    AsyncNotifierProvider<AlertNotifier, List<AlertModel>>(AlertNotifier.new);

class AlertNotifier extends AsyncNotifier<List<AlertModel>> {
  @override
  Future<List<AlertModel>> build() => _fetch();

  Future<List<AlertModel>> _fetch() async {
    final data = await ref.read(apiClientProvider).getAlerts();
    return data
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(
      String symbol, String alertType, double? threshold) async {
    await ref
        .read(apiClientProvider)
        .createAlert(symbol, alertType, threshold);
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(apiClientProvider).deleteAlert(id);
    await refresh();
  }
}
