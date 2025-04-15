import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_manager/drawer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> dados = [];
  List<Map<String, dynamic>> dadosFiltrados = [];

  void _shownewlogdialog() {
    showDialog(
      context: context,
      builder: (builder) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Novo uso"),
              content: TextField(
                decoration: InputDecoration(labelText: "Comentario"),
              ),
            );
          },
        );
      },
    );
  }

  void _buscarEqui() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('equipamentos').get();

      List<Map<String, dynamic>> tempDados = [];

      for (var doc in snapshot.docs) {
        final String nomeEquip = doc["nome"];
        final String equipId = doc.id;
        final List<dynamic> setores = doc["setores"] ?? [];

        for (var entry in setores) {
          try {
            final refData = entry['ref'];
            DocumentReference setorRef;

            if (refData is DocumentReference) {
              setorRef = refData;
            } else if (refData is Map && refData.containsKey('_path')) {
              setorRef = FirebaseFirestore.instance.doc(refData['_path']);
            } else {
              continue;
            }

            DocumentSnapshot setorSnap = await setorRef.get();
            String setorNome = setorSnap["nome"];

            List<String> pathParts = setorRef.path.split('/');
            String salaId = pathParts[1];
            DocumentSnapshot salaSnap =
                await _firestore.collection('salas').doc(salaId).get();
            String salaNome = salaSnap["nome"];

            tempDados.add({
              "id": equipId,
              "equip": nomeEquip,
              "setor": "$salaNome / $setorNome",
              "loc": entry["loc"] ?? "",
              "quantidade": entry["quantidade"] ?? 0,
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
            continue;
          }
        }
      }

      // Ordena por sala/setor numericamente
      tempDados.sort((a, b) {
        String salaSetorA = a['setor'];
        String salaSetorB = b['setor'];

        List<String> partesA = salaSetorA.split(' / ');
        List<String> partesB = salaSetorB.split(' / ');

        int salaNumA =
            int.tryParse(partesA[0].replaceAll(RegExp(r'\D'), '')) ?? 0;
        int setorNumA =
            int.tryParse(partesA[1].replaceAll(RegExp(r'\D'), '')) ?? 0;

        int salaNumB =
            int.tryParse(partesB[0].replaceAll(RegExp(r'\D'), '')) ?? 0;
        int setorNumB =
            int.tryParse(partesB[1].replaceAll(RegExp(r'\D'), '')) ?? 0;

        if (salaNumA != salaNumB) {
          return salaNumA.compareTo(salaNumB);
        } else {
          return setorNumA.compareTo(setorNumB);
        }
      });

      setState(() {
        dados = tempDados;
        dadosFiltrados = tempDados;
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  void _filtrarDados(String texto) {
    String termo = texto.toLowerCase();

    setState(() {
      dadosFiltrados =
          dados.where((item) {
            String equip = item['equip'].toString().toLowerCase();
            String setor = item['setor'].toString().toLowerCase();

            return equip.contains(termo) || setor.contains(termo);
          }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _buscarEqui();
    _searchController.addListener(() {
      _filtrarDados(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Equipamentos"),
        backgroundColor: Color(0xFF63bfd8),
      ),
      drawer: CustomDrawer(),
      body: Container(
        color: Color(0xFFDDFFF7),
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Pesquisar",
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            Container(
              color: Color(0xFF319FBD),
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Qtd',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Nome',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Localização',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: dadosFiltrados.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    child: Container(
                      color:
                          index % 2 == 0
                              ? Color(0xFF9FD9E8)
                              : Color(0xFF77C8DE),
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                dadosFiltrados[index]["quantidade"].toString(),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 3,
                            child: Center(
                              child: Text(
                                dadosFiltrados[index]["equip"],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    dadosFiltrados[index]["setor"],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    dadosFiltrados[index]["loc"],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/log',
                        arguments: {"equipId": dadosFiltrados[index]["id"]},
                      );
                    },
                    onLongPress: () {
                      _shownewlogdialog();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
