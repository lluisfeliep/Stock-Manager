import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/drawer.dart';
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
  ) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userData?["uid"]);

    await FirebaseFirestore.instance
        .collection('salas')
        .doc(salaId)
        .collection('setores')
        .doc(setorId)
        .collection('equipamentos')
        .add({'nome': nome, 'loc': local, 'data': DateTime.now()})
        .then((DocumentReference docRef) async {
          await docRef.collection("log").add({
            'comentario': 'Criado novo equipamento',
            'data': DateTime.now(),
            'user': userRef,
          });
        });
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
    final String id = args["id"] as String;
    try {
      QuerySnapshot setoresSnapshot =
          await firestore
              .collection('salas')
              .doc(id)
              .collection('setores')
              .get();

      List<Map<String, dynamic>> tempList = [];

      for (var setorDoc in setoresSnapshot.docs) {
        String setorNome = setorDoc['nome'];
        String setorId = setorDoc.id;

        QuerySnapshot equipamentosSnapshot =
            await firestore
                .collection('salas')
                .doc(id)
                .collection('setores')
                .doc(setorId)
                .collection('equipamentos')
                .get();

        List<Map<String, dynamic>> equipamentos =
            equipamentosSnapshot.docs
                .map(
                  (equipDoc) => {
                    'nome': equipDoc['nome'],
                    'loc': equipDoc['loc'],
                  },
                )
                .toList();

        tempList.add({
          'setorNome': setorNome,
          'setorId': setorId,
          'equipamentos': equipamentos,
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
      drawer: CustomDrawer(),
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
                                (equip) => ListTile(
                                  title: Text(equip['nome']),
                                  subtitle: Text(
                                    'Localização: ${equip['loc']}',
                                  ),
                                  leading: Icon(Icons.build),
                                ),
                              )
                              .toList(),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF63bfd8),
        onPressed: _showNewEquip,
        child: Icon(Icons.add),
      ),
    );
  }
}
