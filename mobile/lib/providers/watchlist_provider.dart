import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/api_client.dart';
import '../data/models/watchlist_model.dart';

final watchlistsProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistModel>>(
        WatchlistNotifier.new);

class WatchlistNotifier extends AsyncNotifier<List<WatchlistModel>> {
  @override
  Future<List<WatchlistModel>> build() => _fetch();

  Future<List<WatchlistModel>> _fetch() async {
    final data = await ref.read(apiClientProvider).getWatchlists();
    return data
        .map((e) => WatchlistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(String name, String? description) async {
    await ref.read(apiClientProvider).createWatchlist(name, description);
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(apiClientProvider).deleteWatchlist(id);
    await refresh();
  }

  Future<void> addStock(int watchlistId, String symbol) async {
    await ref.read(apiClientProvider).addStockToWatchlist(watchlistId, symbol);
    await refresh();
  }

  Future<void> removeStock(int watchlistId, String symbol) async {
    await ref
        .read(apiClientProvider)
        .removeStockFromWatchlist(watchlistId, symbol);
    await refresh();
  }
}
