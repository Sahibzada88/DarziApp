import 'package:hive/hive.dart';

part 'order.g.dart';

@HiveType(typeId: 1)
class Order extends HiveObject {
  @HiveField(0)
  late String customerId;

  @HiveField(1)
  late String measurementId;

  @HiveField(2)
  late DateTime deliveryDate;

  @HiveField(3)
  late String status;

  @HiveField(4)
  late double totalPrice;

  @HiveField(5)
  late double advancePayment;

  @HiveField(6)
  late double remainingPayment;

  @HiveField(7) // NEW: Add tracking number
  late String? trackingNumber; // Made nullable for existing orders or optional

  Order({
    required this.customerId,
    required this.measurementId,
    required this.deliveryDate,
    required this.status,
    required this.totalPrice,
    required this.advancePayment,
    required this.remainingPayment,
    this.trackingNumber, // Add to constructor
  });
}