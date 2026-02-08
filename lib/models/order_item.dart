import 'package:hive/hive.dart';

part 'order_item.g.dart';

@HiveType(typeId: 4) // Unique ID for this type (make sure it doesn't conflict)
class OrderItem extends HiveObject {
  @HiveField(0)
  late String garmentType; // e.g., 'Gents Qameez', 'Ladies Shirt'

  @HiveField(1)
  late String? measurementKey; // Hive object key of the associated Measurement

  @HiveField(2)
  late double itemPrice;

  @HiveField(3)
  late int quantity;

  @HiveField(4)
  late String? specialInstructions; // e.g., "Slim fit, with piping"

  OrderItem({
    required this.garmentType,
    this.measurementKey,
    required this.itemPrice,
    this.quantity = 1,
    this.specialInstructions,
  });

  // Calculate total price for this item
  double get totalItemPrice => itemPrice * quantity;
}