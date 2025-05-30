import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/admin_page.dart';
import 'package:stock_manager/equip_page.dart';
import 'package:stock_manager/home_page.dart';
import 'package:stock_manager/log_page.dart';
import 'package:stock_manager/login_page.dart';
import 'package:stock_manager/search_page.dart';
import 'package:stock_manager/user_provider.dart';
import 'package:stock_manager/wrapper.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => UserProvider())],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Color(0xFFDDFFF7),
        ),
        home: Wrapper(),
        routes: {
          '/login': (context) => LoginPage(),
          '/home': (context) => HomePage(),
          '/admin': (context) => AdminPage(),
          '/equip': (context) => EquipPage(),
          '/log': (context) => LogPage(),
          '/search': (context) => SearchPage(),
        },
      ),
    );
  }
}
