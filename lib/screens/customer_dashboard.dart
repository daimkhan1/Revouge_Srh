// Location: lib/screens/customer_dashboard.dart
import 'package:flutter/material.dart';
import '../data/cart_provider.dart';
import '../data/payment_methods_store.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

class CustomerDashboard extends StatefulWidget {
  final String? customerName;
  const CustomerDashboard({super.key, this.customerName});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  @override
  void initState() {
    super.initState();
    globalPaymentMethods.addListener(_refresh);
    globalCart.addListener(_refresh);
  }

  @override
  void dispose() {
    globalPaymentMethods.removeListener(_refresh);
    globalCart.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customerName ?? 'Customer';
    final defaultMethod = globalPaymentMethods.defaultMethod;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Customer Dashboard - $name'),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('Checkout'),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cart items: ${globalCart.itemCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  defaultMethod == null
                      ? 'No payment method on file'
                      : 'Default payment: ${defaultMethod.label} (${defaultMethod.detail})',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                        },
                        child: const Text('View Cart', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9AAE)),
                        onPressed: globalCart.itemCount == 0
                            ? null
                            : () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                              },
                        child: const Text('Checkout', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Payment Methods'),
          _glassCard(
            child: Column(
              children: [
                if (globalPaymentMethods.methods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No payment methods yet. Add one below.'),
                  ),
                for (final method in globalPaymentMethods.methods)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _iconFor(method.type),
                    title: Text(method.label),
                    subtitle: Text(method.detail),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: method.id,
                          groupValue: globalPaymentMethods.defaultId,
                          onChanged: (v) {
                            if (v != null) globalPaymentMethods.setDefault(v);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => globalPaymentMethods.removeMethod(method.id),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddPaymentMethod(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _iconFor(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.card:
        return const Icon(Icons.credit_card, color: Colors.black);
      case PaymentMethodType.paypal:
        return const Icon(Icons.account_balance_wallet, color: Colors.blue);
      case PaymentMethodType.bank:
        return const Icon(Icons.account_balance, color: Colors.green);
    }
  }

  void _showAddPaymentMethod(BuildContext context) {
    final label = TextEditingController();
    final detail = TextEditingController();
    PaymentMethodType type = PaymentMethodType.card;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethodType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: PaymentMethodType.card, child: Text('Card')),
                  DropdownMenuItem(value: PaymentMethodType.paypal, child: Text('PayPal')),
                  DropdownMenuItem(value: PaymentMethodType.bank, child: Text('Bank Transfer')),
                ],
                onChanged: (v) {
                  if (v != null) type = v;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: label,
                decoration: const InputDecoration(labelText: 'Label (e.g., Visa)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detail,
                decoration: const InputDecoration(labelText: 'Detail (e.g., •••• 1234)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    if (label.text.trim().isEmpty || detail.text.trim().isEmpty) return;
                    globalPaymentMethods.addMethod(
                      label: label.text,
                      detail: detail.text,
                      type: type,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
