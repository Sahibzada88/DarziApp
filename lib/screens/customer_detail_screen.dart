import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
import 'dart:io'; // For File
import '../models/customer.dart';
// import '../models/order.dart';
// import '../models/measurement.dart';
import '../main.dart'; // Import AppState
import 'add_edit_customer_screen.dart';
import 'add_edit_order_screen.dart';
import 'add_edit_measurement_screen.dart';
import 'order_list_screen.dart'; // For OrderCard
import 'measurement_list_screen.dart'; // For MeasurementCard

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  // Helper for status colors (copied from order_list_screen)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Cutting': return Colors.blue.shade200;
      case 'Stitching': return Colors.orange.shade200;
      case 'Ready': return Colors.green.shade200;
      case 'Delivered': return Colors.grey.shade400;
      default: return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final customerOrders = appState.getOrdersForCustomer(customer.key.toString());
    final customerMeasurements = appState.getMeasurementsForCustomer(customer.key.toString());

    return DefaultTabController(
      length: 3, // Details, Orders, Measurements
      child: Scaffold(
        appBar: AppBar(
          title: Text(customer.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEditCustomerScreen(customer: customer),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details', icon: Icon(Icons.info_outline)),
              Tab(text: 'Orders', icon: Icon(Icons.receipt_long)),
              Tab(text: 'Measurements', icon: Icon(Icons.straighten)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Customer Details
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      backgroundImage: customer.profileImagePath != null
                          ? FileImage(File(customer.profileImagePath!))
                          : null,
                      child: customer.profileImagePath == null
                          ? Icon(Icons.person, size: 50, color: Theme.of(context).primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Customer Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(context, Icons.person, 'Name:', customer.name),
                  _buildDetailRow(context, Icons.phone, 'Phone:', customer.phone),
                  _buildDetailRow(context, Icons.home, 'Address:', customer.address),
                  if (customer.notes != null && customer.notes!.isNotEmpty)
                    _buildDetailRow(context, Icons.notes, 'Notes:', customer.notes!),
                ],
              ),
            ),

            // Tab 2: Orders for this Customer
            customerOrders.isEmpty
                ? const Center(child: Text('No orders for this customer yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: customerOrders.length,
                    itemBuilder: (context, index) {
                      final order = customerOrders[index];
                      return OrderCard( // Reuse OrderCard from order_list_screen
                        order: order,
                        customerName: customer.name,
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
                              content: Text('Are you sure you want to delete this order for ${customer.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await appState.deleteOrder(order);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted!')));
                          }
                        },
                      );
                    },
                  ),

            // Tab 3: Measurements for this Customer
            customerMeasurements.isEmpty
                ? const Center(child: Text('No measurements for this customer yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: customerMeasurements.length,
                    itemBuilder: (context, index) {
                      final measurement = customerMeasurements[index];
                      return MeasurementCard( // Reuse MeasurementCard from measurement_list_screen
                        measurement: measurement,
                        customerName: customer.name,
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
                              content: Text('Are you sure you want to delete this measurement for ${customer.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await appState.deleteMeasurement(measurement);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurement deleted!')));
                          }
                        },
                      );
                    },
                  ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            // Show FAB based on selected tab
            if (tabController.index == 1) { // Orders tab
              return FloatingActionButton.extended(
                onPressed: () async {
                   if (!appState.canAddMoreOrders) {
                     if (!appState.isTrialActive && !appState.hasUsedTrial) {
                       await appState.startTrial();
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('7-day free trial started!')));
                       if (!appState.canAddMoreOrders) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appState.orderLimitMessage)));
                         return;
                       }
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appState.orderLimitMessage)));
                        return;
                     }
                   }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEditOrderScreen(initialCustomerId: customer.key.toString()),
                    ),
                  );
                },
                label: const Text('Add Order'),
                icon: const Icon(Icons.add),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              );
            } else if (tabController.index == 2) { // Measurements tab
              return FloatingActionButton.extended(
                onPressed: () async {
                  if (!appState.canAddMoreMeasurements) {
                    if (!appState.isTrialActive && !appState.hasUsedTrial) {
                      await appState.startTrial();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('7-day free trial started!')));
                      if (!appState.canAddMoreMeasurements) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appState.measurementLimitMessage)));
                        return;
                      }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appState.measurementLimitMessage)));
                       return;
                    }
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEditMeasurementScreen(initialCustomerId: customer.key.toString()),
                    ),
                  );
                },
                label: const Text('Add Measurement'),
                icon: const Icon(Icons.add),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              );
            }
            return const SizedBox.shrink(); // Hide FAB for Details tab
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}