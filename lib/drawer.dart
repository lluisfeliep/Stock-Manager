import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/user_provider.dart';

class CustomDrawer extends StatefulWidget {
  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Drawer(
      backgroundColor: Color(0xFFDDFFF7),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFF63bfd8),
            child: ListTile(
              trailing: Icon(Icons.book),
              title: Text(
                "Stock Manager",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            color: Color(0xFF9FD9E8),
            child: ListTile(
              leading: Icon(Icons.inbox),
              title: Text(
                "Salas",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              color: Color(0xFF9FD9E8),
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text(
                  "Pesquisar",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).pushNamed('/search');
            },
          ),
          if (userData?["Admin"] == true)
            GestureDetector(
              child: Container(
                color: Color(0xFF9FD9E8),
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(
                    "Gerenciar Logins",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/admin');
              },
            ),
          Spacer(),
          GestureDetector(
            child: Container(
              color: Color(0xFF9FD9E8),
              child: ListTile(
                leading: Icon(Icons.login, color: Colors.red),
                title: Text(
                  "Log Out",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            onTap: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }
}
