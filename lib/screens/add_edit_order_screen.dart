import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/order_item.dart'; // NEW: OrderItem model
import '../main.dart';
import '../models/measurement.dart'; // Needed to display measurement details

class AddEditOrderScreen extends StatefulWidget {
  final Order? order;
  final String? initialCustomerId; // NEW: To pre-select customer

  const AddEditOrderScreen({Key? key, this.order, this.initialCustomerId}) : super(key: key);

  @override
  State<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  DateTime _selectedDeliveryDate = DateTime.now();
  String _selectedStatus = 'Cutting';

  final TextEditingController _advancePaymentController = TextEditingController();
  final TextEditingController _trackingNumberController = TextEditingController();

  List<OrderItem> _orderItems = []; // NEW: List of order items

  final List<String> _orderStatuses = ['Cutting', 'Stitching', 'Ready', 'Delivered'];
  final List<String> _garmentTypes = ['Gents Qameez', 'Gents Shalwar', 'Ladies Shirt', 'Ladies Trouser', 'Ladies Dupatta', 'Custom']; // Sample garment types

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedCustomerId = widget.order!.customerId;
      _selectedDeliveryDate = widget.order!.deliveryDate;
      _selectedStatus = widget.order!.status;
      _advancePaymentController.text = widget.order!.advancePayment.toStringAsFixed(2);
      _trackingNumberController.text = widget.order!.trackingNumber ?? '';
      _orderItems = List.from(widget.order!.items); // Copy existing items
    } else {
      _selectedCustomerId = widget.initialCustomerId; // NEW: Set initial customer
      _orderItems.add(OrderItem(garmentType: _garmentTypes.first, itemPrice: 0.0, quantity: 1)); // Add a default item
    }
    _advancePaymentController.addListener(_updatePayments);
  }

  @override
  void dispose() {
    _advancePaymentController.removeListener(_updatePayments);
    _advancePaymentController.dispose();
    _trackingNumberController.dispose();
    super.dispose();
  }

  void _updatePayments() {
    setState(() {}); // Rebuild to update calculated total and remaining
  }

  double get _calculatedTotalPrice {
    return _orderItems.fold(0.0, (sum, item) => sum + item.totalItemPrice);
  }

  double get _calculatedRemainingPayment {
    final total = _calculatedTotalPrice;
    final advance = double.tryParse(_advancePaymentController.text) ?? 0.0;
    return total - advance;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  void _addOrderItem() {
    setState(() {
      _orderItems.add(OrderItem(garmentType: _garmentTypes.first, itemPrice: 0.0, quantity: 1));
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  Future<void> _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      _formKey.currentState!.save();

      if (_orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one order item.')),
        );
        return;
      }

      final advancePayment = double.tryParse(_advancePaymentController.text) ?? 0.0;
      final trackingNumber = _trackingNumberController.text.trim().isEmpty ? null : _trackingNumberController.text.trim();

      if (_isEditing) {
        widget.order!.customerId = _selectedCustomerId!;
        widget.order!.deliveryDate = _selectedDeliveryDate;
        widget.order!.status = _selectedStatus;
        widget.order!.advancePayment = advancePayment;
        widget.order!.trackingNumber = trackingNumber;
        widget.order!.items = _orderItems; // Update items list
        // totalPrice and remainingPayment are calculated in AppState.updateOrder
        await appState.updateOrder(widget.order!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated for ${appState.getCustomerById(_selectedCustomerId!)?.name ?? ''}!')),
        );
      } else {
        final newOrder = Order(
          customerId: _selectedCustomerId!,
          deliveryDate: _selectedDeliveryDate,
          status: _selectedStatus,
          totalPrice: _calculatedTotalPrice, // Initial total price for new order
          advancePayment: advancePayment,
          remainingPayment: _calculatedRemainingPayment, // Initial remaining
          trackingNumber: trackingNumber,
          items: _orderItems, // Add items list
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

    // Ensure a customer is selected if not editing and there are customers
    if (!_isEditing && _selectedCustomerId == null && customers.isNotEmpty) {
      _selectedCustomerId = customers.first.key.toString();
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
              TextFormField(
                controller: _trackingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number (Optional)',
                  hintText: 'e.g., ORD-001-A',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 24.0),
              // NEW: Order Items Section
              Text(
                'Order Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16.0),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orderItems.length,
                itemBuilder: (context, index) {
                  final item = _orderItems[index];
                  final customerMeasurements = _selectedCustomerId != null
                      ? appState.getMeasurementsForCustomer(_selectedCustomerId!)
                      : <Measurement>[];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Garment Type',
                                    prefixIcon: Icon(Icons.style),
                                  ),
                                  value: item.garmentType,
                                  items: _garmentTypes.map((type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      item.garmentType = newValue!;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select garment type';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_orderItems.length > 1) // Only show remove if more than one item
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeOrderItem(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Measurement (Optional)',
                              prefixIcon: Icon(Icons.straighten),
                            ),
                            value: item.measurementKey,
                            hint: Text(
                              _selectedCustomerId == null
                                  ? 'Select customer first'
                                  : (customerMeasurements.isEmpty ? 'No measurements' : 'Choose measurement'),
                            ),
                            items: customerMeasurements.map((measurement) {
                              return DropdownMenuItem<String>(
                                value: measurement.key.toString(),
                                child: Text('${measurement.type} (ID: ${measurement.key}) - ${DateFormat('dd MMM yyyy').format(measurement.createdAt)}'),
                              );
                            }).toList(),
                            onChanged: customerMeasurements.isEmpty ? null : (newValue) {
                              setState(() {
                                item.measurementKey = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            initialValue: item.itemPrice.toStringAsFixed(2),
                            decoration: const InputDecoration(
                              labelText: 'Item Price (PKR)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              setState(() {
                                item.itemPrice = double.tryParse(value) ?? 0.0;
                                _updatePayments();
                              });
                            },
                            validator: (value) {
                              if (value == null || double.tryParse(value) == null) {
                                return 'Enter valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            initialValue: item.quantity.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                item.quantity = int.tryParse(value) ?? 1;
                                _updatePayments();
                              });
                            },
                            validator: (value) {
                              if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'Enter valid quantity';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            initialValue: item.specialInstructions,
                            decoration: const InputDecoration(
                              labelText: 'Special Instructions (Optional)',
                              prefixIcon: Icon(Icons.text_fields),
                            ),
                            maxLines: 2,
                            onChanged: (value) {
                              setState(() {
                                item.specialInstructions = value.isEmpty ? null : value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addOrderItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Item'),
                ),
              ),
              const SizedBox(height: 24.0),
              // Payment Summary
              Text(
                'Payment Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
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
              ListTile(
                tileColor: Theme.of(context).cardTheme.color,
                title: Text(
                  'Total Order Price:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Text(
                  'PKR ${_calculatedTotalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                tileColor: Theme.of(context).cardTheme.color,
                title: Text(
                  'Remaining Payment:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Text(
                  'PKR ${_calculatedRemainingPayment.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _calculatedRemainingPayment > 0 ? Colors.red : Colors.green),
                ),
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