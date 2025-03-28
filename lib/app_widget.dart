import 'package:flutter/material.dart';
import 'package:stock_manager/admin_page.dart';
import 'package:stock_manager/equip_page.dart';
import 'package:stock_manager/home_page.dart';
import 'package:stock_manager/login_page.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFDDFFF7),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/admin': (context) => AdminPage(),
        '/equip': (context) => EquipPage(),
      },
    );
  }
}
