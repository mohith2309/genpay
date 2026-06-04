// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PayeeAdapter extends TypeAdapter<Payee> {
  @override
  final int typeId = 3;

  @override
  Payee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payee(
      id: fields[0] as String,
      name: fields[1] as String,
      upiId: fields[2] as String,
      phone: fields[3] as String?,
      lastPaid: fields[4] as DateTime?,
      avatarColor: fields[5] as int,
      totalPaid: fields[6] as double,
      payCount: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Payee obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.upiId)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.lastPaid)
      ..writeByte(5)
      ..write(obj.avatarColor)
      ..writeByte(6)
      ..write(obj.totalPaid)
      ..writeByte(7)
      ..write(obj.payCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
