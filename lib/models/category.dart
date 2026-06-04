import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  @HiveField(4)
  bool isCustom;

  @HiveField(5)
  List<String> keywords;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
    this.keywords = const [],
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isCustom,
    List<String>? keywords,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCustom: isCustom ?? this.isCustom,
      keywords: keywords ?? this.keywords,
    );
  }
}
