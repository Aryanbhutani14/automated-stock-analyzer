import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../data/models/stock_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final stockProvider = context.watch<StockProvider>();
    final username = authProvider.username ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STOCK ANALYZER',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
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
              Color(0x1506B6D4), // Subtle Cyan glow top right
              Color(0xFF0B0F19), // Dark bg
            ],
          ),
        ),
        child: RefreshIndicator(
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
                    'Active Stock Screener',
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
        ),
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
                    // Symbol & Sector info
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

                    // Price & Daily change bubble
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
}

class _StockDetailsBottomSheet extends StatefulWidget {
  final StockModel stock;
  const _StockDetailsBottomSheet({required this.stock});

  @override
  State<_StockDetailsBottomSheet> createState() => _StockDetailsBottomSheetState();
}

class _StockDetailsBottomSheetState extends State<_StockDetailsBottomSheet> {
  StockDetailModel? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() async {
    try {
      final detail = await context.read<StockProvider>().fetchStockDetail(widget.stock.symbol);
      if (mounted) {
        setState(() {
          _detail = detail;
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
                    if (widget.stock.price != null)
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
                    // Show in reverse chronological order
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
    return oldDelegate.data != data || oldDelegate.lineColor != oldDelegate.lineColor;
  }
}
