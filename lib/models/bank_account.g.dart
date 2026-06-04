// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BankAccountAdapter extends TypeAdapter<BankAccount> {
  @override
  final int typeId = 4;

  @override
  BankAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankAccount(
      id: fields[0] as String,
      bankName: fields[1] as String,
      accountLast4: fields[2] as String,
      ifsc: fields[3] as String,
      balance: fields[4] as double,
      upiPin: fields[5] as String,
      isPrimary: fields[6] as bool,
      vpa: fields[7] as String,
      colorValue: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BankAccount obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.accountLast4)
      ..writeByte(3)
      ..write(obj.ifsc)
      ..writeByte(4)
      ..write(obj.balance)
      ..writeByte(5)
      ..write(obj.upiPin)
      ..writeByte(6)
      ..write(obj.isPrimary)
      ..writeByte(7)
      ..write(obj.vpa)
      ..writeByte(8)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
