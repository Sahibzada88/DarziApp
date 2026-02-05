import 'package:hive/hive.dart';

part 'measurement.g.dart'; // This line will be generated

@HiveType(typeId: 2) // Unique ID for this type
class Measurement extends HiveObject {
  @HiveField(0)
  late String customerId; // Link to customer

  @HiveField(1)
  late String type; // e.g., 'Gents Qameez', 'Ladies Shirt'

  @HiveField(2)
  late Map<String, double> values; // e.g., {'Chest': 20.0, 'Sleeve': 24.5}

  Measurement({required this.customerId, required this.type, required this.values});
}