import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // NEW: Image picker
import 'dart:io'; // For File
import '../models/customer.dart';
import '../main.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddEditCustomerScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController; // NEW: Notes controller

  String? _profileImagePath; // NEW: To store the selected image path

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _notesController = TextEditingController(text: widget.customer?.notes ?? ''); // NEW: Init notes
    _profileImagePath = widget.customer?.profileImagePath; // NEW: Init image path
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose(); // NEW: Dispose notes controller
    super.dispose();
  }

  // NEW: Image picking method
// NEW: Image picking method
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // On web, we can't pick local files easily
      // Use a placeholder or implement web image picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image upload not supported on web. Use mobile app for this feature.'),
        ),
      );
      return;
    }
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      _formKey.currentState!.save();

      if (_isEditing) {
        widget.customer!.name = _nameController.text;
        widget.customer!.phone = _phoneController.text;
        widget.customer!.address = _addressController.text;
        widget.customer!.notes = _notesController.text.isNotEmpty ? _notesController.text : null; // NEW: Save notes
        widget.customer!.profileImagePath = _profileImagePath; // NEW: Save image path
        await appState.updateCustomer(widget.customer!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer ${widget.customer!.name} updated!')),
        );
      } else {
        final newCustomer = Customer(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null, // NEW: Save notes
          profileImagePath: _profileImagePath, // NEW: Save image path
        );
        try {
          await appState.addCustomer(newCustomer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer ${newCustomer.name} added!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
          if (e.toString().contains('Upgrade')) {
            // Optionally navigate to Subscription/Upgrade screen
          }
          return;
        }
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!_isEditing && !appState.isPremiumUser)
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
              // NEW: Profile Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: _profileImagePath != null
                        ? FileImage(File(_profileImagePath!))
                        : null,
                    child: _profileImagePath == null
                        ? Icon(Icons.camera_alt, size: 40, color: Theme.of(context).primaryColor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
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
              const SizedBox(height: 16.0),
              // NEW: Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Customer Notes (Optional)',
                  hintText: 'e.g., Prefers slim fit, sensitive to fabric type',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                minLines: 1,
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