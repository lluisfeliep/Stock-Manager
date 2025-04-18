import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/user_provider.dart';

class CustomDrawer extends StatefulWidget {
  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final Map<String, bool> _pressedStates = {};
  final Map<String, bool> _insideStates = {};

  Widget buildPressableTile({
    required String keyId,
    required Icon icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF9FD9E8),
    Color pressedColor = const Color(0xFF7FBBCB),
  }) {
    _pressedStates.putIfAbsent(keyId, () => false);
    _insideStates.putIfAbsent(keyId, () => false);

    return LayoutBuilder(
      builder:
          (context, constraints) => GestureDetector(
            onTapDown:
                (_) => setState(() {
                  _pressedStates[keyId] = true;
                  _insideStates[keyId] = true;
                }),
            onTapUp: (_) {
              if (_insideStates[keyId] == true) onTap();
              setState(() {
                _pressedStates[keyId] = false;
                _insideStates[keyId] = false;
              });
            },
            onTapCancel:
                () => setState(() {
                  _pressedStates[keyId] = false;
                  _insideStates[keyId] = false;
                }),
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final inside =
                  local.dx >= 0 &&
                  local.dy >= 0 &&
                  local.dx <= constraints.maxWidth &&
                  local.dy <= constraints.maxHeight;
              setState(() => _insideStates[keyId] = inside);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              color:
                  _pressedStates[keyId]! && _insideStates[keyId]!
                      ? pressedColor
                      : color,
              child: ListTile(
                leading: icon,
                title: Text(
                  label,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
    );
  }

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
          buildPressableTile(
            keyId: 'pesquisar',
            icon: Icon(Icons.search),
            label: "Pesquisar",
            onTap: () => Navigator.of(context).pushNamed('/search'),
          ),
          if (userData?['Admin'] == true)
            buildPressableTile(
              keyId: 'admin',
              icon: Icon(Icons.person),
              label: "Gerenciar Logins",
              onTap: () => Navigator.of(context).pushNamed('/admin'),
            ),
          Spacer(),
          buildPressableTile(
            keyId: 'logout',
            icon: Icon(Icons.login, color: Colors.red),
            label: "Log Out",
            onTap: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            color: Color(0xFF9FD9E8),
            pressedColor: Color(0xFF7FBBCB),
          ),
        ],
      ),
    );
  }
}
