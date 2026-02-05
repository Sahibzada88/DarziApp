import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../main.dart'; // Import AppState

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // Null for add, not null for edit

  const AddEditCustomerScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      _formKey.currentState!.save();

      if (_isEditing) {
        // Update existing customer
        widget.customer!.name = _nameController.text;
        widget.customer!.phone = _phoneController.text;
        widget.customer!.address = _addressController.text;
        await appState.updateCustomer(widget.customer!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer ${widget.customer!.name} updated!')),
        );
      } else {
        // Add new customer
        final newCustomer = Customer(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        );
        try {
          await appState.addCustomer(newCustomer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer ${newCustomer.name} added!')),
          );
        } catch (e) {
          // Catch the limit exception from AppState
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
          // Optionally show a dialog for upgrade prompt if it's a limit issue
          if (e.toString().contains('Upgrade')) {
            // Navigate to Subscription/Upgrade screen or show a specific dialog
          }
          return; // Don't pop if adding failed due to limit
        }
      }
      Navigator.of(context).pop(); // Go back to customer list
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
      ),
      body: SingleChildScrollView( // Allows scrolling on small screens
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!_isEditing && !appState.isPremiumUser) // Show limit message only when adding
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  color: appState.customerCount >= AppState.maxFreeCustomers ? Colors.red[50] : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      appState.customerLimitMessage,
                      style: TextStyle(
                        color: appState.customerCount >= AppState.maxFreeCustomers ? Colors.red[800] : Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'e.g., Ali Khan',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g., 03XX-XXXXXXX',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  // Basic phone number validation for Pakistan
                  if (!RegExp(r'^(0?3[0-4]\d{1}[0-9]{7})$').hasMatch(value) &&
                      !RegExp(r'^(\+923[0-4]\d{1}[0-9]{7})$').hasMatch(value)) {
                    return 'Please enter a valid Pakistani phone number (e.g., 03XX-XXXXXXX)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., Street 1, DHA Phase 5, Lahore',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 3,
                minLines: 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: _saveCustomer,
                icon: Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Save Changes' : 'Add Customer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}