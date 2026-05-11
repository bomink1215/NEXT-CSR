import 'package:flutter/material.dart';

class UserStore extends ChangeNotifier {
  String _name = '';
  String _location = '';

  String get name => _name;
  String get location => _location;
  bool get isSignedUp => _name.isNotEmpty && _location.isNotEmpty;

  void signUp({required String name, required String location}) {
    _name = name;
    _location = location;
    notifyListeners();
  }

  void updateLocation(String location) {
    _location = location;
    notifyListeners();
  }
}

class UserStoreProvider extends InheritedNotifier<UserStore> {
  const UserStoreProvider({
    super.key,
    required UserStore store,
    required super.child,
  }) : super(notifier: store);

  static UserStore of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<UserStoreProvider>();
    assert(provider != null, 'UserStoreProvider를 찾을 수 없습니다.');
    return provider!.notifier!;
  }
}
