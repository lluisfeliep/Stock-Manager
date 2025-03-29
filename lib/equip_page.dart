import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_manager/drawer.dart';

class EquipPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String id = ModalRoute.of(context)!.settings.arguments as String;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('salas').doc(id).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Carregando..."),
              backgroundColor: Color(0xFF63bfd8),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text("Sala não encontrada")),
            body: Center(child: Text("Sala não encontrada")),
          );
        }

        String nomeSala = snapshot.data!["nome"];

        return Scaffold(
          appBar: AppBar(
            title: Text(nomeSala),
            backgroundColor: Color(0xFF63bfd8),
          ),
          drawer: CustomDrawer(),
          body: Center(child: Text(nomeSala, style: TextStyle(fontSize: 24))),
        );
      },
    );
  }
}
