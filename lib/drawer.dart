import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  final List<Widget>? extraWidgets; // Lista opcional para novos widgets

  CustomDrawer({this.extraWidgets});
  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
          GestureDetector(
            child: Container(
              color: Color(0xFF9FD9E8),
              child: ListTile(
                leading: Icon(Icons.inbox),
                title: Text(
                  "Salas",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            onTap: () {
              Navigator.of(
                context,
              ).pushReplacementNamed('/home', arguments: userData);
            },
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
              Navigator.of(
                context,
              ).pushReplacementNamed('/', arguments: userData);
            },
          ),
          if (userData["Admin"] == true)
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
                Navigator.of(
                  context,
                ).pushReplacementNamed('/admin', arguments: userData);
              },
            ),
          if (widget.extraWidgets != null) ...widget.extraWidgets!,
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
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }
}
