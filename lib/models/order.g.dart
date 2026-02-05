// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 1;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      customerId: fields[0] as String,
      measurementId: fields[1] as String,
      deliveryDate: fields[2] as DateTime,
      status: fields[3] as String,
      totalPrice: fields[4] as double,
      advancePayment: fields[5] as double,
      remainingPayment: fields[6] as double,
      trackingNumber: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.customerId)
      ..writeByte(1)
      ..write(obj.measurementId)
      ..writeByte(2)
      ..write(obj.deliveryDate)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.totalPrice)
      ..writeByte(5)
      ..write(obj.advancePayment)
      ..writeByte(6)
      ..write(obj.remainingPayment)
      ..writeByte(7)
      ..write(obj.trackingNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
