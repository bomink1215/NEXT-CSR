import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'models/user_store.dart';
import 'screens/signup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => UserStore())],
    child: const GatchiSapsidaApp(),
  ));
}

class GatchiSapsidaApp extends StatelessWidget {
  const GatchiSapsidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = UserStore();
    return UserStoreProvider(
      store: store,
      child: MaterialApp(
        title: '같이삽시다',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SignupScreen(),
      ),
    );
  }
}
