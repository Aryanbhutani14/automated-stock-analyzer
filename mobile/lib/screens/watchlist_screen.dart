import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../data/models/stock_model.dart';

class WatchlistScreen extends StatefulWidget {
  final Function(BuildContext, StockModel) showStockDetails;
  const WatchlistScreen({super.key, required this.showStockDetails});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchWatchlists();
    });
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161C2D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x20FFFFFF))),
          title: const Text('CREATE WATCHLIST', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<StockProvider>().createWatchlist(
                        nameController.text.trim(),
                        descController.text.trim(),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('CREATE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stockProvider.isLoading && stockProvider.watchlists.isEmpty
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))))
          : stockProvider.watchlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No watchlists created yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('CREATE WATCHLIST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<StockProvider>().fetchWatchlists(),
                  color: const Color(0xFF6366F1),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: stockProvider.watchlists.length,
                    itemBuilder: (context, index) {
                      final watchlist = stockProvider.watchlists[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF161C2D), Color(0xFF1A233A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: const Color(0x15FFFFFF)),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          iconColor: const Color(0xFF06B6D4),
                          collapsedIconColor: Colors.grey,
                          title: Row(
                            children: [
                              const Icon(Icons.folder_open_rounded, color: Color(0xFF06B6D4)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      watchlist.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (watchlist.description.isNotEmpty)
                                      Text(
                                        watchlist.description,
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 36, top: 4),
                            child: Text(
                              '${watchlist.stocks.length} stocks',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF161C2D),
                                  title: const Text('Delete Watchlist', style: TextStyle(color: Colors.white)),
                                  content: Text('Are you sure you want to delete "${watchlist.name}"?', style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
                                    TextButton(
                                      onPressed: () {
                                        context.read<StockProvider>().deleteWatchlist(watchlist.id);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('DELETE', style: TextStyle(color: Color(0xFFEF4444))),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          children: [
                            if (watchlist.stocks.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: Text('No stocks in this watchlist yet.', style: TextStyle(color: Colors.grey))),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: watchlist.stocks.length,
                                separatorBuilder: (c, i) => const Divider(color: Color(0x10FFFFFF), height: 1),
                                itemBuilder: (context, sIndex) {
                                  final stock = watchlist.stocks[sIndex];
                                  final isPositive = (stock.changePercent ?? 0.0) >= 0.0;
                                  final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                                  return ListTile(
                                    onTap: () => widget.showStockDetails(context, stock),
                                    title: Text(stock.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text(stock.name, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              stock.price != null ? '₹${stock.price!.toStringAsFixed(2)}' : 'N/A',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            if (stock.changePercent != null)
                                              Text(
                                                '${isPositive ? "+" : ""}${stock.changePercent!.toStringAsFixed(2)}%',
                                                style: TextStyle(color: changeColor, fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey, size: 20),
                                          onPressed: () {
                                            context.read<StockProvider>().removeStockFromWatchlist(watchlist.id, stock.symbol);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
