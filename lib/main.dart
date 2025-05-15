import 'package:flutter/material.dart';
import 'package:map_project/pages/home_page.dart';
import 'package:map_project/pages/login_page.dart';
import 'package:map_project/pages/main_page.dart';
import 'package:map_project/pages/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportsTribe',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: MainPage(),
    );
  }
}
