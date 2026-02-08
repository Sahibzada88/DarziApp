import 'package:hive/hive.dart';

part 'measurement.g.dart';

@HiveType(typeId: 2)
class Measurement extends HiveObject {
  @HiveField(0)
  late String customerId;

  @HiveField(1)
  late String type;

  @HiveField(2)
  late Map<String, double> values;

  @HiveField(3) // NEW: Timestamp for measurement history
  late DateTime createdAt;

  Measurement({
    required this.customerId,
    required this.type,
    required this.values,
    DateTime? createdAt, // Optional in constructor, default to now
  }) : this.createdAt = createdAt ?? DateTime.now(); // Initialize if not provided
}