import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String phone;

  @HiveField(2)
  late String address;

  @HiveField(3) // NEW: Add notes field
  late String? notes;

  @HiveField(4) // NEW: Add profile image path
  late String? profileImagePath;

  Customer({
    required this.name,
    required this.phone,
    required this.address,
    this.notes, // Made optional
    this.profileImagePath, // Made optional
  });
}
