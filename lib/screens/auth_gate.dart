import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_store.dart';
import '../utils/notification_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checked = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('saved_uid');

    if (savedUid == null || savedUid.isEmpty) {
      if (mounted) setState(() => _checked = true);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(savedUid)
          .get();

      if (!doc.exists || !mounted) {
        setState(() => _checked = true);
        return;
      }

      final data = doc.data()!;
      context.read<UserStore>().signUp(
        name: data['name'] ?? '',
        gender: data['gender'] ?? '',
        birthDate: data['birthDate'] ?? '',
        location: data['location'] ?? '',
        uid: savedUid,
        points: (data['points'] ?? 0) as int,
        homeAddress: data['homeAddress'] ?? '',
        avgRating: ((data['avgRating'] ?? 0.0) as num).toDouble(),
      );

      try {
        await NotificationService.saveFcmToken(savedUid);
        NotificationService.setupForegroundNotification();
      } catch (_) {}

      if (mounted) setState(() { _checked = true; _isLoggedIn = true; });
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const HomeScreen() : const SignupScreen();
  }
}