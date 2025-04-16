import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/user_provider.dart';

class EquipPage extends StatefulWidget {
  @override
  State<EquipPage> createState() => _EquipPageState();
}

class _EquipPageState extends State<EquipPage> {
  late FirebaseFirestore firestore;
  bool isLoading = true;
  List<Map<String, dynamic>> setoresComEquipamentos = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    firestore = FirebaseFirestore.instance;
    _loadSetoresComEquipamentos();
  }

  void _showNewEquip() {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String salaId = args["id"] as String;

    TextEditingController textequipController = TextEditingController();
    TextEditingController textlocController = TextEditingController();
    int quantidade = 1;

    String? selectedSetor;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Criar novo item"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textequipController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Equipamento',
                    ),
                  ),
                  TextField(
                    controller: textlocController,
                    decoration: InputDecoration(
                      labelText: 'Localização do equipamento',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Quantidade:"),
                      NumberPicker(
                        minValue: 1,
                        maxValue: 100,
                        value: quantidade,
                        onChanged: (value) {
                          setState(() {
                            quantidade = value;
                          });
                        },
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    hint: Text("Setor"),
                    value: selectedSetor,
                    isExpanded: true,
                    items: [
                      ...setoresComEquipamentos.map((setor) {
                        return DropdownMenuItem<String>(
                          value: setor['setorId'],
                          child: Text(setor['setorNome']),
                        );
                      }),
                      DropdownMenuItem<String>(
                        value: 'add_new',
                        child: Row(
                          children: [
                            Icon(Icons.add),
                            Text("Adicionar novo setor"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == 'add_new') {
                        final newSetorId = await _criarNovoSetor(salaId);
                        await _loadSetoresComEquipamentos(); // Atualiza lista
                        setState(() {
                          selectedSetor = newSetorId;
                        });
                      } else {
                        setState(() {
                          selectedSetor = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (selectedSetor != null &&
                        textequipController.text.isNotEmpty &&
                        textlocController.text.isNotEmpty) {
                      await _salvarEquipamento(
                        salaId,
                        selectedSetor!,
                        textequipController.text,
                        textlocController.text,
                        quantidade,
                      );
                      await _loadSetoresComEquipamentos(); // atualiza lista
                      Navigator.pop(context);
                    }
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

  Future<void> _salvarEquipamento(
    String salaId,
    String setorId,
    String nome,
    String local,
    int quantidadeNova,
  ) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    final userRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userData?["uid"]);

    DocumentReference setorRef = FirebaseFirestore.instance
        .collection('salas')
        .doc(salaId)
        .collection('setores')
        .doc(setorId);

    final query =
        await FirebaseFirestore.instance
            .collection('equipamentos')
            .where('nome', isEqualTo: nome)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      int quantidadeAtual = doc['quantidade'] ?? 0;
      List<dynamic> setoresExistentes = doc['setores'] ?? [];

      bool setorEncontrado = false;

      List<dynamic> setoresAtualizados =
          setoresExistentes.map((entry) {
            final ref = entry['ref'] as DocumentReference;
            if (ref.path == setorRef.path) {
              setorEncontrado = true;
              return {
                'ref': ref,
                'quantidade': (entry['quantidade'] ?? 0) + quantidadeNova,
                'loc': local,
              };
            }
            return entry;
          }).toList();

      if (!setorEncontrado) {
        setoresAtualizados.add({
          'ref': setorRef,
          'quantidade': quantidadeNova,
          'loc': local,
        });
      }

      await doc.reference.update({
        'quantidade': quantidadeAtual + quantidadeNova,
        'setores': setoresAtualizados,
      });

      await doc.reference.collection("log").add({
        'comentario': '"Adicionado novo: +$quantidadeNova',
        'data': DateTime.now(),
        'user': userRef,
        'setor': setorRef,
        'loc': local,
      });
    } else {
      final equipamentoRef = await FirebaseFirestore.instance
          .collection('equipamentos')
          .add({
            'nome': nome,
            'data': DateTime.now(),
            'quantidade': quantidadeNova,
            'setores': [
              {'ref': setorRef, 'quantidade': quantidadeNova, 'loc': local},
            ],
          });

      await equipamentoRef.collection("log").add({
        'comentario': 'Criado novo equipamento',
        'data': DateTime.now(),
        'user': userRef,
        'setor': setorRef,
        'loc': local,
      });
    }
  }

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

  Future<String> _criarNovoSetor(String salaId) async {
    final setoresRef = FirebaseFirestore.instance
        .collection('salas')
        .doc(salaId)
        .collection('setores');

    final snapshot = await setoresRef.get();

    // Pega maior número de "Setor n"
    final numbers =
        snapshot.docs.map((doc) {
          final nome = doc['nome'];
          final match = RegExp(r'Setor (\d+)').firstMatch(nome);
          return match != null ? int.parse(match.group(1)!) : 0;
        }).toList();

    final nextNumber =
        (numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b)) + 1;
    final newId = 'setor_$nextNumber';
    final newName = 'Setor $nextNumber';

    await setoresRef.doc(newId).set({'nome': newName});

    return newId;
  }

  Future<void> _loadSetoresComEquipamentos() async {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String salaId = args["id"] as String;

    try {
      final setoresSnapshot =
          await firestore
              .collection('salas')
              .doc(salaId)
              .collection('setores')
              .get();

      final equipamentosSnapshot =
          await firestore.collection('equipamentos').get();

      List<Map<String, dynamic>> tempList = [];

      for (var setorDoc in setoresSnapshot.docs) {
        String setorNome = setorDoc['nome'];
        String setorId = setorDoc.id;

        DocumentReference setorRef = firestore
            .collection('salas')
            .doc(salaId)
            .collection('setores')
            .doc(setorId);

        List<Map<String, dynamic>> equipamentosDoSetor = [];

        for (var equipDoc in equipamentosSnapshot.docs) {
          final List<dynamic> setores = equipDoc['setores'] ?? [];

          for (var entry in setores) {
            if (entry['ref'].path == setorRef.path) {
              equipamentosDoSetor.add({
                'nome': equipDoc['nome'],
                'loc': entry['loc'],
                'setorRef': setorRef,
                'quantidade': entry['quantidade'],
                'id': equipDoc.id,
              });
            }
          }
        }

        tempList.add({
          'setorNome': setorNome,
          'setorId': setorId,
          'equipamentos': equipamentosDoSetor,
        });
      }

      if (mounted) {
        setState(() {
          setoresComEquipamentos = tempList;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Carregando..."),
          backgroundColor: Color(0xFF63bfd8),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Equipamentos"),
        backgroundColor: Color(0xFF63bfd8),
      ),
      body:
          setoresComEquipamentos.isEmpty
              ? Center(
                child: Text(
                  "Nenhum setor encontrado",
                  style: TextStyle(fontSize: 24),
                ),
              )
              : ListView.builder(
                itemCount: setoresComEquipamentos.length,
                itemBuilder: (context, index) {
                  var setor = setoresComEquipamentos[index];
                  return Container(
                    decoration: BoxDecoration(color: Color(0xFF319FBD)),
                    child: ExpansionTile(
                      title: Text(
                        setor['setorNome'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children:
                          setor['equipamentos']
                              .map<Widget>(
                                (equip) => GestureDetector(
                                  child: ListTile(
                                    title: Text(equip['nome']),
                                    subtitle: Text(
                                      'Localização: ${equip['loc']}',
                                    ),
                                    leading: Icon(Icons.build),
                                    trailing: Text(
                                      equip['quantidade'].toString(),
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      '/log',
                                      arguments: {'equipId': equip['id']},
                                    );
                                  },
                                  onLongPress: () {
                                    _shownewlogdialog(equip, context);
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF319FBD),
        onPressed: _showNewEquip,
        child: Icon(Icons.add),
      ),
    );
  }
}
