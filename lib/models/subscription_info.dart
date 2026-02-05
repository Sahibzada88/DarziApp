import 'package:hive/hive.dart';

part 'subscription_info.g.dart';

@HiveType(typeId: 3)
class SubscriptionInfo extends HiveObject {
  @HiveField(0)
  late bool isSubscribed;

  @HiveField(1)
  late DateTime? trialStartDate;

  @HiveField(2)
  late bool hasUsedTrial; // To prevent giving multiple free trials

  SubscriptionInfo({
    this.isSubscribed = false,
    this.trialStartDate,
    this.hasUsedTrial = false,
  });
}