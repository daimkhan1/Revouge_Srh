// Location: lib/data/order_store.dart
import 'package:flutter/material.dart';

enum OrderStatus {
  placed,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
}

class OrderHistoryItem {
  final String id;
  final DateTime date;
  final int itemCount;
  final double total;
  OrderStatus status;
  final String trackingId;

  OrderHistoryItem({
    required this.id,
    required this.date,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.trackingId,
  });
}

final globalOrderHistory = OrderHistoryStore();

class OrderHistoryStore extends ChangeNotifier {
  final List<OrderHistoryItem> _orders = [];

  OrderHistoryStore() {
    _seed();
  }

  List<OrderHistoryItem> get orders => List.unmodifiable(_orders);

  void addOrder({required int itemCount, required double total}) {
    final id = 'RVG-${DateTime.now().millisecondsSinceEpoch}';
    _orders.insert(
      0,
      OrderHistoryItem(
        id: id,
        date: DateTime.now(),
        itemCount: itemCount,
        total: total,
        status: OrderStatus.placed,
        trackingId: 'TRK-${DateTime.now().microsecondsSinceEpoch % 1000000}',
      ),
    );
    notifyListeners();
  }

  void advanceStatus(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) return;
    final current = _orders[index].status.index;
    if (current < OrderStatus.values.length - 1) {
      _orders[index].status = OrderStatus.values[current + 1];
      notifyListeners();
    }
  }

  void _seed() {
    _orders.addAll([
      OrderHistoryItem(
        id: 'RVG-100023',
        date: DateTime.now().subtract(const Duration(days: 6)),
        itemCount: 2,
        total: 64.50,
        status: OrderStatus.delivered,
        trackingId: 'TRK-384920',
      ),
      OrderHistoryItem(
        id: 'RVG-100019',
        date: DateTime.now().subtract(const Duration(days: 12)),
        itemCount: 1,
        total: 28.00,
        status: OrderStatus.shipped,
        trackingId: 'TRK-102938',
      ),
    ]);
  }
}
