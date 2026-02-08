import 'package:hive/hive.dart';
import 'order_item.dart'; // NEW: Import OrderItem

part 'order.g.dart';

@HiveType(typeId: 1)
class Order extends HiveObject {
  @HiveField(0)
  late String customerId;

  // @HiveField(1) // Removed, replaced by items with individual measurement keys
  // late String measurementId;

  @HiveField(1) // Renumbered fields after removal
  late DateTime deliveryDate;

  @HiveField(2) // Renumbered
  late String status;

  @HiveField(3) // Renumbered
  late double totalPrice; // This will now be a calculated sum of order items

  @HiveField(4) // Renumbered
  late double advancePayment;

  @HiveField(5) // Renumbered
  late double remainingPayment;

  @HiveField(6) // Renumbered
  late String? trackingNumber;

  @HiveField(7) // NEW: List of order items
  late List<OrderItem> items;

  Order({
    required this.customerId,
    // measurementId removed from constructor
    required this.deliveryDate,
    required this.status,
    required this.totalPrice, // Still required for initial setting or display
    required this.advancePayment,
    required this.remainingPayment,
    this.trackingNumber,
    List<OrderItem>? items, // New optional list of items
  }) : this.items = items ?? []; // Initialize items if null
}