// =============================================================================
// PRODUCT MODEL - UPDATED FOR REVOUGE
// =============================================================================
// Location: lib/models/product.dart
// Purpose: Defines the structure of a fashion product with Title and Size
// =============================================================================

class Product {
  final String id;
  final String title;       // Changed from 'name'
  final String category;
  final double price;
  final String imageUrl;
  final String condition;
  final double distance;    // Distance in km
  final String description; // Required now
  final String size;        // Added new field

  Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.condition,
    required this.distance,
    required this.description,
    required this.size,
  });

  // =============================================================================
  // HELPER METHODS (For UI)
  // =============================================================================

  /// Returns formatted price (e.g., €15.00)
  String get formattedPrice {
    return '€${price.toStringAsFixed(2)}';
  }

  /// Returns shortened distance (e.g., "800 m" or "1.2 km")
  String get distanceDisplay {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// UI Color Helper
  String get conditionColor {
    switch (condition) {
      case 'New with Tags':
        return 'green';
      case 'Like New':
        return 'blue';
      case 'Good':
        return 'orange';
      case 'Fair':
        return 'amber';
      default:
        return 'grey';
    }
  }

  // =============================================================================
  // JSON SERIALIZATION (Updated for Title & Size)
  // =============================================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'condition': condition,
      'distance': distance,
      'description': description,
      'size': size,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      condition: json['condition'] as String,
      distance: (json['distance'] as num).toDouble(),
      description: json['description'] as String,
      size: json['size'] as String,
    );
  }
}