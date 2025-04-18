import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/login_page.dart';
import 'package:stock_manager/home_page.dart';
import 'package:stock_manager/user_provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  Future<Widget> handleAuthAndData(BuildContext context, User user) async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      userData['uid'] = user.uid;

      // Salva os dados no Provider
      Provider.of<UserProvider>(context, listen: false).setUser(userData);
    }

    return HomePage(); // Pode mudar aqui para redirecionar conforme a role, se quiser
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Erro de autenticação'));
        } else {
          if (snapshot.data == null) {
            return LoginPage();
          } else {
            // Carrega dados do Firestore e mostra tela correspondente
            return FutureBuilder(
              future: handleAuthAndData(context, snapshot.data!),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (futureSnapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar dados do usuário'),
                  );
                } else {
                  return futureSnapshot.data as Widget;
                }
              },
            );
          }
        }
      },
    );
  }
}
