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
      deliveryDate: fields[1] as DateTime,
      status: fields[2] as String,
      totalPrice: fields[3] as double,
      advancePayment: fields[4] as double,
      remainingPayment: fields[5] as double,
      trackingNumber: fields[6] as String?,
      items: (fields[7] as List?)?.cast<OrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.customerId)
      ..writeByte(1)
      ..write(obj.deliveryDate)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.totalPrice)
      ..writeByte(4)
      ..write(obj.advancePayment)
      ..writeByte(5)
      ..write(obj.remainingPayment)
      ..writeByte(6)
      ..write(obj.trackingNumber)
      ..writeByte(7)
      ..write(obj.items);
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
