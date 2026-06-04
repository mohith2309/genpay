// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      merchant: fields[2] as String,
      category: fields[3] as String,
      subcategory: fields[4] as String?,
      date: fields[5] as DateTime,
      isSilent: fields[6] as bool,
      mood: fields[7] as String?,
      isRecurring: fields[8] as bool,
      note: fields[9] as String?,
      fromSms: fields[10] as bool,
      isApproved: fields[11] as bool,
      vaultSaved: fields[12] as double,
      paymentMethod: fields[13] as String,
      isEmotionalSpend: fields[14] as bool,
      upiId: fields[15] as String?,
      upiApp: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.merchant)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.subcategory)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.isSilent)
      ..writeByte(7)
      ..write(obj.mood)
      ..writeByte(8)
      ..write(obj.isRecurring)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.fromSms)
      ..writeByte(11)
      ..write(obj.isApproved)
      ..writeByte(12)
      ..write(obj.vaultSaved)
      ..writeByte(13)
      ..write(obj.paymentMethod)
      ..writeByte(14)
      ..write(obj.isEmotionalSpend)
      ..writeByte(15)
      ..write(obj.upiId)
      ..writeByte(16)
      ..write(obj.upiApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
