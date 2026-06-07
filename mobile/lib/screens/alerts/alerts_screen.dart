import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/alert_provider.dart';
import '../../data/models/alert_model.dart';

const _alertTypes = [
  'PRICE_ABOVE', 'PRICE_BELOW',
  'MA220_CROSSOVER_UP', 'MA220_CROSSOVER_DOWN',
  'MA50_CROSSOVER_UP',  'MA50_CROSSOVER_DOWN',
  'RSI_OVERBOUGHT',     'RSI_OVERSOLD',
  'VOLUME_BREAKOUT',    'WEEK_52_HIGH',
];

const _needsThreshold = {'PRICE_ABOVE', 'PRICE_BELOW'};

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: () => _showCreateSheet(context, ref),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.bearish))),
        data: (alerts) {
          if (alerts.isEmpty) return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔔', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('No alerts set', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Alert'),
              ),
            ]),
          );
          return RefreshIndicator(
            onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (ctx, i) => _AlertTile(alerts[i], ref),
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final symbolCtrl    = TextEditingController();
    final thresholdCtrl = TextEditingController();
    String selectedType = 'PRICE_ABOVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create Alert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Symbol
              TextField(
                controller: symbolCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Stock Symbol', hintText: 'e.g. TCS'),
              ),
              const SizedBox(height: 14),

              // Alert type dropdown
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Alert Type'),
                dropdownColor: AppTheme.surface,
                items: _alertTypes.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setLocal(() => selectedType = v ?? selectedType),
              ),
              const SizedBox(height: 14),

              // Threshold (only for PRICE_ABOVE / PRICE_BELOW)
              if (_needsThreshold.contains(selectedType)) ...[
                TextField(
                  controller: thresholdCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Threshold (₹)', hintText: 'e.g. 4000'),
                ),
                const SizedBox(height: 14),
              ],

              ElevatedButton(
                onPressed: () async {
                  final sym = symbolCtrl.text.trim().toUpperCase();
                  if (sym.isEmpty) return;
                  double? threshold;
                  if (_needsThreshold.contains(selectedType)) {
                    threshold = double.tryParse(thresholdCtrl.text.trim());
                    if (threshold == null) return;
                  }
                  Navigator.pop(ctx);
                  await ref
                      .read(alertsProvider.notifier)
                      .create(sym, selectedType, threshold);
                },
                child: const Text('Create Alert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertModel alert;
  final WidgetRef  ref;
  const _AlertTile(this.alert, this.ref);

  @override
  Widget build(BuildContext context) {
    final isSell = alert.alertType.contains('DOWN') ||
        alert.alertType.contains('BELOW') ||
        alert.alertType.contains('OVERBOUGHT');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              (isSell ? AppTheme.bearish : AppTheme.bullish).withOpacity(0.15),
          child: Icon(
            isSell ? Icons.trending_down : Icons.trending_up,
            color: isSell ? AppTheme.bearish : AppTheme.bullish,
            size: 20,
          ),
        ),
        title: Row(children: [
          Text(alert.symbol,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(alert.displayType,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alert.threshold != null)
              Text('Threshold: ₹${alert.threshold!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12)),
            Text(
              alert.lastTriggered != null
                  ? 'Last fired: ${alert.lastTriggered!.split('T')[0]}'
                  : 'Never triggered',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.bullish.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Active',
                style: TextStyle(fontSize: 11, color: AppTheme.bullish)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppTheme.textSecondary),
            onPressed: () => ref.read(alertsProvider.notifier).delete(alert.id),
          ),
        ]),
      ),
    );
  }
}
