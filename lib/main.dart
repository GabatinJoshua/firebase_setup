import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_setup/features/app/spalsh_screen/loading_screen.dart';
import 'package:firebase_setup/features/app/spalsh_screen/splash_screen.dart';
import 'package:firebase_setup/features/user_auth/presentation/pages/home_page.dart';
import 'package:firebase_setup/features/user_auth/presentation/pages/login_page.dart';
import 'package:firebase_setup/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      initialRoute: '/', // Default route
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/loading': (context) => LoadingScreen(
              child: HomePage(),
            ),
      },
    );
  }
}
