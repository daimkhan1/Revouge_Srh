// Location: lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import '../data/cart_provider.dart';
import 'mock_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    globalCart.addListener(_update);
  }

  @override
  void dispose() {
    globalCart.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if(mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: globalCart.items.isEmpty
          ? const Center(child: Text("Cart is Empty"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: globalCart.items.length,
              itemBuilder: (ctx, i) {
                final product = globalCart.items[i];
                return ListTile(
                  title: Text(product.title),
                  subtitle: Text("€${product.price}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => globalCart.removeItem(product),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const MockPaymentScreen()),
                  );
                },
                child: const Text("CHECKOUT", style: TextStyle(color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
