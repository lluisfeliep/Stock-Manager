import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/user_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> dados = [];
  List<Map<String, dynamic>> dadosFiltrados = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 10;

  void _shownewlogdialog(
    Map<String, dynamic> equipamento,
    BuildContext context,
  ) {
    final TextEditingController comentarioController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Novo uso"),
              content: TextField(
                controller: comentarioController,
                decoration: InputDecoration(labelText: "Comentário"),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    String comentario = comentarioController.text.trim();
                    if (comentario.isNotEmpty) {
                      final userId = userProvider.userData?["uid"];
                      final firestore = FirebaseFirestore.instance;

                      final loc = equipamento["loc"];
                      final setorRef =
                          equipamento["setorRef"]; // Isso deve ser um DocumentReference

                      final novaEntrada = {
                        "comentario": comentario,
                        "data": DateTime.now(),
                        "loc": loc,
                        "setor": setorRef,
                        "user": firestore.doc('/Users/$userId'),
                      };

                      await firestore
                          .collection('equipamentos')
                          .doc(equipamento["id"])
                          .collection('log')
                          .add(novaEntrada);
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text("Salvar"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancelar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _buscarEqui({bool append = false}) async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      Query query = _firestore
          .collection('equipamentos')
          .orderBy('nome')
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

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

            // A string de nome do setor e sala
            List<String> pathParts = setorRef.path.split('/');
            String salaId = pathParts[1];
            DocumentSnapshot salaSnap =
                await _firestore.collection('salas').doc(salaId).get();
            String salaNome = salaSnap["nome"];

            tempDados.add({
              "id": equipId,
              "equip": nomeEquip,
              "setor":
                  "$salaNome / $setorNome", // Aqui você ainda está usando a string
              "setorRef": setorRef, // Aqui você vai armazenar a referência
              "loc": entry["loc"] ?? "",
              "quantidade": entry["quantidade"] ?? 0,
            });
          } catch (e) {
            continue;
          }
        }
      }

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

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {
          if (append) {
            dados.addAll(tempDados);
            dadosFiltrados.addAll(tempDados);
          } else {
            dados = tempDados;
            dadosFiltrados = tempDados;
          }
        });
      }

      if (snapshot.docs.length < _limit) _hasMore = false;
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoading = false);
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _buscarEqui(append: true);
      }
    });
    _searchController.addListener(() {
      _filtrarDados(_searchController.text);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                controller: _scrollController,
                itemCount: dadosFiltrados.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < dadosFiltrados.length) {
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
                                  dadosFiltrados[index]["quantidade"]
                                      .toString(),
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
                        _shownewlogdialog(dadosFiltrados[index], context);
                      },
                    );
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
