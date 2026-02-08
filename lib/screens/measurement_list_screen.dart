import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/measurement.dart';
import '../main.dart';
import 'add_edit_measurement_screen.dart';

class MeasurementListScreen extends StatefulWidget {
  const MeasurementListScreen({Key? key}) : super(key: key);

  @override
  State<MeasurementListScreen> createState() => _MeasurementListScreenState();
}

class _MeasurementListScreenState extends State<MeasurementListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<AppState>(context, listen: false).setMeasurementSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUpgradePrompt(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limit Reached!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Taking you to upgrade options...')),
              );
              Provider.of<AppState>(context, listen: false).upgradeToPremium();
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurements'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search measurements by customer, type, ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<AppState>(context, listen: false).setMeasurementSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).refreshMeasurements();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.measurements.isEmpty) {
            return Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No measurements added yet. Click + to add your first measurement!'
                    : 'No measurements found matching "${_searchController.text}"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: appState.measurements.length,
            itemBuilder: (context, index) {
              final measurement = appState.measurements[index];
              final customer = appState.getCustomerById(measurement.customerId);
              return MeasurementCard(
                measurement: measurement,
                customerName: customer?.name ?? 'Unknown Customer',
                onEdit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEditMeasurementScreen(measurement: measurement),
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Measurement?'),
                      content: Text('Are you sure you want to delete this measurement for ${customer?.name ?? 'Unknown Customer'}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await appState.deleteMeasurement(measurement);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Measurement deleted!')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<AppState>(
        builder: (context, appState, child) {
          return FloatingActionButton.extended(
            onPressed: () async {
              if (!appState.canAddMoreMeasurements) {
                if (!appState.isTrialActive && !appState.hasUsedTrial) {
                  await appState.startTrial();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('7-day free trial started!')),
                  );
                  if (!appState.canAddMoreMeasurements) {
                    _showUpgradePrompt(context, appState.measurementLimitMessage);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEditMeasurementScreen(),
                      ),
                    );
                  }
                } else {
                   _showUpgradePrompt(context, appState.measurementLimitMessage);
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEditMeasurementScreen(),
                  ),
                );
              }
            },
            label: const Text('Add Measurement'),
            icon: const Icon(Icons.add),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- Custom Widget for Measurement List Item ---
class MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final String customerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MeasurementCard({
    Key? key,
    required this.measurement,
    required this.customerName,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.straighten, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          '${measurement.type} for $customerName',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'ID: ${measurement.key} - ${DateFormat('dd MMM yyyy').format(measurement.createdAt)}', // NEW: Display created date
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[600]),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: measurement.values.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${entry.key}: ${entry.value} inches',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}