import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<String> _alertTypes = [
    'PRICE_ABOVE',
    'PRICE_BELOW',
    'MA50_CROSSOVER_UP',
    'MA50_CROSSOVER_DOWN',
    'MA220_CROSSOVER_UP',
    'MA220_CROSSOVER_DOWN',
    'RSI_OVERBOUGHT',
    'RSI_OVERSOLD',
    'VOLUME_BREAKOUT',
    'WEEK_52_HIGH'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchAlerts();
    });
  }

  void _showCreateAlert() {
    final symbolController = TextEditingController();
    final thresholdController = TextEditingController();
    String selectedType = _alertTypes.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final needsValue = selectedType.startsWith('PRICE') || 
                               selectedType.startsWith('RSI') || 
                               selectedType == 'VOLUME_BREAKOUT' ||
                               selectedType == 'WEEK_52_HIGH';

            return AlertDialog(
              backgroundColor: const Color(0xFF161C2D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x20FFFFFF))),
              title: const Text('CREATE STOCK ALERT', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: symbolController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Stock Symbol',
                        hintText: 'e.g. RELIANCE',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF161C2D),
                      initialValue: selectedType,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Condition Alert Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _alertTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    if (needsValue) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: selectedType.startsWith('RSI') 
                              ? 'RSI Threshold (e.g. 30)' 
                              : (selectedType == 'VOLUME_BREAKOUT' 
                                  ? 'Volume multiplier (e.g. 1.5)' 
                                  : 'Price Trigger Threshold (₹)'),
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0x30FFFFFF)), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366F1)), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
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
                    final symbol = symbolController.text.trim().toUpperCase();
                    if (symbol.isEmpty) return;

                    double? threshold;
                    if (needsValue && thresholdController.text.trim().isNotEmpty) {
                      threshold = double.tryParse(thresholdController.text.trim());
                    }

                    context.read<StockProvider>().createAlert(symbol, selectedType, threshold);
                    Navigator.pop(ctx);
                  },
                  child: const Text('SAVE', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stockProvider.isLoading && stockProvider.alerts.isEmpty
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))))
          : stockProvider.alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No custom stock alerts set yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showCreateAlert,
                        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
                        label: const Text('CREATE STOCK ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<StockProvider>().fetchAlerts(),
                  color: const Color(0xFF6366F1),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: stockProvider.alerts.length,
                    itemBuilder: (context, index) {
                      final alert = stockProvider.alerts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF161C2D), Color(0xFF1A233A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: const Color(0x15FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_alert_rounded, color: Color(0xFF06B6D4)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        alert.symbol,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          alert.alertType.replaceAll('_', ' '),
                                          style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.name,
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (alert.threshold != null)
                                    Text(
                                      'Target: ${alert.threshold!.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  if (alert.lastTriggered != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Last triggered: ${alert.lastTriggered!.toLocal().toString().split('.')[0]}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                              onPressed: () {
                                context.read<StockProvider>().deleteAlert(alert.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _showCreateAlert,
        child: const Icon(Icons.add_alert_rounded, color: Colors.white),
      ),
    );
  }
}
