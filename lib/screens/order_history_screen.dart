// Location: lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import '../data/order_store.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    globalOrderHistory.addListener(_refresh);
  }

  @override
  void dispose() {
    globalOrderHistory.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final orders = globalOrderHistory.orders;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _glassCard(
            child: Column(
              children: [
                if (orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No orders yet.'),
                  ),
                for (final o in orders)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(o.id, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_subtitle(o)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(OrderHistoryItem order) {
    final date = '${order.date.day}/${order.date.month}/${order.date.year}';
    return '$date • ${order.itemCount} item${order.itemCount == 1 ? '' : 's'} • €${order.total.toStringAsFixed(2)}';
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
}

class OrderDetailScreen extends StatelessWidget {
  final OrderHistoryItem order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    final currentIndex = order.status.index;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Order Detail'),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Tracking ID: ${order.trackingId}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                Text('Items: ${order.itemCount}'),
                Text('Total: €${order.total.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++)
                  _StepRow(
                    title: steps[i],
                    isDone: i <= currentIndex,
                    isLast: i == steps.length - 1,
                  ),
                const SizedBox(height: 12),
                if (order.status != OrderStatus.delivered)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        globalOrderHistory.advanceStatus(order.id);
                      },
                      child: const Text('Advance Status (Mock)'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _steps() {
    return const [
      'Order placed',
      'Confirmed',
      'Packed',
      'Shipped',
      'Out for delivery',
      'Delivered',
    ];
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
}

class _StepRow extends StatelessWidget {
  final String title;
  final bool isDone;
  final bool isLast;

  const _StepRow({
    required this.title,
    required this.isDone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : Colors.black38,
              size: 18,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDone ? Colors.green : Colors.black26,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(title),
          ),
        ),
      ],
    );
  }
}
