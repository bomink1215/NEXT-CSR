import 'package:flutter/material.dart';

class UserStore extends ChangeNotifier {
  String _name = '';
  String _location = '';
  String _uid = '';
  String _gender = '';
  String _birthDate = ''; // 'YYYY-MM-DD'
  int _points = 0;

  String get name => _name;
  String get location => _location;
  String get uid => _uid;
  String get gender => _gender;
  String get birthDate => _birthDate;
  int get points => _points;
  bool get isSignedUp => _name.isNotEmpty && _location.isNotEmpty;

  /// 생년월일로부터 나이대 계산 ('twenties' | 'thirties' | 'other')
  String get ageCategory {
    if (_birthDate.isEmpty) return 'other';
    try {
      final birth = DateTime.parse(_birthDate);
      final age = DateTime.now().year - birth.year;
      if (age >= 20 && age < 30) return 'twenties';
      if (age >= 30 && age < 40) return 'thirties';
      return 'other';
    } catch (_) {
      return 'other';
    }
  }

  void signUp({
    required String name,
    required String location,
    required String uid,
    String gender = '',
    String birthDate = '',
    int points = 0,
  }) {
    _name = name;
    _location = location;
    _uid = uid;
    _gender = gender;
    _birthDate = birthDate;
    _points = points;
    notifyListeners();
  }

  void updateLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void setPoints(int points) {
    _points = points;
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
