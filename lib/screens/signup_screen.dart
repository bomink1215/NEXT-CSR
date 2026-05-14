import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_store.dart';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/rating_checker.dart';
import '../utils/location_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isLoginMode = true; // true = 로그인, false = 회원가입

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '같이삽시다 🏠',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '더 가볍게 사고(Buy),\n더 즐겁게 사는(Live) 법',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // 로그인/회원가입 탭
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLoginMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _isLoginMode
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: _isLoginMode ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '로그인',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _isLoginMode
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLoginMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: !_isLoginMode
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: !_isLoginMode ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '회원가입',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: !_isLoginMode
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_isLoginMode)
                _LoginForm()
              else
                _SignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 로그인 폼 ────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePw = true;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_idController.text.trim().isEmpty || _pwController.text.trim().isEmpty) {
      _showError('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final snap = await firestore
          .collection('users')
          .where('userId', isEqualTo: _idController.text.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _showError('존재하지 않는 아이디예요.');
        return;
      }

      final data = snap.docs.first.data();
      if (data['password'] != _pwController.text.trim()) {
        _showError('비밀번호가 틀렸어요.');
        return;
      }

      if (!mounted) return;
      UserStoreProvider.of(context).signUp(
        name: data['name'] ?? '',
        gender: data['gender'] ?? '',
        birthDate: data['birthDate'] ?? '',
        location: data['location'] ?? '',
        uid: snap.docs.first.id,
        points: (data['points'] ?? 0) as int,
        homeAddress: data['homeAddress'] ?? '',
        avgRating: ((data['avgRating'] ?? 0.0) as num).toDouble(),       
      );

      if (!mounted) return;
      RatingChecker.checkAndComplete();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('아이디',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _idController,
          decoration: _inputDeco(hint: '아이디를 입력하세요', icon: Icons.person_outline),
        ),
        const SizedBox(height: 16),
        const Text('비밀번호',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _pwController,
          obscureText: _obscurePw,
          decoration: _inputDeco(hint: '비밀번호를 입력하세요', icon: Icons.lock_outline)
              .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePw ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textHint),
              onPressed: () => setState(() => _obscurePw = !_obscurePw),
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('로그인',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

// ─── 회원가입 폼 ──────────────────────────────────────────────
class _SignupForm extends StatefulWidget {
  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedGender = '';
  DateTime? _selectedBirthDate;
  String _selectedLocation = '';
  bool _isLoading = false;
  bool _obscurePw = true;
  bool _obscurePwConfirm = true;
  bool _idChecked = false; // 중복확인 여부
  bool _idAvailable = false; // 사용 가능 여부

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await showLocationPicker(
      context,
      currentLocation: _selectedLocation,
    );
    if (result != null && mounted) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _checkIdDuplicate() async {
    if (_idController.text.trim().isEmpty) {
      _showError('아이디를 입력해주세요.');
      return;
    }
    if (_idController.text.trim().length < 4) {
      _showError('아이디는 4글자 이상 입력해주세요.');
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: _idController.text.trim())
        .limit(1)
        .get();

    setState(() {
      _idChecked = true;
      _idAvailable = snap.docs.isEmpty;
    });

    if (_idAvailable) {
      _showMessage('사용 가능한 아이디예요! 😊');
    } else {
      _showError('이미 사용 중인 아이디예요.');
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10),
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  Future<void> _signup() async {
    if (!_idChecked || !_idAvailable) {
      _showError('아이디 중복확인을 해주세요.');
      return;
    }
    if (_pwController.text.trim().isEmpty) {
      _showError('비밀번호를 입력해주세요.');
      return;
    }
    if (_pwController.text.trim().length < 6) {
      _showError('비밀번호는 6자 이상 입력해주세요.');
      return;
    }
    if (_pwController.text != _pwConfirmController.text) {
      _showError('비밀번호가 일치하지 않아요.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('닉네임을 입력해주세요.');
      return;
    }
    if (_selectedGender.isEmpty) {
      _showError('성별을 선택해주세요.');
      return;
    }
    if (_selectedBirthDate == null) {
      _showError('생년월일을 선택해주세요.');
      return;
    }
    if (_selectedLocation.isEmpty) {
      _showError('거주지를 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final birthDate =
          '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}';

      final docRef = await firestore.collection('users').add({
        'userId': _idController.text.trim(),
        'password': _pwController.text.trim(),
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birthDate': birthDate,
        'location': _selectedLocation,
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      UserStoreProvider.of(context).signUp(
        name: _nameController.text.trim(),
        gender: _selectedGender,
        birthDate: birthDate,
        location: _selectedLocation,
        uid: docRef.id,
        points: 0,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이디
        const Text('아이디',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _idController,
                onChanged: (_) => setState(() {
                  _idChecked = false;
                  _idAvailable = false;
                }),
                decoration: _inputDeco(
                    hint: '4자 이상 영문/숫자', icon: Icons.person_outline),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _checkIdDuplicate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('중복확인',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
        if (_idChecked)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _idAvailable ? '✅ 사용 가능한 아이디예요' : '❌ 이미 사용 중인 아이디예요',
              style: TextStyle(
                  fontSize: 12,
                  color: _idAvailable ? AppColors.success : AppColors.error),
            ),
          ),
        const SizedBox(height: 16),

        // 비밀번호
        const Text('비밀번호',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _pwController,
          obscureText: _obscurePw,
          decoration:
              _inputDeco(hint: '6자 이상', icon: Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePw ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textHint),
              onPressed: () => setState(() => _obscurePw = !_obscurePw),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 비밀번호 확인
        const Text('비밀번호 확인',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _pwConfirmController,
          obscureText: _obscurePwConfirm,
          decoration:
              _inputDeco(hint: '비밀번호 재입력', icon: Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePwConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textHint),
              onPressed: () =>
                  setState(() => _obscurePwConfirm = !_obscurePwConfirm),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 닉네임
        const Text('닉네임',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: _inputDeco(hint: '', icon: Icons.badge_outlined),
        ),
        const SizedBox(height: 16),

        // 성별
        const Text('성별',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: ['남성', '여성', '기타'].map((g) {
            final isSelected = _selectedGender == g;
            return GestureDetector(
              onTap: () => setState(() => _selectedGender = g),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(g,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 생년월일
        const Text('생년월일',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBirthDate,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedBirthDate != null
                    ? AppColors.primary
                    : AppColors.divider,
                width: _selectedBirthDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_outlined,
                    color: _selectedBirthDate != null
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 20),
                const SizedBox(width: 12),
                Text(
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일'
                      : '생년월일을 선택해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedBirthDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 거주지
        const Text('거주지',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('공동구매·모임 등 근처 이웃과 매칭할 때 사용돼요',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        LocationPickerButton(
          selectedLocation: _selectedLocation,
          hint: '시/구/동을 선택해주세요',
          onTap: _pickLocation,
        ),
        const SizedBox(height: 40),

        // 회원가입 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('회원가입',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

InputDecoration _inputDeco({required String hint, required IconData icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.textHint),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}