import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/watchlist_provider.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(watchlistsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlists'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreate(context, ref))]),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.bearish))),
        data: (lists) {
          if (lists.isEmpty) return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📋', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('No watchlists yet', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreate(context, ref),
                icon: const Icon(Icons.add), label: const Text('Create Watchlist'),
              ),
            ]),
          );
          return RefreshIndicator(
            onRefresh: () => ref.read(watchlistsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lists.length,
              itemBuilder: (ctx, i) {
                final wl = lists[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ListTile(
                      title: Text(wl.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: wl.description != null ? Text(wl.description!, style: const TextStyle(fontSize: 12)) : null,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${wl.symbols.length} stocks', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textSecondary),
                          onPressed: () => _confirmDelete(context, ref, wl.id, wl.name),
                        ),
                      ]),
                    ),
                    if (wl.symbols.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(spacing: 8, runSpacing: 6,
                          children: wl.symbols.map((sym) => _StockChip(sym, wl.id, ref)).toList()),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _AddSymbolField(watchlistId: wl.id),
                    ),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Create Watchlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(watchlistsProvider.notifier).create(nameCtrl.text.trim(), descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
            },
            child: const Text('Create'),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Watchlist'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async { Navigator.pop(ctx); await ref.read(watchlistsProvider.notifier).delete(id); },
                     child: const Text('Delete', style: TextStyle(color: AppTheme.bearish))),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final String symbol;
  final int watchlistId;
  final WidgetRef ref;
  const _StockChip(this.symbol, this.watchlistId, this.ref);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/stocks/$symbol'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(symbol, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => ref.read(watchlistsProvider.notifier).removeStock(watchlistId, symbol),
          child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
        ),
      ]),
    ),
  );
}

class _AddSymbolField extends ConsumerStatefulWidget {
  final int watchlistId;
  const _AddSymbolField({required this.watchlistId});
  @override
  ConsumerState<_AddSymbolField> createState() => _AddSymbolFieldState();
}

class _AddSymbolFieldState extends ConsumerState<_AddSymbolField> {
  final _ctrl = TextEditingController();
  String? _error;

  Future<void> _add() async {
    final sym = _ctrl.text.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() => _error = null);
    try {
      await ref.read(watchlistsProvider.notifier).addStock(widget.watchlistId, sym);
      _ctrl.clear();
    } catch (_) {
      setState(() => _error = 'Could not add $sym');
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(
        child: TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Add symbol (e.g. TCS)',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            errorText: _error,
          ),
          onSubmitted: (_) => _add(),
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: _add,
        style: ElevatedButton.styleFrom(minimumSize: const Size(60, 42), padding: EdgeInsets.zero),
        child: const Text('+ Add'),
      ),
    ]),
  ]);
}
