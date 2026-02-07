import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import '../models/customer.dart';
// import '../models/measurement.dart';
import '../models/order.dart';
import '../main.dart'; // Import AppState

class AddEditOrderScreen extends StatefulWidget {
  final Order? order;

  const AddEditOrderScreen({Key? key, this.order}) : super(key: key);

  @override
  State<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  String? _selectedMeasurementId;
  DateTime _selectedDeliveryDate = DateTime.now();
  String _selectedStatus = 'Cutting';

  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _advancePaymentController = TextEditingController();
  final TextEditingController _remainingPaymentController = TextEditingController();
  final TextEditingController _trackingNumberController = TextEditingController(); // NEW: Tracking number controller

  final List<String> _orderStatuses = ['Cutting', 'Stitching', 'Ready', 'Delivered'];

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedCustomerId = widget.order!.customerId;
      _selectedMeasurementId = widget.order!.measurementId;
      _selectedDeliveryDate = widget.order!.deliveryDate;
      _selectedStatus = widget.order!.status;
      _totalPriceController.text = widget.order!.totalPrice.toStringAsFixed(2);
      _advancePaymentController.text = widget.order!.advancePayment.toStringAsFixed(2);
      _remainingPaymentController.text = widget.order!.remainingPayment.toStringAsFixed(2);
      _trackingNumberController.text = widget.order!.trackingNumber ?? ''; // NEW: Initialize tracking number
    } else {
      _totalPriceController.addListener(_updateRemainingPayment);
      _advancePaymentController.addListener(_updateRemainingPayment);
    }
  }

  @override
  void dispose() {
    _totalPriceController.removeListener(_updateRemainingPayment);
    _advancePaymentController.removeListener(_updateRemainingPayment);
    _totalPriceController.dispose();
    _advancePaymentController.dispose();
    _remainingPaymentController.dispose();
    _trackingNumberController.dispose(); // NEW: Dispose tracking number controller
    super.dispose();
  }

  void _updateRemainingPayment() {
    final total = double.tryParse(_totalPriceController.text) ?? 0.0;
    final advance = double.tryParse(_advancePaymentController.text) ?? 0.0;
    setState(() {
      _remainingPaymentController.text = (total - advance).toStringAsFixed(2);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years from now
    );
    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      _formKey.currentState!.save();

      final totalPrice = double.tryParse(_totalPriceController.text) ?? 0.0;
      final advancePayment = double.tryParse(_advancePaymentController.text) ?? 0.0;
      final remainingPayment = double.tryParse(_remainingPaymentController.text) ?? 0.0;
      final trackingNumber = _trackingNumberController.text.trim().isEmpty ? null : _trackingNumberController.text.trim(); // NEW

      if (_isEditing) {
        widget.order!.customerId = _selectedCustomerId!;
        widget.order!.measurementId = _selectedMeasurementId!;
        widget.order!.deliveryDate = _selectedDeliveryDate;
        widget.order!.status = _selectedStatus;
        widget.order!.totalPrice = totalPrice;
        widget.order!.advancePayment = advancePayment;
        widget.order!.remainingPayment = remainingPayment;
        widget.order!.trackingNumber = trackingNumber; // NEW: Update tracking number
        await appState.updateOrder(widget.order!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated for ${appState.getCustomerById(_selectedCustomerId!)?.name ?? ''}!')),
        );
      } else {
        final newOrder = Order(
          customerId: _selectedCustomerId!,
          measurementId: _selectedMeasurementId!,
          deliveryDate: _selectedDeliveryDate,
          status: _selectedStatus,
          totalPrice: totalPrice,
          advancePayment: advancePayment,
          remainingPayment: remainingPayment,
          trackingNumber: trackingNumber, // NEW: Add tracking number
        );
        try {
          await appState.addOrder(newOrder);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order added for ${appState.getCustomerById(_selectedCustomerId!)?.name ?? ''}!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
          return;
        }
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final customers = appState.customers;
    final measurements = appState.measurements;

    final customerMeasurements = _selectedCustomerId != null
        ? measurements.where((m) => m.customerId == _selectedCustomerId).toList()
        : [];

    if (!_isEditing && _selectedCustomerId == null && customers.isNotEmpty) {
      _selectedCustomerId = customers.first.key.toString();
    }
    if (!_isEditing && _selectedMeasurementId == null && customerMeasurements.isNotEmpty) {
      _selectedMeasurementId = customerMeasurements.first.key.toString(); // ERROR FIX: Access first item in list
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Order' : 'Add Order'),
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
                  color: appState.orderCount >= AppState.maxFreeOrders ? Colors.red[50] : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      appState.orderLimitMessage,
                      style: TextStyle(
                        color: appState.orderCount >= AppState.maxFreeOrders ? Colors.red[800] : Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              // Customer Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Customer',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                value: _selectedCustomerId,
                hint: const Text('Choose a customer'),
                items: customers.map((customer) {
                  return DropdownMenuItem<String>(
                    value: customer.key.toString(),
                    child: Text(customer.name),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCustomerId = newValue;
                    _selectedMeasurementId = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a customer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Measurement Selection (filtered by customer)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Measurement',
                  prefixIcon: Icon(Icons.straighten),
                ),
                value: _selectedMeasurementId,
                hint: Text(
                  _selectedCustomerId == null
                      ? 'Select a customer first'
                      : (customerMeasurements.isEmpty ? 'No measurements for this customer' : 'Choose a measurement'),
                ),
                items: customerMeasurements.map((measurement) {
                  return DropdownMenuItem<String>(
                    value: measurement.key.toString(),
                    child: Text('${measurement.type} (ID: ${measurement.key})'),
                  );
                }).toList(),
                onChanged: customerMeasurements.isEmpty ? null : (newValue) {
                  setState(() {
                    _selectedMeasurementId = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a measurement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Delivery Date Picker
              ListTile(
                title: Text(
                  'Delivery Date: ${DateFormat('dd MMM yyyy').format(_selectedDeliveryDate)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16.0),
              // Order Status Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Order Status',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                value: _selectedStatus,
                items: _orderStatuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an order status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // NEW: Tracking Number Field
              TextFormField(
                controller: _trackingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number (Optional)',
                  hintText: 'e.g., ORD-001-A',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16.0),
              // Price Fields
              TextFormField(
                controller: _totalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Total Price (PKR)',
                  prefixIcon: Icon(Icons.payments),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _advancePaymentController,
                decoration: const InputDecoration(
                  labelText: 'Advance Payment (PKR)',
                  prefixIcon: Icon(Icons.arrow_downward),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter advance payment';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _remainingPaymentController,
                decoration: const InputDecoration(
                  labelText: 'Remaining Payment (PKR)',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
                enabled: false,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: _saveOrder,
                icon: Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Save Order' : 'Add Order'),
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