// =============================================================================
// CART PROVIDER - FINAL SIMPLIFIED VERSION
// =============================================================================
// Location: lib/data/cart_provider.dart
// Purpose: Simple cart logic using a Global Variable for easy access
// =============================================================================

import 'package:flutter/material.dart';
import '../models/product.dart';

// -----------------------------------------------------------------------------
// 1. GLOBAL VARIABLE
// This is the magic line that fixes "Undefined name 'globalCart'" errors.
// It creates one cart that the whole app can share.
// -----------------------------------------------------------------------------
final globalCart = CartProvider();

// -----------------------------------------------------------------------------
// 2. THE LOGIC CLASS
// -----------------------------------------------------------------------------
class CartProvider extends ChangeNotifier {
  // We use a simple list of Products. No complex 'CartItem' needed for the demo.
  final List<Product> _items = [];

  // Getters
  List<Product> get items => _items;
  int get itemCount => _items.length;

  /// Calculate total price of all items in the cart
  double get totalAmount {
    var total = 0.0;
    for (var item in _items) {
      total += item.price;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  /// Add a product to the cart
  void addItem(Product product) {
    _items.add(product);
    // This tells Flutter to refresh the screens (update the red badge)
    notifyListeners();
  }

  /// Remove a specific product from the cart
  void removeItem(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  /// Clear the cart (used after checkout)
  void clear() {
    _items.clear();
    notifyListeners();
  }
}