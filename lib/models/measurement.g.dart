// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 2;

  @override
  Measurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Measurement(
      customerId: fields[0] as String,
      type: fields[1] as String,
      values: (fields[2] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, Measurement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.customerId)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.values);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
