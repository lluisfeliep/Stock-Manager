import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
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
  Map<String, dynamic>? userData;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 10;

  Future<void> _shownewlogdialog(
    Map<String, dynamic> equipamento,
    BuildContext context,
  ) {
    final TextEditingController comentarioController = TextEditingController();
    int quantidade = 0;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Novo uso"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: comentarioController,
                    decoration: InputDecoration(labelText: "Comentário"),
                  ),
                  Row(
                    children: [
                      Text("Quantidade usada:"),
                      NumberPicker(
                        minValue: 0,
                        maxValue: equipamento['quantidade'],
                        value: quantidade,
                        onChanged: (value) {
                          setState(() {
                            quantidade = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    String comentario = comentarioController.text.trim();
                    if (comentario.isNotEmpty) {
                      String userId = userData?["uid"];
                      final firestore = FirebaseFirestore.instance;

                      final loc = equipamento["loc"];
                      final setorRef = equipamento["setorRef"];

                      final docRef = firestore
                          .collection('equipamentos')
                          .doc(equipamento["id"]);

                      final novaEntrada = {
                        "comentario":
                            quantidade == 0
                                ? comentario
                                : "$comentario -$quantidade",
                        "data": DateTime.now(),
                        "loc": loc,
                        "setor": setorRef,
                        "user": firestore.doc('/Users/$userId'),
                      };

                      // Adiciona o log
                      await docRef.collection('log').add(novaEntrada);

                      // Atualiza setores, se necessário
                      final docSnapshot = await docRef.get();
                      if (docSnapshot.exists) {
                        final data = docSnapshot.data() as Map<String, dynamic>;
                        List<dynamic> setores = data["setores"] ?? [];

                        for (var setor in setores) {
                          final ref = setor["ref"];
                          if (ref is DocumentReference &&
                              ref.path == setorRef.path &&
                              setor.containsKey("quantidade")) {
                            if (quantidade > 0) {
                              setor["quantidade"] =
                                  (setor["quantidade"] ?? 0) - quantidade;
                              if (setor["quantidade"] < 0) {
                                setor["quantidade"] = 0;
                              }

                              // Se zerou, marca como inativo
                              if (setor["quantidade"] == 0) {
                                setor["inativo"] = true;
                              }
                            } else {
                              // Se quantidade usada é 0, mas no banco a quantidade já era 0
                              if ((setor["quantidade"] ?? 0) == 0) {
                                setor["inativo"] = true;
                              }
                            }

                            break;
                          }
                        }

                        await docRef.update({"setores": setores});
                      }
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _buscarEqui({bool append = false}) async {
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
        final data = doc.data() as Map<String, dynamic>;
        final String nomeEquip = data["nome"];
        final String equipId = doc.id;
        final List<dynamic> setores = data["setores"] ?? [];

        for (var entry in setores) {
          try {
            // Verifica se o setor está inativo
            final bool isInativo = entry["inativo"] == true;
            final bool isAdmin = userData?['Admin'] == true;

            // Se o setor for inativo e o usuário não for admin, ignora
            if (isInativo && !isAdmin) continue;

            // Pega a referência corretamente
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

            // Pega o nome da sala a partir do path
            List<String> pathParts = setorRef.path.split('/');
            String salaId = pathParts[1];
            DocumentSnapshot salaSnap =
                await _firestore.collection('salas').doc(salaId).get();
            String salaNome = salaSnap["nome"];

            tempDados.add({
              "id": equipId,
              "equip": nomeEquip,
              "setor": "$salaNome / $setorNome",
              "setorRef": setorRef,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        userData = provider.userData;
      });
    });
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
                      onLongPress: () async {
                        await _shownewlogdialog(dadosFiltrados[index], context);
                        _lastDocument = null;
                        _hasMore = true;
                        dados.clear();
                        dadosFiltrados.clear();
                        await _buscarEqui();
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
