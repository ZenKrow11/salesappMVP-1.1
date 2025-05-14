import 'package:hive/hive.dart';
import 'product.dart';

part 'named_list.g.dart';

@HiveType(typeId: 1)
class NamedList extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<Product> items;

  @HiveField(2)
  final int index;

  NamedList({
    required this.name,
    required this.items,
    required this.index,
  });

  NamedList copyWith({
    String? name,
    List<Product>? items,
    int? index,
  }) {
    return NamedList(
      name: name ?? this.name,
      items: items ?? this.items,
      index: index ?? this.index,
    );
  }
}
