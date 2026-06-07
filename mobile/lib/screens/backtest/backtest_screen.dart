import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../data/api/api_client.dart';
import '../../data/models/backtest_model.dart';
import '../widgets/stat_card.dart';

const _strategies = [
  '', 'MA220_CROSSOVER', 'MA50_CROSSOVER',
  'RSI_OVERSOLD', 'RSI_OVERBOUGHT',
  'WEEK_52_HIGH', 'VOLUME_BREAKOUT', 'MOMENTUM',
];

class BacktestScreen extends ConsumerStatefulWidget {
  const BacktestScreen({super.key});
  @override
  ConsumerState<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends ConsumerState<BacktestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Form state
  final _symbolCtrl  = TextEditingController();
  final _capitalCtrl = TextEditingController(text: '100000');
  String _strategy   = '';
  DateTime _startDate = DateTime(2023, 1, 1);
  DateTime _endDate   = DateTime.now();

  // Result state
  BacktestResultModel? _result;
  List<BacktestResultModel> _history = [];
  bool   _running  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _symbolCtrl.dispose();
    _capitalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ref.read(apiClientProvider).getBacktestHistory();
      setState(() {
        _history = data
            .map((e) => BacktestResultModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _run() async {
    final sym = _symbolCtrl.text.trim().toUpperCase();
    if (sym.isEmpty) {
      setState(() => _error = 'Symbol is required');
      return;
    }
    setState(() { _running = true; _error = null; _result = null; });
    try {
      final data = await ref.read(apiClientProvider).runBacktest({
        'symbol':         sym,
        'strategy':       _strategy.isEmpty ? null : _strategy,
        'startDate':      _startDate.toIso8601String().split('T')[0],
        'endDate':        _endDate.toIso8601String().split('T')[0],
        'initialCapital': double.tryParse(_capitalCtrl.text) ?? 100000,
      });
      setState(() => _result = BacktestResultModel.fromJson(data));
      await _loadHistory();
    } catch (e) {
      setState(() => _error = 'Backtest failed: ${e.toString()}');
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary, surface: AppTheme.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Backtester'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [Tab(text: '▶  Run'), Tab(text: '📋  History')],
        indicatorColor: AppTheme.primary,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
      ),
    ),
    body: TabBarView(controller: _tabs, children: [
      _RunTab(
        symbolCtrl: _symbolCtrl, capitalCtrl: _capitalCtrl,
        strategy: _strategy, startDate: _startDate, endDate: _endDate,
        running: _running, error: _error, result: _result,
        onStrategyChange: (v) => setState(() => _strategy = v ?? ''),
        onPickStart:  () => _pickDate(true),
        onPickEnd:    () => _pickDate(false),
        onRun:        _run,
      ),
      _HistoryTab(history: _history),
    ]),
  );
}

// ── Run tab ──────────────────────────────────────────────────────────────────
class _RunTab extends StatelessWidget {
  final TextEditingController symbolCtrl, capitalCtrl;
  final String strategy;
  final DateTime startDate, endDate;
  final bool running;
  final String? error;
  final BacktestResultModel? result;
  final void Function(String?) onStrategyChange;
  final VoidCallback onPickStart, onPickEnd, onRun;

  const _RunTab({
    required this.symbolCtrl, required this.capitalCtrl,
    required this.strategy, required this.startDate, required this.endDate,
    required this.running, required this.error, required this.result,
    required this.onStrategyChange,
    required this.onPickStart, required this.onPickEnd, required this.onRun,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // ── Form card ───────────────────────────────────────────────
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: symbolCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Stock Symbol *', hintText: 'e.g. RELIANCE'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: strategy.isEmpty ? null : strategy,
            decoration: const InputDecoration(labelText: 'Strategy'),
            dropdownColor: AppTheme.surface,
            hint: const Text('All Strategies', style: TextStyle(color: AppTheme.textSecondary)),
            items: _strategies.map((s) => DropdownMenuItem(
              value: s.isEmpty ? null : s,
              child: Text(s.isEmpty ? 'All Strategies' : s.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: onStrategyChange,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: capitalCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Initial Capital (₹)'),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _DateButton(
              label: 'Start', date: startDate, onTap: onPickStart)),
            const SizedBox(width: 10),
            Expanded(child: _DateButton(
              label: 'End',   date: endDate,   onTap: onPickEnd)),
          ]),
          const SizedBox(height: 20),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bearish.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!, style: const TextStyle(color: AppTheme.bearish, fontSize: 13)),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: running ? null : onRun,
            icon: running
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow),
            label: Text(running ? 'Running…' : 'Run Backtest'),
          ),
        ]),
      )),

      // ── Result ─────────────────────────────────────────────────
      if (result != null && !running) ...[
        const SizedBox(height: 20),
        Text('Results — ${result!.symbol} / ${result!.strategy ?? 'All'}',
             style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4,
          children: [
            StatCard(
              label: 'Total Return',
              value: '${(result!.totalReturnPct ?? 0) >= 0 ? '+' : ''}${result!.totalReturnPct?.toStringAsFixed(2) ?? '—'}%',
              color: (result!.totalReturnPct ?? 0) >= 0 ? AppTheme.bullish : AppTheme.bearish,
            ),
            StatCard(label: 'Win Rate',     value: '${result!.winRatePct?.toStringAsFixed(1) ?? '—'}%', color: AppTheme.primary),
            StatCard(label: 'Trades',       value: '${result!.totalTrades ?? '—'}'),
            StatCard(
              label: 'Max Drawdown',
              value: '-${result!.maxDrawdownPct?.toStringAsFixed(2) ?? '—'}%',
              color: AppTheme.bearish,
            ),
          ],
        ),
        if (result!.message != null) ...[
          const SizedBox(height: 8),
          Text(result!.message!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
        if (result!.trades.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Trade Returns', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _TradeBarChart(result!.trades),
          const SizedBox(height: 16),
          _TradeTable(result!.trades),
        ],
      ],
    ],
  );
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          Text('${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
               style: const TextStyle(fontSize: 13)),
        ]),
      ]),
    ),
  );
}

class _TradeBarChart extends StatelessWidget {
  final List<TradeRecord> trades;
  const _TradeBarChart(this.trades);
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    child: BarChart(BarChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 0.5)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:   AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 40,
          getTitlesWidget: (v, _) =>
              Text('${v.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        )),
      ),
      barGroups: trades.asMap().entries.map((e) => BarChartGroupData(
        x: e.key,
        barRods: [BarChartRodData(
          toY: e.value.returnPct ?? 0,
          color: (e.value.returnPct ?? 0) >= 0 ? AppTheme.bullish : AppTheme.bearish,
          width: 14, borderRadius: BorderRadius.circular(4),
        )],
      )).toList(),
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: AppTheme.surface,
        getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
            '${rod.toY >= 0 ? '+' : ''}${rod.toY.toStringAsFixed(2)}%',
            TextStyle(color: rod.toY >= 0 ? AppTheme.bullish : AppTheme.bearish, fontSize: 12)),
      )),
    )),
  );
}

class _TradeTable extends StatelessWidget {
  final List<TradeRecord> trades;
  const _TradeTable(this.trades);
  @override
  Widget build(BuildContext context) => Card(
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: AppTheme.surfaceAlt,
        child: const Row(children: [
          Expanded(child: Text('Entry',  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
          Expanded(child: Text('Exit',   style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
          SizedBox(width: 80, child: Text('Buy ₹',  textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
          SizedBox(width: 80, child: Text('Sell ₹', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
          SizedBox(width: 60, child: Text('Return', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        ]),
      ),
      ...trades.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
        child: Row(children: [
          Expanded(child: Text(t.entryDate ?? '—', style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(t.exitDate  ?? '—', style: const TextStyle(fontSize: 11))),
          SizedBox(width: 80, child: Text(t.entryPrice != null ? t.entryPrice!.toStringAsFixed(0) : '—',
              textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 80, child: Text(t.exitPrice != null ? t.exitPrice!.toStringAsFixed(0) : '—',
              textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 60, child: Text(
            t.returnPct != null ? '${t.returnPct! >= 0 ? '+' : ''}${t.returnPct!.toStringAsFixed(1)}%' : '—',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: (t.returnPct ?? 0) >= 0 ? AppTheme.bullish : AppTheme.bearish),
          )),
        ]),
      )),
    ]),
  );
}

// ── History tab ──────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<BacktestResultModel> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('📊', style: TextStyle(fontSize: 56)),
        SizedBox(height: 12),
        Text('No backtests run yet', style: TextStyle(color: AppTheme.textSecondary)),
      ]),
    );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final r = history[i];
        final ret = r.totalReturnPct ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(children: [
              Text(r.symbol ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(width: 8),
              Text(r.strategy ?? 'All',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            subtitle: Text('${r.startDate ?? '—'} → ${r.endDate ?? '—'}  ·  '
                '${r.totalTrades ?? 0} trades  ·  WR ${r.winRatePct?.toStringAsFixed(1) ?? '—'}%',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${ret >= 0 ? '+' : ''}${ret.toStringAsFixed(2)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                      color: ret >= 0 ? AppTheme.bullish : AppTheme.bearish)),
              Text('DD -${r.maxDrawdownPct?.toStringAsFixed(1) ?? '—'}%',
                  style: const TextStyle(fontSize: 11, color: AppTheme.bearish)),
            ]),
          ),
        );
      },
    );
  }
}
