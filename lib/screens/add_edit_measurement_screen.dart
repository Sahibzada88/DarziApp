import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import '../models/customer.dart';
import '../models/measurement.dart';
import '../main.dart'; // Import AppState

class AddEditMeasurementScreen extends StatefulWidget {
  final Measurement? measurement;

  const AddEditMeasurementScreen({Key? key, this.measurement}) : super(key: key);

  @override
  State<AddEditMeasurementScreen> createState() => _AddEditMeasurementScreenState();
}

class _AddEditMeasurementScreenState extends State<AddEditMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  String _selectedMeasurementType = 'Gents Qameez'; // Default type
  final Map<String, TextEditingController> _measurementControllers = {};

  bool get _isEditing => widget.measurement != null;

  // Define default measurement fields for Gents and Ladies
  final Map<String, List<String>> _measurementTemplates = {
    'Gents Qameez': ['Length', 'Chest', 'Shoulder', 'Sleeve', 'Collar', 'Waist', 'Hip'],
    'Gents Shalwar': ['Length', 'Hip', 'Bottom'],
    'Ladies Shirt': ['Length', 'Chest', 'Shoulder', 'Sleeve', 'Neck', 'Waist', 'Hip'],
    'Ladies Trouser': ['Length', 'Waist', 'Hip', 'Bottom'],
    'Ladies Dupatta': ['Length', 'Width'],
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedCustomerId = widget.measurement!.customerId;
      _selectedMeasurementType = widget.measurement!.type;
      widget.measurement!.values.forEach((key, value) {
        _measurementControllers[key] = TextEditingController(text: value.toString());
      });
    } else {
      // Initialize controllers for the default type when adding
      _measurementTemplates[_selectedMeasurementType]?.forEach((field) {
        _measurementControllers[field] = TextEditingController();
      });
    }
  }

  @override
  void dispose() {
    _measurementControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _updateMeasurementFields(String? newType) {
    if (newType == null || newType == _selectedMeasurementType) return;

    setState(() {
      _selectedMeasurementType = newType;
      _measurementControllers.clear(); // Clear old controllers
      _measurementTemplates[_selectedMeasurementType]?.forEach((field) {
        _measurementControllers[field] = TextEditingController(); // Create new ones
      });
    });
  }

  Future<void> _saveMeasurement() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      _formKey.currentState!.save();

      final Map<String, double> values = {};
      _measurementControllers.forEach((field, controller) {
        values[field] = double.tryParse(controller.text) ?? 0.0;
      });

      if (_isEditing) {
        widget.measurement!.customerId = _selectedCustomerId!;
        widget.measurement!.type = _selectedMeasurementType;
        widget.measurement!.values = values;
        await appState.updateMeasurement(widget.measurement!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Measurement updated for ${appState.getCustomerById(_selectedCustomerId!)?.name ?? ''}!')),
        );
      } else {
        final newMeasurement = Measurement(
          customerId: _selectedCustomerId!,
          type: _selectedMeasurementType,
          values: values,
        );
        try {
          await appState.addMeasurement(newMeasurement);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Measurement added for ${appState.getCustomerById(_selectedCustomerId!)?.name ?? ''}!')),
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
        title: Text(_isEditing ? 'Edit Measurement' : 'Add Measurement'),
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
                  color: appState.measurementCount >= AppState.maxFreeMeasurements ? Colors.red[50] : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      appState.measurementLimitMessage,
                      style: TextStyle(
                        color: appState.measurementCount >= AppState.maxFreeMeasurements ? Colors.red[800] : Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              // Customer selection
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
              // Measurement type selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Measurement Type',
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedMeasurementType,
                items: _measurementTemplates.keys.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _updateMeasurementFields,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a measurement type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              Text(
                'Enter Measurements (in inches)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16.0),
              // Dynamic measurement fields based on selected type
              ...(_measurementTemplates[_selectedMeasurementType] ?? []).map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    controller: _measurementControllers[field],
                    decoration: InputDecoration(
                      labelText: field,
                      hintText: 'e.g., 20.5',
                      prefixIcon: const Icon(Icons.straighten),
                      suffixText: 'inches',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter $field';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: _saveMeasurement,
                icon: Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Save Measurement' : 'Add Measurement'),
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