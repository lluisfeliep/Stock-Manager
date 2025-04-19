import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stock_manager/user_provider.dart';

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
  Map<String, dynamic> equipamentoData = {'quantidade': 0, 'setoresInfo': []};
  Map<String, dynamic>? userData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    firestore = FirebaseFirestore.instance;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    equipId = args['equipId'];
    if (userData == null) {
      userData = Provider.of<UserProvider>(context).userData;
      _loadEquipamentoNome();
      _loadLog();
    }
  }

  Future<void> showEditEquip() async {
    final TextEditingController nomeController = TextEditingController(
      text: equipamentoNome,
    );
    final userRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userData?["uid"]);
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Editar"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: InputDecoration(
                      labelText: "Nome do equipamento",
                    ),
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
                    String novoNome = nomeController.text.trim();
                    if (novoNome != equipamentoNome) {
                      final docRef = firestore
                          .collection('equipamentos')
                          .doc(equipId);
                      final novaEntrada = {"nome": novoNome};
                      await docRef.update(novaEntrada);

                      await docRef.collection('log').add({
                        'comentario':
                            "Atualizado nome: \nAntigo:\n$equipamentoNome\nNovo:\n$novoNome",
                        'data': DateTime.now(),
                        'user': userRef,
                        'setor': null,
                        'loc': null,
                      });
                      _loadLog();
                      _loadEquipamentoNome();
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

  Future<void> _loadEquipamentoNome() async {
    try {
      DocumentSnapshot equipamentoSnapshot =
          await firestore.collection('equipamentos').doc(equipId).get();

      final dadosEquipamento =
          equipamentoSnapshot.data() as Map<String, dynamic>;
      final String nome = dadosEquipamento['nome'] ?? 'Nome Desconhecido';
      final List<dynamic> setores = dadosEquipamento['setores'] ?? [];

      List<Map<String, dynamic>> setoresInfo = [];
      int quantidadeTotalCalculada = 0;

      for (var entry in setores) {
        try {
          DocumentReference ref;

          final refData = entry['ref'];
          if (refData is DocumentReference) {
            ref = refData;
          } else if (refData is Map && refData.containsKey('_path')) {
            ref = FirebaseFirestore.instance.doc(refData['_path']);
          } else {
            continue;
          }

          final setorSnap = await ref.get();
          final setorNome = setorSnap['nome'];

          final pathParts = ref.path.split('/');
          final salaId = pathParts[1];

          final salaSnap =
              await firestore.collection('salas').doc(salaId).get();
          final salaNome = salaSnap['nome'];

          int quantidade = entry['quantidade'] ?? 0;
          quantidadeTotalCalculada += quantidade;

          setoresInfo.add({
            'sala': salaNome,
            'setor': setorNome,
            'quantidade': quantidade,
            'loc': entry['loc'] ?? '',
          });
        } catch (e) {
          _showErrorDialog("Erro ao carregar setor: $e");
          continue;
        }
      }

      setState(() {
        equipamentoNome = nome;
        equipamentoData = {
          'quantidade': quantidadeTotalCalculada,
          'setoresInfo': setoresInfo,
        };
      });
    } catch (e) {
      _showErrorDialog("Erro ao carregar equipamento: $e");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
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
        var setorRef = doc['setor'];
        String username = '';
        String setor = '';
        String sala = '';

        if (userRef is DocumentReference) {
          DocumentSnapshot userSnapshot = await userRef.get();
          username =
              userSnapshot.exists
                  ? userSnapshot['username'] ?? ''
                  : 'Usuário desconhecido';
        }

        if (setorRef is DocumentReference) {
          // Pega o nome do setor
          DocumentSnapshot setorSnapshot = await setorRef.get();
          setor =
              setorSnapshot.exists
                  ? setorSnapshot['nome'] ?? ''
                  : 'Setor desconhecido';

          // Sobe um nível e pega o nome da sala
          DocumentReference salaRef =
              setorRef
                  .parent
                  .parent!; // sobe de /setores/setor_3 para /salas/sala_1
          DocumentSnapshot salaSnapshot = await salaRef.get();
          sala =
              salaSnapshot.exists
                  ? salaSnapshot['nome'] ?? ''
                  : 'Sala desconhecida';
        }

        var rawDate = doc['data'];
        String dataFormatada = '';
        String horaFormatada = '';
        if (rawDate is Timestamp) {
          DateTime date = rawDate.toDate();
          dataFormatada = DateFormat('dd/MM/yyyy').format(date);
          horaFormatada = DateFormat('HH:mm').format(date);
        } else if (rawDate is String) {
          // Se você salvar a string já formatada, pode separar via substring
          dataFormatada = rawDate.split(' ')[0];
          horaFormatada = rawDate.split(' ')[1];
        }

        String salaOuGeral = (sala.isEmpty && setor.isEmpty) ? "Geral" : sala;
        String setorOuVazio = (sala.isEmpty && setor.isEmpty) ? "" : setor;

        tempLogs.add({
          'comentario': doc['comentario'] ?? '',
          'data': dataFormatada,
          'hora': horaFormatada,
          'user': username,
          'setor': setorOuVazio,
          'sala': salaOuGeral,
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
      body: Container(
        color: Color(0xFFDDFFF7),
        padding: EdgeInsets.all(10),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFF319FBD),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              equipamentoNome,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Center(child: Icon(Icons.image, size: 300)),
                          SizedBox(height: 10),
                          Text(
                            "Quantidade total: ${equipamentoData['quantidade']}",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Distribuição por setor:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          ...List.generate(
                            (equipamentoData['setoresInfo'] as List).length,
                            (index) {
                              final setor =
                                  equipamentoData['setoresInfo'][index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text(
                                  "${setor['sala']} / ${setor['setor']} - ${setor['loc']} (Qtd: ${setor['quantidade']})",
                                  style: TextStyle(fontSize: 15),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  child: Container(
                    color: Color(0xFF319FBD),
                    padding: EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Text("Log", style: TextStyle(fontSize: 25)),
                  ),
                  minHeight: 50,
                  maxHeight: 50,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  child: Container(
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
                              'Localização',
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
                  minHeight: 40,
                  maxHeight: 40,
                ),
              ),
            ];
          },
          body: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return Container(
                color: index % 2 == 0 ? Color(0xFF9FD9E8) : Color(0xFF77C8DE),
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            logs[index]["comentario"],
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Por: ${logs[index]["user"]}",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            logs[index]["sala"],
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            logs[index]["setor"],
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            logs[index]["data"],
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            logs[index]["hora"],
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF319FBD),
        child: Icon(Icons.edit),
        onPressed: () {
          showEditEquip();
        },
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}
