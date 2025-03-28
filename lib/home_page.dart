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
  List<String> blocos = [];

  @override
  void initState() {
    super.initState();
    _buscarBlocos();
  }

  // Função para buscar os blocos no Firestore
  void _buscarBlocos() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('salas').get();
      setState(() {
        blocos = snapshot.docs.map((doc) => doc['nome'].toString()).toList();
      });
    } catch (e) {
      print("Erro ao buscar blocos: $e");
    }
  }

  // Quando um bloco é clicado
  void blocoClicado(int index) {
    print("Bloco ${blocos[index]} clicado!");
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
              blocos.isEmpty
                  ? CircularProgressIndicator() // Mostra carregamento enquanto busca os blocos
                  : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: blocos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => blocoClicado(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "{blocos[index]}",
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
          if (value == 1) {
            // Futuramente, pode ser usado para adicionar novos blocos no Firestore
            print("Botão de adicionar pressionado!");
          }
        },
      ),
    );
  }
}
