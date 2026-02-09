// Location: lib/data/user_profile_store.dart
import 'package:flutter/material.dart';

class UserProfile {
  String name;
  String email;
  String phone;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
  });
}

final globalUserProfile = UserProfileStore();

class UserProfileStore extends ChangeNotifier {
  UserProfile _profile = UserProfile(
    name: 'Alex Morgan',
    email: 'alex@revouge.test',
    phone: '+49 30 1234 5678',
  );

  UserProfile get profile => _profile;

  void update({required String name, required String email, required String phone}) {
    _profile = UserProfile(name: name.trim(), email: email.trim(), phone: phone.trim());
    notifyListeners();
  }
}
