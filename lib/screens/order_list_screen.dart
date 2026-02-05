import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../main.dart'; // Import AppState
import 'add_edit_order_screen.dart';
//import '../models/customer.dart'; // To get customer name - not directly used here

class OrderListScreen extends StatefulWidget { // Changed to StatefulWidget for search bar
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<AppState>(context, listen: false).setOrderSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper for status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Cutting': return Colors.blue.shade200;
      case 'Stitching': return Colors.orange.shade200;
      case 'Ready': return Colors.green.shade200;
      case 'Delivered': return Colors.grey.shade400;
      default: return Colors.grey.shade100;
    }
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
              // TODO: Navigate to Subscription/Upgrade screen (Phase 4)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Taking you to upgrade options...')),
              );
              Provider.of<AppState>(context, listen: false).upgradeToPremium(); // For testing
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // Corrected build method signature
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize( // Add search bar below AppBar
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders by customer, tracking #, status...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<AppState>(context, listen: false).setOrderSearchQuery('');
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
              Provider.of<AppState>(context, listen: false).refreshOrders();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.orders.isEmpty) { // Check filtered list
            return Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No orders added yet. Click + to add your first order!'
                    : 'No orders found matching "${_searchController.text}"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: appState.orders.length,
            itemBuilder: (context, index) {
              final order = appState.orders[index];
              final customer = appState.getCustomerById(order.customerId);
              return OrderCard(
                order: order,
                customerName: customer?.name ?? 'Unknown Customer',
                statusColor: _getStatusColor(order.status),
                onEdit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEditOrderScreen(order: order),
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Order?'),
                      content: Text('Are you sure you want to delete this order for ${customer?.name ?? 'Unknown Customer'}?'),
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
                    await appState.deleteOrder(order);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order deleted!')),
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
              if (!appState.canAddMoreOrders) {
                if (!appState.isTrialActive && !appState.hasUsedTrial) {
                  await appState.startTrial();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('7-day free trial started!')),
                  );
                  if (!appState.canAddMoreOrders) {
                    _showUpgradePrompt(context, appState.orderLimitMessage);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEditOrderScreen(),
                      ),
                    );
                  }
                } else {
                   _showUpgradePrompt(context, appState.orderLimitMessage);
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEditOrderScreen(),
                  ),
                );
              }
            },
            label: const Text('Add Order'),
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

// --- Custom Widget for Order List Item ---
class OrderCard extends StatelessWidget {
  final Order order;
  final String customerName;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OrderCard({
    Key? key,
    required this.order,
    required this.customerName,
    required this.statusColor,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order for $customerName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) // NEW: Display tracking number
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Tracking #: ${order.trackingNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ),
            const SizedBox(height: 8),
            Text('Delivery Date: ${DateFormat('dd MMM yyyy').format(order.deliveryDate)}'),
            Text('Total: PKR ${order.totalPrice.toStringAsFixed(2)}'),
            Text('Advance: PKR ${order.advancePayment.toStringAsFixed(2)}'),
            Text('Remaining: PKR ${order.remainingPayment.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }
}