import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../data/models/stock_model.dart';
import 'watchlist_screen.dart';
import 'alerts_screen.dart';
import 'backtest_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Screener states
  String _selectedScreenerFilter = 'ALL';
  String _selectedExchange = '';
  String _selectedSector = '';

  // Signals states
  String _selectedSignalType = ''; // '' for All, 'BUY', 'SELL'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchStocks();
    });
  }

  Future<void> _refreshStocks() async {
    await context.read<StockProvider>().fetchStocks();
  }

  void _triggerSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting stock price sync with Yahoo Finance...'),
        duration: Duration(seconds: 2),
      ),
    );
    final success = await context.read<StockProvider>().triggerSync();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync triggered. Please pull down to refresh in a few seconds.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to trigger sync. Please check server logs.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showStockDetails(BuildContext context, StockModel stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _StockDetailsBottomSheet(stock: stock);
      },
    );
  }

  void _runScreener() {
    context.read<StockProvider>().fetchScreenerResults(
      _selectedScreenerFilter,
      exchange: _selectedExchange,
      sector: _selectedSector,
    );
  }

  void _runSignalsFeed() {
    context.read<StockProvider>().fetchSignals(
      type: _selectedSignalType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final stockProvider = context.watch<StockProvider>();
    final username = authProvider.username ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'STOCK ANALYZER'
              : (_currentIndex == 1
                  ? 'TECHNICAL SCREENER'
                  : (_currentIndex == 2
                      ? 'BUY/SELL SIGNALS'
                      : (_currentIndex == 3
                          ? 'PORTFOLIO WATCHLISTS'
                          : 'ALERTS & SIMULATOR'))),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Color(0xFF06B6D4)),
              tooltip: 'Sync with Yahoo Finance',
              onPressed: _triggerSync,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthProvider>().logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0x1506B6D4), // Subtle Cyan glow
              Color(0xFF0B0F19), // Dark background
            ],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardTab(username, stockProvider),
            _buildScreenerTab(stockProvider),
            _buildSignalsTab(stockProvider),
            WatchlistScreen(showStockDetails: (ctx, stock) => _showStockDetails(ctx, stock)),
            _buildAlertsAndSimulatorTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0F1524),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            context.read<StockProvider>().fetchSectors();
            _runScreener();
          } else if (index == 2) {
            _runSignalsFeed();
          } else if (index == 3) {
            context.read<StockProvider>().fetchWatchlists();
          } else if (index == 4) {
            context.read<StockProvider>().fetchAlerts();
            context.read<StockProvider>().fetchBacktestHistory();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_alt_rounded),
            label: 'Screener',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_rounded),
            label: 'Signals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_rounded),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_rounded),
            label: 'Alerts/Sim',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsAndSimulatorTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0F1524),
            child: const TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: Color(0xFF6366F1),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              tabs: [
                Tab(text: 'ALERTS', icon: Icon(Icons.notifications_active_rounded, size: 18)),
                Tab(text: 'STRATEGY SIMULATOR', icon: Icon(Icons.analytics_rounded, size: 18)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AlertsScreen(),
                BacktestScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: DASHBOARD ──────────────────────────────────────────────────────
  Widget _buildDashboardTab(String username, StockProvider stockProvider) {
    return RefreshIndicator(
      onRefresh: _refreshStocks,
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF161C2D),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF161C2D), Color(0xFF1A233A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $username!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Authentication Session: Active (JWT Token protected)',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Overview Section Header
          const Text(
            'Market Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildIndexCard('NIFTY 50', '22,350.20', '+0.64%', true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndexCard('SENSEX', '73,610.45', '+0.62%', true),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stock Screener Feed Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tracked Stocks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: _refreshStocks,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6366F1)),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Feed list
          _buildStockList(stockProvider),
        ],
      ),
    );
  }

  Widget _buildIndexCard(String title, String value, String change, bool isPositive) {
    final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF161C2D),
          border: Border.all(color: const Color(0x10FFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: changeColor),
                  const SizedBox(width: 4),
                  Text(change, style: TextStyle(color: changeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockList(StockProvider provider) {
    if (provider.isLoading && provider.stocks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }

    if (provider.errorMessage != null && provider.stocks.isEmpty) {
      return Card(
        color: const Color(0xFF1C141E),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshStocks,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.stocks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.query_stats_rounded, size: 56, color: Colors.indigo.shade300),
              const SizedBox(height: 16),
              const Text(
                'No Tracked Stocks Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Database stock records are empty or sync is required.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _triggerSync,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Seed & Sync Yahoo Finance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.stocks.length,
      itemBuilder: (context, index) {
        final stock = provider.stocks[index];
        final bool isPositive = (stock.changePercent ?? 0) >= 0;
        final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        final String sign = isPositive ? '+' : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF161C2D),
              border: Border.all(color: const Color(0x10FFFFFF)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showStockDetails(context, stock),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                stock.symbol,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x156366F1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stock.exchange,
                                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stock.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stock.sector} • ${stock.industry}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stock.price != null ? '₹${stock.price!.toStringAsFixed(2)}' : 'Fetching...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (stock.price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: changeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$sign${stock.changePercent!.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 2: TECHNICAL SCREENER ─────────────────────────────────────────────
  Widget _buildScreenerTab(StockProvider provider) {
    final Map<String, String> filtersMap = {
      'ALL': 'All Active Stocks',
      'MA220_CROSSOVER': 'MA-220 Crossover',
      'MA50_CROSSOVER': 'MA-50 Crossover',
      'WEEK_52_HIGH': '52w High Breakout',
      'VOLUME_BREAKOUT': 'Volume Breakout',
      'RSI_OVERSOLD': 'RSI Oversold (<35)',
      'RSI_OVERBOUGHT': 'RSI Overbought (>70)',
      'MOMENTUM': 'High Momentum (>20%)'
    };

    return Column(
      children: [
        // Screener Filter Selection Card
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF111726),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Technical Strategy Filter:',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filtersMap.entries.map((entry) {
                    final isSelected = _selectedScreenerFilter == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade400,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF1E2638),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedScreenerFilter = entry.key;
                            });
                            _runScreener();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Sector Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSector.isEmpty ? null : _selectedSector,
                          hint: const Text('All Sectors', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          dropdownColor: const Color(0xFF1E2638),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All Sectors'),
                            ),
                            ...provider.sectors.map((sector) {
                              return DropdownMenuItem<String>(
                                value: sector,
                                child: Text(sector),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSector = val ?? '';
                            });
                            _runScreener();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Exchange Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedExchange.isEmpty ? null : _selectedExchange,
                          hint: const Text('All Exchanges', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          dropdownColor: const Color(0xFF1E2638),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          items: const [
                            DropdownMenuItem<String>(value: '', child: Text('All Exchanges')),
                            DropdownMenuItem<String>(value: 'NSE', child: Text('NSE')),
                            DropdownMenuItem<String>(value: 'BSE', child: Text('BSE')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedExchange = val ?? '';
                            });
                            _runScreener();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Screener Results list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _runScreener(),
            color: const Color(0xFF6366F1),
            child: _buildScreenerList(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenerList(StockProvider provider) {
    if (provider.isLoading && provider.screenerResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))));
    }

    if (provider.errorMessage != null && provider.screenerResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (provider.screenerResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text('No stocks match this filter criteria.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: provider.screenerResults.length,
      itemBuilder: (context, index) {
        final res = provider.screenerResults[index];
        final stock = StockModel(
          id: 0,
          symbol: res.symbol,
          name: res.name,
          exchange: res.exchange,
          sector: res.sector,
          industry: '',
          price: res.closePrice,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF161C2D),
              border: Border.all(color: const Color(0x10FFFFFF)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showStockDetails(context, stock),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  res.symbol,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x156366F1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    res.exchange,
                                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(res.name, maxLines: 1, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        Text(
                          res.closePrice != null ? '₹${res.closePrice!.toStringAsFixed(2)}' : 'N/A',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0x10FFFFFF), height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          res.sector,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            res.matchedFilters.replaceAll('_', ' '),
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 3: SIGNALS TAB ────────────────────────────────────────────────────
  Widget _buildSignalsTab(StockProvider provider) {
    return Column(
      children: [
        // Signal type chips (All, BUY, SELL)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: const Color(0xFF111726),
          child: Row(
            children: [
              const Text('Filter Signals:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildSignalTypeChip('ALL', ''),
              const SizedBox(width: 8),
              _buildSignalTypeChip('BUY', 'BUY'),
              const SizedBox(width: 8),
              _buildSignalTypeChip('SELL', 'SELL'),
            ],
          ),
        ),

        // Signals Feed List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _runSignalsFeed(),
            color: const Color(0xFF6366F1),
            child: _buildSignalsList(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalTypeChip(String label, String value) {
    final isSelected = _selectedSignalType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: value == 'BUY'
          ? const Color(0xFF10B981)
          : (value == 'SELL' ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
      backgroundColor: const Color(0xFF1E2638),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedSignalType = value;
          });
          _runSignalsFeed();
        }
      },
    );
  }

  Widget _buildSignalsList(StockProvider provider) {
    if (provider.isLoading && provider.signals.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))));
    }

    if (provider.errorMessage != null && provider.signals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (provider.signals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.offline_bolt_rounded, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text('No buy/sell signals generated today.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: provider.signals.length,
      itemBuilder: (context, index) {
        final sig = provider.signals[index];
        final bool isBuy = sig.signalType == 'BUY';
        final Color typeColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        final dateStr = '${sig.signalDate.day.toString().padLeft(2, '0')}-${sig.signalDate.month.toString().padLeft(2, '0')}-${sig.signalDate.year}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF161C2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: typeColor.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          sig.symbol,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sig.signalType,
                            style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  sig.strategy.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  sig.notes,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trigger: ₹${sig.triggerPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        // Quick lookup and show stock details
                        final found = provider.stocks.firstWhere(
                          (element) => element.symbol.toUpperCase() == sig.symbol.toUpperCase(),
                          orElse: () => StockModel(
                            id: 0,
                            symbol: sig.symbol,
                            name: sig.symbol,
                            exchange: 'NSE',
                            sector: '',
                            industry: '',
                            price: sig.triggerPrice,
                          ),
                        );
                        _showStockDetails(context, found);
                      },
                      child: const Text('View Charts', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── BOTTOM SHEET STOCK DETAILS ──────────────────────────────────────────────
class _StockDetailsBottomSheet extends StatefulWidget {
  final StockModel stock;
  const _StockDetailsBottomSheet({required this.stock});

  @override
  State<_StockDetailsBottomSheet> createState() => _StockDetailsBottomSheetState();
}

class _StockDetailsBottomSheetState extends State<_StockDetailsBottomSheet> {
  StockDetailModel? _detail;
  List<SignalModel> _stockSignals = [];
  AiSummaryModel? _aiSummary;
  bool _isLoading = true;
  bool _loadingSummary = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadAiSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchWatchlists();
    });
  }

  void _loadDetail() async {
    try {
      final stockProvider = context.read<StockProvider>();
      final detail = await stockProvider.fetchStockDetail(widget.stock.symbol);
      final signals = await stockProvider.fetchStockSignals(widget.stock.symbol);
      if (mounted) {
        setState(() {
          _detail = detail;
          _stockSignals = signals;
          _isLoading = false;
          if (detail == null) {
            _error = "Failed to load historical price history.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Error: $e";
        });
      }
    }
  }

  void _loadAiSummary() async {
    if (!mounted) return;
    setState(() {
      _loadingSummary = true;
    });
    try {
      final summary = await context.read<StockProvider>().fetchAiSummary(widget.stock.symbol);
      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _loadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSummary = false;
        });
      }
    }
  }

  void _showWatchlistSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161C2D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer<StockProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ADD/REMOVE FROM WATCHLISTS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const Divider(color: Color(0x10FFFFFF)),
                  if (provider.watchlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please create a watchlist in the Watchlists tab first.')),
                            );
                          },
                          child: const Text('CREATE WATCHLIST IN TAB', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.watchlists.length,
                      itemBuilder: (c, idx) {
                        final wl = provider.watchlists[idx];
                        final hasStock = wl.stocks.any((s) => s.symbol.toUpperCase() == widget.stock.symbol.toUpperCase());
                        return CheckboxListTile(
                          activeColor: const Color(0xFF6366F1),
                          checkColor: Colors.white,
                          title: Text(wl.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${wl.stocks.length} stocks', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          value: hasStock,
                          onChanged: (val) {
                            if (val == true) {
                              provider.addStockToWatchlist(wl.id, widget.stock.symbol);
                            } else {
                              provider.removeStockFromWatchlist(wl.id, widget.stock.symbol);
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF111726),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadDetail();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _buildDetailsContent(),
    );
  }

  Widget _buildDetailsContent() {
    final bool isPositive = (widget.stock.changePercent ?? 0) >= 0;
    final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final String sign = isPositive ? '+' : '';
    final List<double> closePrices = _detail!.history.map((e) => e.close).toList();

    return Column(
      children: [
        // Drag indicator handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Bottom sheet header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stock.symbol,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.stock.name,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.stock.exchange} • ${widget.stock.sector} • ${widget.stock.industry}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFF06B6D4)),
                tooltip: 'Manage Watchlists',
                onPressed: _showWatchlistSelector,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
        const Divider(color: Color(0x15FFFFFF)),

        // Main detail body (scrollable)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Price block
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LATEST PRICE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          widget.stock.price != null ? '₹${widget.stock.price!.toStringAsFixed(2)}' : 'N/A',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    if (widget.stock.price != null && widget.stock.changePercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: changeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$sign${widget.stock.changePercent!.toStringAsFixed(2)}%',
                          style: TextStyle(color: changeColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sparkline Chart Card
              Card(
                color: const Color(0xFF161C2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0x10FFFFFF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1-Year Close Price Trend (${closePrices.length} trading days)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (closePrices.length >= 2)
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: SparklinePainter(
                              data: closePrices,
                              lineColor: changeColor,
                              fillColor: changeColor,
                            ),
                          ),
                        )
                      else
                        const SizedBox(
                          height: 150,
                          child: Center(
                            child: Text('Insufficient price points for trend line', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI Stock Profile
              _buildAiSummaryCard(),
              const SizedBox(height: 16),

              // Technical Indicators Grid
              _buildTechnicalIndicatorsGrid(_detail!),
              const SizedBox(height: 16),

              // Buy/Sell Signals History Feed
              const Text(
                'Buy/Sell Signals History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              _buildSignalsHistoryFeed(),
              const SizedBox(height: 20),

              // Key Stats Table
              if (_detail!.history.isNotEmpty) ...[
                const Text(
                  'Latest Daily Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                _buildMetricsGrid(_detail!.history.last),
                const SizedBox(height: 24),
              ],

              // History table
              const Text(
                'Historical Price Feed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              if (_detail!.history.isEmpty)
                const Center(child: Text('No historical rates found.', style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _detail!.history.length > 15 ? 15 : _detail!.history.length,
                  itemBuilder: (context, index) {
                    final pricePoint = _detail!.history[_detail!.history.length - 1 - index];
                    final dateStr = '${pricePoint.date.day.toString().padLeft(2, '0')}-${pricePoint.date.month.toString().padLeft(2, '0')}-${pricePoint.date.year}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161C2D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x08FFFFFF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '₹${pricePoint.close.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            Text(
                              'Vol: ${_formatVolume(pricePoint.volume)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSummaryCard() {
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF06B6D4), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI STOCK PROFILE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Outfit', letterSpacing: 0.5),
                    ),
                  ],
                ),
                if (!_loadingSummary)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 18),
                    onPressed: _loadAiSummary,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingSummary)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2.5),
                  ),
                ),
              )
            else if (_aiSummary != null)
              Text(
                _aiSummary!.summaryText,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45, fontFamily: 'Outfit'),
              )
            else
              Center(
                child: TextButton(
                  onPressed: _loadAiSummary,
                  child: const Text('GENERATE AI TECHNICAL SUMMARY', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalIndicatorsGrid(StockDetailModel detail) {
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
          children: [
            const Text(
              'Technical Analysis Indicators',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildIndicatorCard('RSI (14)', detail.rsi14 != null ? detail.rsi14!.toStringAsFixed(1) : 'N/A', 
                    _getRsiStatus(detail.rsi14)),
                _buildIndicatorCard('12M Momentum', detail.momentumScore != null ? '${detail.momentumScore!.toStringAsFixed(1)}%' : 'N/A',
                    detail.momentumScore != null && detail.momentumScore! > 20 ? 'Strong Bullish' : 'Neutral'),
                _buildIndicatorCard('MA (50)', detail.ma50 != null ? '₹${detail.ma50!.toStringAsFixed(1)}' : 'N/A',
                    _getMaStatus(widget.stock.price, detail.ma50)),
                _buildIndicatorCard('MA (220)', detail.ma220 != null ? '₹${detail.ma220!.toStringAsFixed(1)}' : 'N/A',
                    _getMaStatus(widget.stock.price, detail.ma220)),
                _buildIndicatorCard('52w High', detail.week52High != null ? '₹${detail.week52High!.toStringAsFixed(1)}' : 'N/A',
                    'Resistance'),
                _buildIndicatorCard('52w Low', detail.week52Low != null ? '₹${detail.week52Low!.toStringAsFixed(1)}' : 'N/A',
                    'Support'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(String title, String value, String status) {
    Color statusColor = Colors.grey;
    if (status.contains('Bullish') || status.contains('above') || status.contains('Buy')) {
      statusColor = const Color(0xFF10B981);
    } else if (status.contains('Bearish') || status.contains('below') || status.contains('Sell')) {
      statusColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x08FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getRsiStatus(double? rsi) {
    if (rsi == null) return 'No Data';
    if (rsi < 35) return 'Oversold (Buy)';
    if (rsi > 70) return 'Overbought (Sell)';
    return 'Neutral';
  }

  String _getMaStatus(double? price, double? ma) {
    if (price == null || ma == null) return 'No Data';
    return price > ma ? 'Price above MA' : 'Price below MA';
  }

  Widget _buildSignalsHistoryFeed() {
    if (_stockSignals.isEmpty) {
      return const Card(
        color: Color(0xFF161C2D),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No historical signals generated for this stock.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stockSignals.length,
      itemBuilder: (context, index) {
        final sig = _stockSignals[index];
        final bool isBuy = sig.signalType == 'BUY';
        final Color typeColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        final dateStr = '${sig.signalDate.day.toString().padLeft(2, '0')}-${sig.signalDate.month.toString().padLeft(2, '0')}-${sig.signalDate.year}';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: const Color(0xFF161C2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: typeColor.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sig.signalType,
                        style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sig.strategy.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  sig.notes,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trigger Price: ₹${sig.triggerPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(PricePoint point) {
    return Card(
      color: const Color(0xFF161C2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x10FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Open', '₹${point.open?.toStringAsFixed(2) ?? "N/A"}'),
                _buildStatItem('High', '₹${point.high?.toStringAsFixed(2) ?? "N/A"}'),
              ],
            ),
            const Divider(color: Color(0x10FFFFFF), height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Low', '₹${point.low?.toStringAsFixed(2) ?? "N/A"}'),
                _buildStatItem('Volume', _formatVolume(point.volume)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  String _formatVolume(int? volume) {
    if (volume == null) return 'N/A';
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(2)} Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(2)} L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)} K';
    }
    return volume.toString();
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  SparklinePainter({required this.data, required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final Path path = Path();
    final double dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = i * dx;
      final double y = size.height - ((data[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor.withOpacity(0.3), fillColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}
