import 'package:flutter/material.dart';
import '../models/customer.dart'; // Import Customer model

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(context, Icons.person, 'Name:', customer.name),
            _buildDetailRow(context, Icons.phone, 'Phone:', customer.phone),
            _buildDetailRow(context, Icons.home, 'Address:', customer.address),
            const SizedBox(height: 30),
            Text(
              'No orders or measurements yet.', // Placeholder
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
            // TODO: In future phases, integrate tabs or sections for Orders and Measurements
          ],
        ),
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