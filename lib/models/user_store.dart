import 'package:flutter/material.dart';

class UserStore extends ChangeNotifier {
  String _name = '';
  String _location = '';
  String _uid = '';
  String _gender = '';
  String _birthDate = '';
  int _points = 0;
  String _homeAddress = '';
  double _avgRating = 0.0;
  int _locationScope = 0; // 0=자동(최대), 몇 번째 파트까지 쓸지

  String get name => _name;
  String get location => _location;
  String get uid => _uid;
  String get gender => _gender;
  String get birthDate => _birthDate;
  int get points => _points;
  String get homeAddress => _homeAddress;
  double get avgRating => _avgRating;
  int get locationScope => _locationScope;
  bool get isSignedUp => _name.isNotEmpty && _location.isNotEmpty;

  // 실제 필터로 쓸 location prefix (scope에 따라 1~N 파트)
  String get filterLocation {
    final parts = _location.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return _location;
    final take = _locationScope == 0 ? parts.length : _locationScope;
    return parts.take(take.clamp(1, parts.length)).join(' ');
  }

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
    String homeAddress = '',
    double avgRating = 0.0,         // ← 추가
  }) {
    _name = name;
    _location = location;
    _uid = uid;
    _gender = gender;
    _birthDate = birthDate;
    _points = points;
    _homeAddress = homeAddress;
    _avgRating = avgRating;             // ← 추가
    notifyListeners();
  }

  void updateLocation(String location) {
    _location = location;
    _locationScope = 0; // 위치 바뀌면 범위 초기화
    notifyListeners();
  }

  void setLocationScope(int scope) {
    _locationScope = scope;
    notifyListeners();
  }

  void setPoints(int points) {
    _points = points;
    notifyListeners();
  }

  void setHomeAddress(String homeAddress) {
    _homeAddress = homeAddress;
    notifyListeners();
  }

  void setAvgRating(double avgRating) {
    _avgRating = avgRating;
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
