import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_manager/drawer.dart';
import 'package:intl/intl.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late String salaId;
  late String setorId;
  late String equipId;
  late FirebaseFirestore firestore;
  List<Map<String, dynamic>> logs = [];
  String equipamentoNome = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    firestore = FirebaseFirestore.instance;

    // Recebe os argumentos passados
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    equipId = args['equipId'];
    _loadEquipamentoNome();
    _loadLog();
  }

  Future<void> _loadEquipamentoNome() async {
    try {
      DocumentSnapshot equipamentoSnapshot =
          await firestore.collection('equipamentos').doc(equipId).get();

      setState(() {
        equipamentoNome = equipamentoSnapshot['nome'] ?? 'Nome Desconhecido';
      });
    } catch (e) {
      _showErrorDialog("Erro ao carregar equipamento: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Erro"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> _loadLog() async {
    try {
      QuerySnapshot logsnapshot =
          await firestore
              .collection('equipamentos')
              .doc(equipId)
              .collection('log')
              .orderBy('data', descending: true)
              .get();

      List<Map<String, dynamic>> tempLogs = [];

      for (var doc in logsnapshot.docs) {
        var userRef = doc['user'];
        String username = '';

        if (userRef is DocumentReference) {
          DocumentSnapshot userSnapshot = await userRef.get();
          username =
              userSnapshot.exists
                  ? userSnapshot['username'] ?? ''
                  : 'Usuário desconhecido';
        }

        var rawDate = doc['data'];
        String formattedDate = '';
        if (rawDate is Timestamp) {
          formattedDate = DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(rawDate.toDate());
        } else if (rawDate is String) {
          formattedDate = rawDate;
        }

        tempLogs.add({
          'comentario': doc['comentario'] ?? '',
          'data': formattedDate,
          'user': username,
        });
      }

      setState(() {
        logs = tempLogs;
      });
    } catch (e) {
      _showErrorDialog("Erro ao carregar logs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(equipamentoNome),
        backgroundColor: Color(0xFF63bfd8),
      ),
      drawer: CustomDrawer(),
      body: Container(
        color: Color(0xFFDDFFF7),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF287D94),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(12),
              child: Center(
                child: Column(
                  children: [
                    Text(equipamentoNome, style: TextStyle(fontSize: 20)),
                    Icon(Icons.image, size: 300),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              color: Color(0xFF319FBD),
              width: double.infinity,
              child: Center(child: Text("Log", style: TextStyle(fontSize: 30))),
            ),
            Container(
              color: Color(0xFF319FBD),
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Comentario',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Data',
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
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Container(
                    color:
                        index % 2 == 0 ? Color(0xFF9FD9E8) : Color(0xFF77C8DE),
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Center(
                          child: Flexible(
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    logs[index]["comentario"],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Por: ${logs[index]["user"]}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Flexible(
                            child: Center(
                              child: Text(
                                logs[index]["data"],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
