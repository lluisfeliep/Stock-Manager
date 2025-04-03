import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/drawer.dart';
import 'package:stock_manager/user_provider.dart';

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

  Future<bool> _mostrarDialogoConfirmacao(
    TextEditingController nomeController,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Criar nova sala"),
              content: TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: "Nome da sala"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Criar"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _criarNovaSala() async {
    try {
      // Obtém a quantidade atual de documentos na coleção "salas"
      QuerySnapshot snapshot = await _firestore.collection('salas').get();
      int quantidade = snapshot.docs.length;

      // Define o ID fixo da sala
      String idSala = "sala_${quantidade + 1}";

      // Abre um AlertDialog para o usuário definir o campo "nome"
      TextEditingController nomeController = TextEditingController();
      bool confirmar = await _mostrarDialogoConfirmacao(nomeController);

      if (!confirmar || nomeController.text.trim().isEmpty) {
        return; // Cancela se não for confirmado
      }

      // Criar documento no Firestore com ID fixo e nome escolhido
      await _firestore.collection('salas').doc(idSala).set({
        'nome': nomeController.text.trim(), // Apenas o campo "nome" é editável
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sala '$idSala' criada com sucesso!")),
      );
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
    _buscarSalas();
  }

  //Função de mostrar salas na tela principal
  Future<void> _buscarSalas() async {
    await Future.delayed(Duration(seconds: 1));
    try {
      QuerySnapshot snapshot = await _firestore.collection('salas').get();
      setState(() {
        salas =
            //Busca id para mandar para nova sala e nome para mostrar na tela
            snapshot.docs
                .map((doc) => {"id": doc.id, "nome": doc["nome"].toString()})
                .toList();
        salas.sort((a, b) => a["nome"]!.compareTo(b["nome"]!));
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

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      appBar: AppBar(title: Text('Home'), backgroundColor: Color(0xFF63bfd8)),
      drawer: CustomDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child:
              salas.isEmpty
                  ? CircularProgressIndicator()
                  : RefreshIndicator(
                    onRefresh: _buscarSalas,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: salas.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              "/equip",
                              arguments: {
                                "id": salas[index]["id"],
                                "userData": userData,
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              salas[index]["nome"].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
            userData?["Admin"] || userData?["PSala"] == true
                ? _criarNovaSala()
                : showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text("Erro"),
                        content: Text(
                          "Você não tem permissão para adicionar novas salas",
                        ),
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
        },
      ),
    );
  }
}
