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
  Map<String, dynamic>? userData; // <- Adicionado

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    firestore = FirebaseFirestore.instance;
    if (userData == null) {
      userData = Provider.of<UserProvider>(context).userData;
      _loadSetoresComEquipamentos();
    }
  }

  void _showNewEquip() async {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String salaId = args["id"] as String;
    List<String> nomesEquipamentos = [];
    List<String> locaisEquipamentos = [];

    TextEditingController textequipController = TextEditingController();
    TextEditingController textlocController = TextEditingController();
    int quantidade = 1;

    String? selectedSetor;

    final equipamentosSnapshot =
        await FirebaseFirestore.instance.collection('equipamentos').get();

    for (var doc in equipamentosSnapshot.docs) {
      final nome = doc['nome'];
      if (nome != null && !nomesEquipamentos.contains(nome)) {
        nomesEquipamentos.add(nome);
      }

      final setores = doc['setores'];
      if (setores is List) {
        for (var setor in setores) {
          final loc = setor['loc'];
          if (loc != null && !locaisEquipamentos.contains(loc)) {
            locaisEquipamentos.add(loc);
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Criar novo item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do Equipamento
                    RawAutocomplete<String>(
                      textEditingController: textequipController,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return nomesEquipamentos.where((String option) {
                          return option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      },
                      fieldViewBuilder: (
                        context,
                        controller,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Nome do Equipamento',
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              color: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),

                    // Localização
                    RawAutocomplete<String>(
                      textEditingController: textlocController,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return locaisEquipamentos.where((String option) {
                          return option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      },
                      fieldViewBuilder: (
                        context,
                        controller,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Localização do Equipamento',
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              color: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),

                    // Quantidade
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

                    // Dropdown de setor
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
                          await _loadSetoresComEquipamentos();
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
                      await _loadSetoresComEquipamentos();
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
      List<dynamic> setoresExistentes = doc['setores'] ?? [];

      bool setorEncontrado = false;

      List<dynamic> setoresAtualizados =
          setoresExistentes.map((entry) {
            final ref = entry['ref'] as DocumentReference;
            if (ref.path == setorRef.path) {
              setorEncontrado = true;
              int quantidadeAtual = (entry['quantidade'] ?? 0);
              int novaQuantidade = quantidadeAtual + quantidadeNova;

              // Clona o map e atualiza os campos
              Map<String, dynamic> atualizado = {
                'ref': ref,
                'quantidade': novaQuantidade,
                'loc': local,
              };

              // Se existia algum campo extra como 'inativo', só mantém se necessário
              if (novaQuantidade <= 0 && entry['inativo'] == true) {
                atualizado['inativo'] = true;
              }

              return atualizado;
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

      await doc.reference.update({'setores': setoresAtualizados});

      await doc.reference.collection("log").add({
        'comentario': 'Adicionado novo: +$quantidadeNova',
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

  Future<String> _criarNovoSetor(String salaId) async {
    final setoresRef = FirebaseFirestore.instance
        .collection('salas')
        .doc(salaId)
        .collection('setores');

    final snapshot = await setoresRef.get();

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
            if (entry['ref'].path == setorRef.path &&
                (userData?['Admin'] == true || entry['inativo'] != true)) {
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
                                  onLongPress: () async {
                                    await _shownewlogdialog(equip, context);
                                    await _loadSetoresComEquipamentos();
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
