// Location: lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import '../data/cart_provider.dart'; // To clear cart after purchase

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Transparent Background so Revouge.jpg shows through
      backgroundColor: Colors.transparent,

      // 2. Custom Transparent AppBar
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.white.withOpacity(0.8), // Semi-transparent
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),

      // 3. Centered Content with Glass Card Effect
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              // Semi-transparent white card
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with simple animation scale
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  "Payment Successful!",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                const Text(
                  "Thank you for choosing sustainable fashion.\nYour order is on its way!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5
                  ),
                ),

                const SizedBox(height: 40),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // 1. Clear the cart logic
                      globalCart.clear();

                      // 2. Navigate back to the very first screen (Home)
                      Navigator.popUntil(context, (route) => route.isFirst);

                      // 3. Show a little confirmation toast/snackbar on the Home Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Order confirmed! Continue shopping."),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                        "Back to Home",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}