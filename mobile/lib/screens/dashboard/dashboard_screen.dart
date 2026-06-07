import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/signal_model.dart';
import '../widgets/stat_card.dart';
import '../widgets/signal_badge.dart';
import '../widgets/loading_shimmer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(authStateProvider).value;
    final stocksAsync = ref.watch(allStocksProvider);
    final signalsAsync = ref.watch(todaySignalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good ${_greeting()}, ${user?.username ?? ''}'),
          Text(DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
               style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.normal)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allStocksProvider);
          ref.invalidate(todaySignalsProvider);
        },
        child: stocksAsync.when(
          loading: () => const LoadingShimmer(),
          error:   (e, _) => _ErrorView(e.toString()),
          data:    (stocks) => _Body(stocks: stocks, signalsAsync: signalsAsync),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _Body extends StatefulWidget {
  final List<StockModel> stocks;
  final AsyncValue<List<SignalModel>> signalsAsync;
  const _Body({required this.stocks, required this.signalsAsync});
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final signals  = widget.signalsAsync.value ?? [];
    final buyCount  = signals.where((s) => s.isBuy).length;
    final sellCount = signals.where((s) => s.isSell).length;
    final fmt       = NumberFormat('#,##,##0.00', 'en_IN');

    final filtered = widget.stocks.where((s) =>
      s.symbol.toLowerCase().contains(_search.toLowerCase()) ||
      s.name.toLowerCase().contains(_search.toLowerCase())).toList();

    return CustomScrollView(
      slivers: [
        // ── Stat cards ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            delegate: SliverChildListDelegate([
              StatCard(label: 'Stocks',        value: '${widget.stocks.length}', sub: 'tracked'),
              StatCard(label: 'Signals Today', value: '${signals.length}',       sub: 'total'),
              StatCard(label: 'BUY',           value: '$buyCount',  color: AppTheme.bullish),
              StatCard(label: 'SELL',          value: '$sellCount', color: AppTheme.bearish),
            ]),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2),
          ),
        ),

        // ── Today's signals ─────────────────────────────────────────
        if (signals.isNotEmpty) ...[
          _SectionHeader('Today\'s Signals'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final sig = signals[i];
                  return _SignalTile(sig, fmt);
                },
                childCount: signals.length > 5 ? 5 : signals.length,
              ),
            ),
          ),
        ],

        // ── Search bar ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          sliver: SliverToBoxAdapter(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search stocks…',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () => setState(() => _search = ''))
                    : null,
              ),
            ),
          ),
        ),

        // ── Stocks list ─────────────────────────────────────────────
        _SectionHeader('All Stocks (${filtered.length})'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _StockTile(filtered[i], fmt),
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalTile extends StatelessWidget {
  final SignalModel sig;
  final NumberFormat fmt;
  const _SignalTile(this.sig, this.fmt);
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(children: [
        Text(sig.symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(width: 8),
        SignalBadge(sig.signalType),
      ]),
      subtitle: Text(sig.strategy ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: sig.triggerPrice != null
          ? Text('₹${fmt.format(sig.triggerPrice)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))
          : null,
      onTap: () => context.push('/stocks/${sig.symbol}'),
    ),
  );
}

class _StockTile extends StatelessWidget {
  final StockModel s;
  final NumberFormat fmt;
  const _StockTile(this.s, this.fmt);
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(children: [
        Text(s.symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(width: 8),
        Flexible(child: Text(s.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis, maxLines: 1)),
      ]),
      subtitle: s.sector != null ? Text(s.sector!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)) : null,
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (s.closePrice != null)
          Text('₹${fmt.format(s.closePrice)}',
               style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        if (s.rsi14 != null)
          Text('RSI ${s.rsi14!.toStringAsFixed(1)}',
               style: TextStyle(fontSize: 11,
                 color: s.rsi14! < 35 ? AppTheme.bullish : s.rsi14! > 70 ? AppTheme.bearish : AppTheme.textSecondary)),
      ]),
      onTap: () => context.push('/stocks/${s.symbol}'),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    sliver: SliverToBoxAdapter(
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView(this.message);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.bearish, size: 48),
        const SizedBox(height: 12),
        Text('Failed to load data', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
      ]),
    ),
  );
}
