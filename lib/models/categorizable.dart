// lib/models/categorizable.dart

/// An interface for any object that has category and subcategory fields.
/// This allows services to work with both Hive-backed `Product` objects
/// and isolate-friendly `PlainProduct` objects.
abstract class Categorizable {
  String get category;
  String get subcategory;
}