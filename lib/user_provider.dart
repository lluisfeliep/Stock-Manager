import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  void setUser(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    _userData = null;
    notifyListeners();
  }
}
