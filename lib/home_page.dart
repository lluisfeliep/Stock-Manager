import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_manager/drawer.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, String>> salas = [];

  @override
  void initState() {
    super.initState();
    _buscarSalas();
  }

  void _buscarSalas() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('salas').get();
      setState(() {
        salas =
            snapshot.docs
                .map((doc) => {"id": doc.id, "nome": doc["nome"].toString()})
                .toList();
      });
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Erro"),
              content: Text("$e"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o diálogo
                  },
                  child: Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  void salaClicada(int index) {
    Navigator.pushNamed(context, "/equip", arguments: salas[index]["id"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home'), backgroundColor: Color(0xFF63bfd8)),
      drawer: CustomDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child:
              salas.isEmpty
                  ? CircularProgressIndicator()
                  : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: salas.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => salaClicada(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            salas[index]["nome"].toString(),
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF63bfd8),
        selectedItemColor: Color(0xFF000000),
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Adicionar"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
        onTap: (value) {
          if (value == 1) {}
        },
      ),
    );
  }
}
