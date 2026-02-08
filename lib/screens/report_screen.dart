import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import AppState
import 'package:intl/intl.dart'; // For currency formatting

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_PK', // Pakistan Rupee locale
      symbol: 'PKR ',
      decimalDigits: 2,
    );

    // Get order status counts
    final ordersByStatus = appState.ordersByStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refreshing any of these will implicitly rebuild the reports as they rely on AppState
              appState.refreshCustomers();
              appState.refreshOrders();
              appState.refreshMeasurements();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reports Refreshed!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling for GridView
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildSummaryCard(
                  context,
                  icon: Icons.people,
                  label: 'Total Customers',
                  value: appState.totalCustomers.toString(),
                  color: Colors.blue.shade100,
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.receipt_long,
                  label: 'Total Orders',
                  value: appState.totalOrders.toString(),
                  color: Colors.green.shade100,
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.straighten,
                  label: 'Total Measurements',
                  value: appState.totalMeasurements.toString(),
                  color: Colors.purple.shade100,
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.attach_money,
                  label: 'Average Order Value',
                  value: currencyFormatter.format(appState.averageOrderValue),
                  color: Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFinancialRow(
                      context,
                      label: 'Total Revenue (Delivered Orders)',
                      value: currencyFormatter.format(appState.totalRevenue),
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green,
                    ),
                    const Divider(),
                    _buildFinancialRow(
                      context,
                      label: 'Total Outstanding Payments',
                      value: currencyFormatter.format(appState.totalOutstandingPayments),
                      icon: Icons.pending_actions,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Orders by Status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ordersByStatus.length,
                itemBuilder: (context, index) {
                  final status = ordersByStatus.keys.elementAt(index);
                  final count = ordersByStatus[status]!;
                  return ListTile(
                    leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                    title: Text('$status Orders'),
                    trailing: Chip(
                      label: Text(count.toString()),
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      labelStyle: TextStyle(color: _getStatusColor(status)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 50), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColorDark),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(BuildContext context, {required String label, required String value, required IconData icon, required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Cutting': return Icons.cut;
      case 'Stitching': return Icons.content_cut; // Or a sewing machine icon if available
      case 'Ready': return Icons.check_circle;
      case 'Delivered': return Icons.local_shipping;
      default: return Icons.info_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Cutting': return Colors.blue;
      case 'Stitching': return Colors.orange;
      case 'Ready': return Colors.green;
      case 'Delivered': return Colors.grey;
      default: return Colors.grey;
    }
  }
}