import 'package:hive/hive.dart';

part 'payee.g.dart';

@HiveType(typeId: 3)
class Payee extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String upiId;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  DateTime? lastPaid;

  @HiveField(5)
  int avatarColor;

  @HiveField(6)
  double totalPaid;

  @HiveField(7)
  int payCount;

  Payee({
    required this.id,
    required this.name,
    required this.upiId,
    this.phone,
    this.lastPaid,
    this.avatarColor = 0xFF00D9FF,
    this.totalPaid = 0.0,
    this.payCount = 0,
  });

  /// Two-letter initials for the avatar circle.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Payee copyWith({
    String? name,
    String? upiId,
    String? phone,
    DateTime? lastPaid,
    int? avatarColor,
    double? totalPaid,
    int? payCount,
  }) {
    return Payee(
      id: id,
      name: name ?? this.name,
      upiId: upiId ?? this.upiId,
      phone: phone ?? this.phone,
      lastPaid: lastPaid ?? this.lastPaid,
      avatarColor: avatarColor ?? this.avatarColor,
      totalPaid: totalPaid ?? this.totalPaid,
      payCount: payCount ?? this.payCount,
    );
  }
}
