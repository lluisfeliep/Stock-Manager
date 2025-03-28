import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  String username = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, size: 150),
            Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: 300,
                decoration: BoxDecoration(
                  color: Color(0xFF77C8DE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xff4FB6D2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        username = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Username',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        password = value;
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.white, // Campo branco
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (username == "Admin" && password == "123") {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/admin');
                            } else if (username == "Home" &&
                                password == "123") {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/home');
                            }
                          },
                          child: const Text("Entrar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
