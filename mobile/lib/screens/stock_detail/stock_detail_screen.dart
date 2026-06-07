import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/api/api_client.dart';
import '../../providers/stock_provider.dart';
import '../widgets/signal_badge.dart';
import '../widgets/stat_card.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});
  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  int    _rangeDays = 90;
  String? _aiSummary;
  bool   _aiLoading = false;

  static const _ranges = [(label: '1M', days: 30), (label: '3M', days: 90),
                           (label: '6M', days: 180),(label: '1Y', days: 365)];

  String _daysAgo(int n) {
    final d = DateTime.now().subtract(Duration(days: n));
    return DateFormat('yyyy-MM-dd').format(d);
  }

  Future<void> _loadAi() async {
    setState(() => _aiLoading = true);
    try {
      final res = await ref.read(apiClientProvider).getAiSummary(widget.symbol);
      setState(() => _aiSummary = res['summary'] as String?);
    } catch (_) {
      setState(() => _aiSummary = 'AI summary unavailable — check your OpenAI API key.');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync   = ref.watch(stockDetailProvider(widget.symbol));
    final signalsAsync = ref.watch(stockSignalsProvider(widget.symbol));
    final today        = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final historyAsync = ref.watch(priceHistoryProvider(
        (symbol: widget.symbol, from: _daysAgo(_rangeDays), to: today)));
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Scaffold(
      appBar: AppBar(title: Text(widget.symbol)),
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (stock) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(stockDetailProvider(widget.symbol));
            ref.invalidate(stockSignalsProvider(widget.symbol));
          },
          child: ListView(padding: const EdgeInsets.all(16), children: [

            // ── Price header ─────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stock.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  if (stock.exchange != null) _SmallChip(stock.exchange!),
                  if (stock.sector   != null) ...[const SizedBox(width: 6), _SmallChip(stock.sector!)],
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(stock.closePrice != null ? '₹${fmt.format(stock.closePrice)}' : '—',
                     style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                if (stock.ma220 != null && stock.closePrice != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(stock.isAboveMa220 ? Icons.arrow_upward : Icons.arrow_downward,
                         size: 14, color: stock.isAboveMa220 ? AppTheme.bullish : AppTheme.bearish),
                    Text(stock.isAboveMa220 ? 'Above 220-DMA' : 'Below 220-DMA',
                         style: TextStyle(fontSize: 12,
                             color: stock.isAboveMa220 ? AppTheme.bullish : AppTheme.bearish)),
                  ]),
              ]),
            ]),
            const SizedBox(height: 16),

            // ── Indicator cards ───────────────────────────────────────
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4,
              children: [
                StatCard(label: 'MA-50',  value: stock.ma50  != null ? '₹${stock.ma50!.toStringAsFixed(1)}'  : '—'),
                StatCard(label: 'MA-220', value: stock.ma220 != null ? '₹${stock.ma220!.toStringAsFixed(1)}' : '—'),
                StatCard(label: 'RSI 14', value: stock.rsi14 != null ? stock.rsi14!.toStringAsFixed(1) : '—',
                  color: stock.rsi14 != null
                    ? (stock.rsi14! < 35 ? AppTheme.bullish : stock.rsi14! > 70 ? AppTheme.bearish : null)
                    : null),
                StatCard(label: '12M Momentum',
                  value: stock.momentumScore != null ? '${stock.momentumScore!.toStringAsFixed(1)}%' : '—',
                  color: stock.momentumScore != null
                    ? (stock.momentumScore! >= 0 ? AppTheme.bullish : AppTheme.bearish)
                    : null),
              ],
            ),
            const SizedBox(height: 20),

            // ── Price chart ───────────────────────────────────────────
            _SectionTitle('Price History'),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end,
                children: _ranges.map((r) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(r.label, style: const TextStyle(fontSize: 12)),
                    selected: _rangeDays == r.days,
                    onSelected: (_) => setState(() => _rangeDays = r.days),
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceAlt,
                    labelStyle: TextStyle(color: _rangeDays == r.days ? Colors.white : AppTheme.textSecondary),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )).toList()),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:   (_, __) => const Center(child: Text('Chart unavailable', style: TextStyle(color: AppTheme.textSecondary))),
                data:    (history) {
                  if (history.isEmpty) return const Center(child: Text('No price data', style: TextStyle(color: AppTheme.textSecondary)));
                  final spots = history.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), (e.value['closePrice'] as num).toDouble())).toList();
                  final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
                  final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                  return LineChart(LineChartData(
                    minY: minY * 0.98, maxY: maxY * 1.02,
                    gridData:      FlGridData(show: true, drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 0.5)),
                    titlesData:    FlTitlesData(
                      leftTitles:  AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 56,
                                    getTitlesWidget: (v, _) => Text('₹${v.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData:   FlBorderData(show: false),
                    lineBarsData: [LineChartBarData(
                      spots: spots, isCurved: true, color: AppTheme.primary,
                      strokeWidth: 2, dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true,
                          gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.3), Colors.transparent],
                                                   begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    )],
                    lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppTheme.surface,
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                          '₹${fmt.format(s.y)}', const TextStyle(color: AppTheme.textPrimary, fontSize: 12))).toList(),
                    )),
                  ));
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── AI Summary ────────────────────────────────────────────
            _SectionTitle('🤖 AI Analysis'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _aiSummary != null
                  ? Text(_aiSummary!, style: const TextStyle(color: AppTheme.textPrimary, height: 1.6))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Generate an AI-powered analysis for this stock.',
                                 style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _aiLoading ? null : _loadAi,
                          icon: _aiLoading ? const SizedBox(height: 16, width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                          label: Text(_aiLoading ? 'Generating…' : 'Generate Summary'),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFA855F7)),
                        ),
                      ),
                    ]),
              ),
            ),
            const SizedBox(height: 24),

            // ── Signals ───────────────────────────────────────────────
            _SectionTitle('Recent Signals'),
            const SizedBox(height: 10),
            signalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (_, __) => const SizedBox.shrink(),
              data: (sigs) {
                if (sigs.isEmpty) return const Text('No signals recorded yet.',
                    style: TextStyle(color: AppTheme.textSecondary));
                return Column(children: sigs.take(8).map((sig) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Row(children: [
                      SignalBadge(sig.signalType), const SizedBox(width: 8),
                      Text(sig.strategy ?? '', style: const TextStyle(fontSize: 13)),
                    ]),
                    subtitle: sig.notes != null ? Text(sig.notes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)) : null,
                    trailing: Text(sig.signalDate, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                )).toList());
              },
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
}

class _SmallChip extends StatelessWidget {
  final String text;
  const _SmallChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
  );
}
