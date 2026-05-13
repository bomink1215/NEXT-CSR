import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_store.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedGender = '';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  final List<String> _genderOptions = ['남성', '여성', '기타'];

  final List<String> _suggestions = [
    '안암동', '종암동', '정릉동', '길음동', '미아동',
    '성북동', '돈암동', '석관동', '장위동', '월곡동',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10, now.month, now.day),
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  Future<String> _getOrCreateUid() async {
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      return credential.user!.uid;
    } catch (e) {
      return 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender.isEmpty) {
      _showError('성별을 선택해주세요.');
      return;
    }
    if (_selectedBirthDate == null) {
      _showError('생년월일을 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final gender = _selectedGender;
      final birthDate =
          '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}';
      final location = _locationController.text.trim();
      final firestore = FirebaseFirestore.instance;

      // 동일한 (이름 + 성별 + 생년월일) 사용자 확인
      final existing = await firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .where('gender', isEqualTo: gender)
          .where('birthDate', isEqualTo: birthDate)
          .limit(1)
          .get();

      String uid;
      int points = 0;

      if (existing.docs.isNotEmpty) {
        // 기존 사용자 복원
        uid = existing.docs.first.id;
        points = (existing.docs.first.data()['points'] ?? 0) as int;
        // 동네가 바뀌었을 경우 업데이트
        await firestore.collection('users').doc(uid).update({
          'location': location,
        });
      } else {
        // 신규 사용자 생성
        uid = await _getOrCreateUid();
        await firestore.collection('users').doc(uid).set({
          'name': name,
          'gender': gender,
          'birthDate': birthDate,
          'location': location,
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
        });
      }

      if (!mounted) return;
      UserStoreProvider.of(context).signUp(
        name: name,
        gender: gender,
        birthDate: birthDate,
        location: location,
        uid: uid,
        points: points,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
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
            child:
                const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
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
                const SizedBox(height: 48),

                // 이름
                _fieldLabel('이름'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                      hint: '예) 이예주', icon: Icons.person_outline),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '이름을 입력해주세요';
                    if (v.trim().length < 2) return '2글자 이상 입력해주세요';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 성별
                _fieldLabel('성별'),
                const SizedBox(height: 8),
                Row(
                  children: _genderOptions.map((g) {
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
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 생년월일
                _fieldLabel('생년월일'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                        Icon(
                          Icons.cake_outlined,
                          color: _selectedBirthDate != null
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 20,
                        ),
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
                const SizedBox(height: 24),

                // 내 동네
                _fieldLabel('내 동네'),
                const SizedBox(height: 4),
                const Text(
                  '공동구매·모임 등 근처 이웃과 매칭할 때 사용돼요',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(
                      hint: '예) 안암동', icon: Icons.location_on_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '동네를 입력해주세요';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 동네 빠른 선택 칩
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((s) {
                    final isSelected = _locationController.text == s;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _locationController.text = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),

                // 시작 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            '같이삽시다 시작하기 🏠',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
