// Location: lib/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/mock_data.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatelessWidget {
  final String category;

  const ProductListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Get products using the helper from mock_data
    // If no products match the specific category, we show all products (for demo purposes)
    // to ensure the screen isn't empty during your presentation.
    List<Product> displayProducts = getProductsByCategory(category);
    if (displayProducts.isEmpty) {
      displayProducts = products;
    }

    return Scaffold(
      // Transparent background so the global Revouge.jpg shows through
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Semi-transparent white to keep text readable but show background
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: displayProducts.isEmpty
          ? const Center(
        child: Text(
            "No items found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70, // Adjusted to prevent overflow on smaller screens
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: displayProducts.length,
        itemBuilder: (context, index) {
          final product = displayProducts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
            // We don't need a container here because ProductCard now handles
            // its own decoration and transparency.
            child: ProductCard(product: product),
          );
        },
      ),
    );
  }
}