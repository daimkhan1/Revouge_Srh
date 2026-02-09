// Location: lib/data/address_store.dart
import 'package:flutter/material.dart';

class Address {
  final String id;
  String label;
  String line1;
  String line2;
  String city;
  String postalCode;
  String country;
  bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });
}

final globalAddressBook = AddressStore();

class AddressStore extends ChangeNotifier {
  final List<Address> _addresses = [];

  AddressStore() {
    _seed();
  }

  List<Address> get addresses => List.unmodifiable(_addresses);

  Address? get defaultAddress {
    for (final a in _addresses) {
      if (a.isDefault) return a;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  void add(Address address) {
    if (_addresses.isEmpty) {
      address.isDefault = true;
    }
    _addresses.add(address);
    notifyListeners();
  }

  void update(Address updated) {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index >= 0) {
      _addresses[index] = updated;
      notifyListeners();
    }
  }

  void remove(String id) {
    final wasDefault = _addresses.any((a) => a.id == id && a.isDefault);
    _addresses.removeWhere((a) => a.id == id);
    if (wasDefault && _addresses.isNotEmpty) {
      _addresses.first.isDefault = true;
    }
    notifyListeners();
  }

  void setDefault(String id) {
    for (final a in _addresses) {
      a.isDefault = a.id == id;
    }
    notifyListeners();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _seed() {
    add(
      Address(
        id: newId(),
        label: 'Home',
        line1: 'Linienstrasse 12',
        line2: '2nd Floor',
        city: 'Berlin',
        postalCode: '10178',
        country: 'DE',
        isDefault: true,
      ),
    );
  }
}
