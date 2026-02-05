// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionInfoAdapter extends TypeAdapter<SubscriptionInfo> {
  @override
  final int typeId = 3;

  @override
  SubscriptionInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionInfo(
      isSubscribed: fields[0] as bool,
      trialStartDate: fields[1] as DateTime?,
      hasUsedTrial: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.isSubscribed)
      ..writeByte(1)
      ..write(obj.trialStartDate)
      ..writeByte(2)
      ..write(obj.hasUsedTrial);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
