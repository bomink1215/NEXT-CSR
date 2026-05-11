import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'models/user_store.dart';
import 'screens/signup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const GatchiSapsidaApp());
}

class GatchiSapsidaApp extends StatelessWidget {
  const GatchiSapsidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return UserStoreProvider(
      store: UserStore(),
      child: MaterialApp(
        title: '같이삽시다',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SignupScreen(),
      ),
    );
  }
}
