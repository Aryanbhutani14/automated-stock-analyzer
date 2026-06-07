import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/stock_provider.dart';
import '../widgets/loading_shimmer.dart';

const _filters = [
  'ALL', 'MA220_CROSSOVER', 'MA50_CROSSOVER',
  'WEEK_52_HIGH', 'VOLUME_BREAKOUT', 'RSI_OVERSOLD', 'RSI_OVERBOUGHT', 'MOMENTUM',
];

class ScreenerScreen extends ConsumerWidget {
  const ScreenerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter   = ref.watch(screenerFilterProvider);
    final exchange = ref.watch(screenerExchangeProvider);
    final results  = ref.watch(screenerResultsProvider);
    final sectors  = ref.watch(sectorsProvider);
    final fmt      = NumberFormat('#,##,##0.00', 'en_IN');

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Screener')),
      body: Column(children: [
        // ── Filter strip ─────────────────────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(children: [
            // Filter chips
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: _filters.map((f) {
                final label = f == 'ALL' ? 'All' : f.replaceAll('_', ' ');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: filter == f,
                    onSelected: (_) => ref.read(screenerFilterProvider.notifier).state = f,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceAlt,
                    labelStyle: TextStyle(color: filter == f ? Colors.white : AppTheme.textSecondary),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide.none,
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 10),
            // Exchange + Sector row
            Row(children: [
              Expanded(
                child: _DropdownField(
                  value: exchange.isEmpty ? null : exchange,
                  hint: 'Exchange',
                  items: const ['NSE', 'BSE'],
                  onChanged: (v) => ref.read(screenerExchangeProvider.notifier).state = v ?? '',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: sectors.when(
                  data: (list) => _DropdownField(
                    value: ref.watch(screenerSectorProvider).isEmpty ? null : ref.watch(screenerSectorProvider),
                    hint: 'Sector',
                    items: list,
                    onChanged: (v) => ref.read(screenerSectorProvider.notifier).state = v ?? '',
                  ),
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                ),
              ),
            ]),
          ]),
        ),

        // ── Results ──────────────────────────────────────────────────
        Expanded(
          child: results.when(
            loading: () => const LoadingShimmer(),
            error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.bearish))),
            data:    (list) {
              if (list.isEmpty) return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔍', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No stocks matched this filter', style: TextStyle(color: AppTheme.textSecondary)),
                ]),
              );
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final r = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/stocks/${r.symbol}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(r.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                            const SizedBox(width: 8),
                            if (r.exchange != null)
                              _Chip(r.exchange!, AppTheme.surfaceAlt),
                            const Spacer(),
                            if (r.closePrice != null)
                              Text('₹${fmt.format(r.closePrice)}',
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ]),
                          const SizedBox(height: 4),
                          Text(r.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                               overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: r.filterList.map((f) =>
                            _Chip(f.replaceAll('_', ' '), AppTheme.primary.withOpacity(0.2),
                                  textColor: AppTheme.primary)).toList()),
                          const Divider(height: 16),
                          Row(children: [
                            _IndStat('MA50',  r.ma50  != null ? '₹${r.ma50!.toStringAsFixed(0)}' : '—'),
                            _IndStat('MA220', r.ma220 != null ? '₹${r.ma220!.toStringAsFixed(0)}' : '—'),
                            _IndStat('RSI',   r.rsi14 != null ? r.rsi14!.toStringAsFixed(1) : '—',
                              color: r.rsi14 != null
                                ? (r.rsi14! < 35 ? AppTheme.bullish : r.rsi14! > 70 ? AppTheme.bearish : null)
                                : null),
                            _IndStat('Mom',   r.momentumScore != null ? '${r.momentumScore!.toStringAsFixed(1)}%' : '—',
                              color: r.momentumScore != null
                                ? (r.momentumScore! >= 0 ? AppTheme.bullish : AppTheme.bearish)
                                : null),
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final void Function(String?) onChanged;
  const _DropdownField({this.value, required this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    ),
    items: [DropdownMenuItem(value: null, child: Text(hint, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))],
    onChanged: onChanged,
    dropdownColor: AppTheme.surface,
  );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color? textColor;
  const _Chip(this.text, this.bg, {this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 11, color: textColor ?? AppTheme.textSecondary)),
  );
}

class _IndStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _IndStat(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? AppTheme.textPrimary)),
    ]),
  );
}
