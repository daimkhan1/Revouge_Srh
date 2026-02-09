// =============================================================================
// MOCK DATA - UPDATED FOR REVOUGE
// =============================================================================
// Location: lib/data/mock_data.dart
// Purpose: Sample product data used by the App
// =============================================================================

import '../models/product.dart';

// =============================================================================
// FASHION PRODUCTS LIST
// Note: We name this 'products' so the Screens can find it easily.
// =============================================================================

final List<Product> products = [
  // --- TOPS ---
  Product(
    id: 't1',
    title: 'Vintage White Tee',
    category: 'Top',
    price: 15.0,
    imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=500&q=60',
    condition: 'Good',
    distance: 1.2,
    size: 'M',
    description: 'Classic cotton t-shirt, barely worn. Great condition. Perfect for Berlin summer.\n\n• 100% Organic Cotton\n• Soft texture\n• Vintage wash',
  ),
  Product(
    id: 't2',
    title: 'Striped Blouse',
    category: 'Top',
    price: 24.50,
    imageUrl: 'https://images.unsplash.com/photo-1551163943-3f6a29e39bb7?auto=format&fit=crop&w=500&q=60',
    condition: 'Like New',
    distance: 2.5,
    size: 'S',
    description: 'Elegant striped blouse perfect for office or casual wear. Bought for an interview, worn once.\n\n• Breathable fabric\n• Button-down front',
  ),
  Product(
    id: 't3',
    title: 'Black Hoodie',
    category: 'Top',
    price: 30.0,
    imageUrl: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=500&q=60',
    condition: 'Fair',
    distance: 0.8,
    size: 'L',
    description: 'Warm and cozy hoodie. Slightly faded but very comfortable.\n\n• Fleece lined\n• Kangaroo pocket\n• Perfect for layering',
  ),

  // --- BOTTOMS ---
  Product(
    id: 'b1',
    title: 'Blue Jeans',
    category: 'Bottom',
    price: 45.0,
    imageUrl: 'https://images.unsplash.com/photo-1542272617-08f086303b94?auto=format&fit=crop&w=500&q=60',
    condition: 'New with Tags',
    distance: 3.0,
    size: '32',
    description: 'Classic denim jeans. Never worn, wrong size.\n\n• Straight fit\n• Durable denim',
  ),

  // --- SHOES ---
  Product(
    id: 's1',
    title: 'White Sneakers',
    category: 'Shoe',
    price: 55.0,
    imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=500&q=60',
    condition: 'Good',
    distance: 1.5,
    size: '42',
    description: 'Comfortable walking shoes. Good condition with minor scuffs.\n\n• Rubber sole\n• Daily wear',
  ),

  // --- BAGS ---
  Product(
    id: 'bg1',
    title: 'Leather Tote',
    category: 'Bag',
    price: 85.0,
    imageUrl: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=500&q=60',
    condition: 'Like New',
    distance: 4.2,
    size: 'One Size',
    description: 'Brown leather bag, perfect for daily use or laptop.\n\n• Genuine leather\n• Spacious interior',
  ),
];

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Get products by category
List<Product> getProductsByCategory(String category) {
  if (category == 'All') {
    return products;
  }
  // Case-insensitive comparison just in case
  return products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
}

/// Get products within a certain distance
List<Product> getNearbyProducts(double maxDistance) {
  return products.where((p) => p.distance <= maxDistance).toList();
}

/// Search products by title or description
List<Product> searchProducts(String query) {
  final lowerQuery = query.toLowerCase();
  return products.where((p) {
    return p.title.toLowerCase().contains(lowerQuery) ||
        p.description.toLowerCase().contains(lowerQuery);
  }).toList();
}

/// Get product by ID
Product? getProductById(String id) {
  try {
    return products.firstWhere((p) => p.id == id);
  } catch (e) {
    return null;
  }
}

/// Get products sorted by price (low to high)
List<Product> getProductsSortedByPrice() {
  final sorted = List<Product>.from(products);
  sorted.sort((a, b) => a.price.compareTo(b.price));
  return sorted;
}

/// Get products sorted by distance (nearest first)
List<Product> getProductsSortedByDistance() {
  final sorted = List<Product>.from(products);
  sorted.sort((a, b) => a.distance.compareTo(b.distance));
  return sorted;
}

// =============================================================================
// STATISTICS
// =============================================================================

int getTotalProductCount() => products.length;

Map<String, int> getProductCountByCategory() {
  final Map<String, int> counts = {
    'Top': 0,
    'Bottom': 0,
    'Shoe': 0,
    'Bag': 0,
  };

  for (var product in products) {
    counts[product.category] = (counts[product.category] ?? 0) + 1;
  }
  return counts;
}