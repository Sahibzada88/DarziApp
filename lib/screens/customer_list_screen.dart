import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // For File
import '../models/customer.dart';
import '../main.dart';
import 'add_edit_customer_screen.dart';
import 'customer_detail_screen.dart'; // NEW: Import detail screen

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<AppState>(context, listen: false).setCustomerSearchQuery(_searchController.text);
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
              Provider.of<AppState>(context, listen: false).upgradeToPremium(); // For testing
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
        title: const Text('Customers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers by name, phone, address...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<AppState>(context, listen: false).setCustomerSearchQuery('');
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
              Provider.of<AppState>(context, listen: false).refreshCustomers();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          Widget? trialBanner;
          if (!appState.isPremiumUser) {
            if (appState.isTrialActive) {
              trialBanner = Card(
                margin: const EdgeInsets.all(8.0),
                color: Colors.amber[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        'Free Trial: ${appState.daysLeftInTrial} days left!',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to Subscription Page!')),
                          );
                          appState.upgradeToPremium();
                        },
                        child: const Text('Upgrade Now'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (appState.hasUsedTrial) {
              trialBanner = Card(
                margin: const EdgeInsets.all(8.0),
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        'Your Free Trial Has Expired!',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to Subscription Page!')),
                          );
                          appState.upgradeToPremium();
                        },
                        child: const Text('Upgrade to continue'),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (appState.customers.isEmpty && trialBanner == null) {
            return Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No customers added yet. Click + to add your first customer!'
                    : 'No customers found matching "${_searchController.text}"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            children: [
              if (trialBanner != null) trialBanner,
              Expanded(
                child: ListView.builder(
                  itemCount: appState.customers.length,
                  itemBuilder: (context, index) {
                    final customer = appState.customers[index];
                    return CustomerCard(
                      customer: customer,
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddEditCustomerScreen(customer: customer),
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Customer?'),
                            content: Text('Are you sure you want to delete ${customer.name}? This will also delete associated orders and measurements.'),
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
                          await appState.deleteCustomer(customer);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${customer.name} deleted!')),
                          );
                        }
                      },
                      onTap: () { // NEW: Handle tap to view details
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailScreen(customer: customer),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AppState>(
        builder: (context, appState, child) {
          return FloatingActionButton.extended(
            onPressed: () async {
              if (!appState.canAddMoreCustomers) {
                if (!appState.isTrialActive && !appState.hasUsedTrial) {
                  await appState.startTrial();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('7-day free trial started!')),
                  );
                  if (!appState.canAddMoreCustomers) {
                    _showUpgradePrompt(context, appState.customerLimitMessage);
                  } else {
                     Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEditCustomerScreen(),
                      ),
                    );
                  }
                } else {
                   _showUpgradePrompt(context, appState.customerLimitMessage);
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEditCustomerScreen(),
                  ),
                );
              }
            },
            label: const Text('Add Customer'),
            icon: const Icon(Icons.person_add),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- Custom Widget for Customer List Item ---
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap; // NEW: onTap callback

  const CustomerCard({
    Key? key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onTap, // NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell( // NEW: Make the card tappable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: customer.profileImagePath != null
                    ? FileImage(File(customer.profileImagePath!))
                    : null,
                child: customer.profileImagePath == null
                    ? Icon(Icons.person, color: Theme.of(context).primaryColor)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${customer.phone}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Address: ${customer.address}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     if (customer.notes != null && customer.notes!.isNotEmpty) // NEW: Display notes
                       Text(
                         'Notes: ${customer.notes}',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                  ],
                ),
              ),
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
      ),
    );
  }
}