// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      store: fields[1] as String,
      name: fields[2] as String,
      currentPrice: fields[3] as double,
      normalPrice: fields[4] as double,
      discountPercentage: fields[5] as int,
      category: fields[6] as String,
      subcategory: fields[7] as String,
      url: fields[8] as String,
      imageUrl: fields[9] as String,
      nameTokens: (fields[10] as List).cast<String>(),
      availableFrom: fields[11] as DateTime?,
      sonderkondition: fields[12] as String?,
      dealEnd: fields[13] as DateTime?,
      isCustom: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.store)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.currentPrice)
      ..writeByte(4)
      ..write(obj.normalPrice)
      ..writeByte(5)
      ..write(obj.discountPercentage)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.subcategory)
      ..writeByte(8)
      ..write(obj.url)
      ..writeByte(9)
      ..write(obj.imageUrl)
      ..writeByte(10)
      ..write(obj.nameTokens)
      ..writeByte(11)
      ..write(obj.availableFrom)
      ..writeByte(12)
      ..write(obj.sonderkondition)
      ..writeByte(13)
      ..write(obj.dealEnd)
      ..writeByte(14)
      ..write(obj.isCustom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
