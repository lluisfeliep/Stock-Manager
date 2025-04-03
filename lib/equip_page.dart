import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/drawer.dart';
import 'package:stock_manager/user_provider.dart';

class EquipPage extends StatefulWidget {
  @override
  _EquipPageState createState() => _EquipPageState();
}

class _EquipPageState extends State<EquipPage> {
  late String id;
  late Map<String, dynamic> userData;
  late FirebaseFirestore firestore;
  bool isLoading = true;
  List<Map<String, dynamic>> setoresComEquipamentos = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userData = Provider.of<UserProvider>(context).userData;
    id = userData?["id"]; // Pegando o ID do usuário
    firestore = FirebaseFirestore.instance;
    _loadSetoresComEquipamentos();
  }

  Future<void> _loadSetoresComEquipamentos() async {
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

        tempList.add({'setorNome': setorNome, 'equipamentos': equipamentos});
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
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
