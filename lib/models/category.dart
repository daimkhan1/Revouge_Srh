// =============================================================================
// CATEGORY MODEL
// =============================================================================
// Location: lib/models/category.dart
// Purpose: Represents a product category (Outerwear, Footwear, Loungewear)
// =============================================================================

import 'package:flutter/material.dart';

class Category {
  final String name;
  final String? icon;
  final String? description;
  final Color? color;

  Category({
    required this.name,
    this.icon,
    this.description,
    this.color,
  }) : assert(name.isNotEmpty, 'Category name cannot be empty');

  // =============================================================================
  // PREDEFINED CATEGORIES
  // =============================================================================

  /// All products category
  static Category get all => Category(
    name: 'All',
    icon: '🏷️',
    description: 'All available products',
    color: Colors.black,
  );

  /// Outerwear category (Jackets, Coats, etc.)
  static Category get outerwear => Category(
    name: 'Outerwear',
    icon: '🧥',
    description: 'Jackets, coats, and blazers',
    color: Colors.blue,
  );

  /// Footwear category (Shoes, Sneakers, Boots)
  static Category get footwear => Category(
    name: 'Footwear',
    icon: '👟',
    description: 'Shoes, sneakers, and boots',
    color: Colors.orange,
  );

  /// Loungewear category (Hoodies, Joggers, etc.)
  static Category get loungewear => Category(
    name: 'Loungewear',
    icon: '👕',
    description: 'Hoodies, joggers, and casual wear',
    color: Colors.green,
  );

  // =============================================================================
  // STATIC HELPERS
  // =============================================================================

  /// Get all available categories
  static List<Category> getAllCategories() {
    return [all, outerwear, footwear, loungewear];
  }

  /// Get category names only (for simple lists)
  static List<String> getCategoryNames() {
    return ['All', 'Outerwear', 'Footwear', 'Loungewear'];
  }

  /// Get category by name
  static Category? fromName(String name) {
    switch (name) {
      case 'All':
        return all;
      case 'Outerwear':
        return outerwear;
      case 'Footwear':
        return footwear;
      case 'Loungewear':
        return loungewear;
      default:
        return null;
    }
  }

  /// Check if a category name is valid
  static bool isValidCategory(String name) {
    return name == 'All' ||
        name == 'Outerwear' ||
        name == 'Footwear' ||
        name == 'Loungewear';
  }

  // =============================================================================
  // FLUTTER ICON MAPPING
  // =============================================================================

  /// Get Material icon for category
  IconData get materialIcon {
    switch (name) {
      case 'All':
        return Icons.grid_view;
      case 'Outerwear':
        return Icons.checkroom;
      case 'Footwear':
        return Icons.directions_run;
      case 'Loungewear':
        return Icons.weekend;
      default:
        return Icons.category;
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Check if this is the "All" category
  bool get isAll {
    return name == 'All';
  }

  /// Get display name (same as name for now, but can be customized)
  String get displayName {
    return name;
  }

  /// Get a short description for the category
  String get shortDescription {
    return description ?? 'Browse $name products';
  }

  // =============================================================================
  // JSON SERIALIZATION (Optional - for future API integration)
  // =============================================================================

  /// Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'color': color?.value,
    };
  }

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
    );
  }

  // =============================================================================
  // EQUALITY & HASH CODE
  // =============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  // =============================================================================
  // TO STRING (for debugging)
  // =============================================================================

  @override
  String toString() {
    return 'Category(name: $name, icon: $icon)';
  }

  // =============================================================================
  // COPY WITH (for creating modified copies)
  // =============================================================================

  Category copyWith({
    String? name,
    String? icon,
    String? description,
    Color? color,
  }) {
    return Category(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }
}

// =============================================================================
// CATEGORY EXTENSIONS (Optional - for convenience)
// =============================================================================

extension CategoryListExtensions on List<Category> {
  /// Filter to get only product categories (exclude "All")
  List<Category> get productCategories {
    return where((category) => !category.isAll).toList();
  }

  /// Get category names as list of strings
  List<String> get names {
    return map((category) => category.name).toList();
  }
}