import 'package:flutter/material.dart';
import 'package:map_project/pages/login_page.dart';
import 'package:map_project/pages/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportsTribe',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        //'/home': (context) => const HomeScreen(),
      },
    );
  }
}
