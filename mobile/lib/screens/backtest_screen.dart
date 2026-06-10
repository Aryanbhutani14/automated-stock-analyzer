import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../data/models/stock_model.dart';

class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key});

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _symbolController = TextEditingController(text: 'RELIANCE');
  final _capitalController = TextEditingController(text: '100000');
  String _selectedStrategy = 'MA50_CROSSOVER';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  bool _isRunning = false;
  BacktestResultModel? _currentResult;

  final List<String> _strategies = [
    'MA50_CROSSOVER',
    'MA220_CROSSOVER',
    'RSI_STRATEGY',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchBacktestHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symbolController.dispose();
    _capitalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF161C2D),
              onSurface: Colors.white70,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _runSimulation() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    if (symbol.isEmpty) return;

    final capitalVal = double.tryParse(_capitalController.text.trim()) ?? 100000.0;

    setState(() {
      _isRunning = true;
      _currentResult = null;
    });

    final startDateStr = "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endDateStr = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";

    final result = await context.read<StockProvider>().runBacktest(
          _selectedStrategy,
          symbol,
          startDateStr,
          endDateStr,
          capitalVal,
        );

    if (mounted) {
      setState(() {
        _isRunning = false;
        _currentResult = result;
      });

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backtest completed successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        // Refresh history tab
        context.read<StockProvider>().fetchBacktestHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<StockProvider>().errorMessage ?? 'Failed to execute backtest.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: const Color(0xFF6366F1),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            tabs: const [
              Tab(text: 'RUN SIMULATION'),
              Tab(text: 'PAST RUNS HISTORY'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSimulationTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSimulationTab() {
    final String startFormatted = "${_startDate.day}/${_startDate.month}/${_startDate.year}";
    final String endFormatted = "${_endDate.day}/${_endDate.month}/${_endDate.year}";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF161C2D), Color(0xFF1A233A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x15FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CONFIG SIMULATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _symbolController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Stock Symbol',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF161C2D),
                      initialValue: _selectedStrategy,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Strategy Model',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _strategies.map((strat) {
                        return DropdownMenuItem(
                          value: strat,
                          child: Text(strat.replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStrategy = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(startFormatted, style: const TextStyle(color: Colors.white)),
                            const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(endFormatted, style: const TextStyle(color: Colors.white)),
                            const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capitalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Initial Capital (₹)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isRunning ? null : _runSimulation,
                  icon: _isRunning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: Text(
                    _isRunning ? 'RUNNING SIMULATION...' : 'START BACKTEST',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_currentResult != null) _buildResultView(_currentResult!),
      ],
    );
  }

  Widget _buildResultView(BacktestResultModel result) {
    final double returnPct = result.totalReturnPct ?? 0.0;
    final double winRate = result.winRatePct ?? 0.0;
    final int trades = result.totalTrades ?? 0;
    final double drawdown = result.maxDrawdownPct ?? 0.0;

    final returnColor = returnPct >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SIMULATION METRICS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('TOTAL RETURNS', '${returnPct >= 0 ? "+" : ""}${returnPct.toStringAsFixed(2)}%', returnColor),
            _buildStatCard('WIN RATE', '${winRate.toStringAsFixed(1)}%', const Color(0xFF06B6D4)),
            _buildStatCard('TOTAL TRADES', trades.toString(), Colors.purpleAccent),
            _buildStatCard('MAX DRAWDOWN', '${drawdown.toStringAsFixed(2)}%', const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('TRADE LEDGER LOG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (result.trades.isEmpty)
          const Card(
            color: Color(0xFF161C2D),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No trades executed in this period.', style: TextStyle(color: Colors.grey))),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161C2D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x10FFFFFF)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.trades.length,
              separatorBuilder: (c, i) => const Divider(color: Color(0x10FFFFFF), height: 1),
              itemBuilder: (context, index) {
                final trade = result.trades[index];
                final isBuy = trade.type.startsWith('BUY');
                final typeColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                return ListTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trade.type,
                          style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${trade.date.day}/${trade.date.month}/${trade.date.year}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Shares: ${trade.shares.toStringAsFixed(1)} @ ₹${trade.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${trade.value.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      if (trade.profitPct != null)
                        Text(
                          '${trade.profitPct! >= 0 ? "+" : ""}${trade.profitPct!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: trade.profitPct! >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Card(
      color: const Color(0xFF161C2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x10FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final stockProvider = context.watch<StockProvider>();

    if (stockProvider.isLoading && stockProvider.backtestHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))));
    }

    if (stockProvider.backtestHistory.isEmpty) {
      return const Center(child: Text('No backtest history logs found.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StockProvider>().fetchBacktestHistory(),
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stockProvider.backtestHistory.length,
        itemBuilder: (context, index) {
          final run = stockProvider.backtestHistory[index];
          final double returnPct = run.totalReturnPct ?? 0.0;
          final returnColor = returnPct >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

          return Card(
            color: const Color(0xFF161C2D),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0x10FFFFFF)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Text(run.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      run.strategyName.replaceAll('_', ' '),
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Period: ${run.startDate.day}/${run.startDate.month}/${run.startDate.year} - ${run.endDate.day}/${run.endDate.month}/${run.endDate.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${returnPct >= 0 ? "+" : ""}${returnPct.toStringAsFixed(2)}%',
                    style: TextStyle(color: returnColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '${run.totalTrades} trades • ${run.winRatePct?.toStringAsFixed(0)}% win',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
