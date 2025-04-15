import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/user_provider.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  String username = '';
  String password = '';

  Future<void> login() async {
    try {
      String email = "$username@example.com"; // Transformar username em email

      // Autenticar no Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Buscar permissões no Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userDoc.id;

        // Armazenar dados no Provider
        Provider.of<UserProvider>(context, listen: false).setUser(userData);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário não encontrado no Firestore!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
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
                              onPressed: login, // Chamando a função de login
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
        ),
      ),
    );
  }
}
