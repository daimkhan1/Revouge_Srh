// Location: lib/data/payment_methods_store.dart
import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String label;
  final String detail;
  final PaymentMethodType type;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.detail,
    required this.type,
  });
}

enum PaymentMethodType { card, paypal, bank }

final globalPaymentMethods = PaymentMethodStore();

class PaymentMethodStore extends ChangeNotifier {
  final List<PaymentMethod> _methods = [];
  String? _defaultId;

  PaymentMethodStore() {
    _seed();
  }

  List<PaymentMethod> get methods => List.unmodifiable(_methods);
  String? get defaultId => _defaultId;

  PaymentMethod? get defaultMethod {
    if (_defaultId == null) return null;
    for (final m in _methods) {
      if (m.id == _defaultId) return m;
    }
    return _methods.isEmpty ? null : _methods.first;
  }

  void addMethod({required String label, required String detail, required PaymentMethodType type}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _methods.add(PaymentMethod(id: id, label: label.trim(), detail: detail.trim(), type: type));
    _defaultId ??= id;
    notifyListeners();
  }

  void removeMethod(String id) {
    _methods.removeWhere((m) => m.id == id);
    if (_defaultId == id) {
      _defaultId = _methods.isEmpty ? null : _methods.first.id;
    }
    notifyListeners();
  }

  void setDefault(String id) {
    if (_methods.any((m) => m.id == id)) {
      _defaultId = id;
      notifyListeners();
    }
  }

  void _seed() {
    addMethod(
      label: 'Visa',
      detail: '•••• 4242',
      type: PaymentMethodType.card,
    );
  }
}
