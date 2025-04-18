import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> dados = [];

  void _showRegisterDialog() {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    bool isAdmin = false;
    bool isPSala = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Cadastrar Usuário'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[a-zA-Z0-9]+$'),
                      ),
                    ],
                    decoration: InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Password'),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isAdmin,
                        onChanged: (value) {
                          setState(() => isAdmin = value!);
                        },
                      ),
                      Text('Admin'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isPSala,
                        onChanged: (value) {
                          setState(() => isPSala = value!);
                        },
                      ),
                      Text('PSala'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String username = usernameController.text.trim();
                    String password = passwordController.text.trim();
                    if (username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Preencha todos os campos!')),
                      );
                      return;
                    }

                    try {
                      String email = "$username@example.com";

                      // Criar usuário no Firebase Auth
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                      String uid = userCredential.user!.uid;

                      // Salvar no Firestore com as permissões
                      await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(uid)
                          .set({
                            "username": username,
                            "Admin": isAdmin,
                            "PSala": isPSala,
                          });

                      Navigator.pop(context); // Fecha o diálogo
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Usuário cadastrado com sucesso!'),
                        ),
                      );
                      _buscarLogin();
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  },
                  child: Text('Cadastrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void updateUserEmail(String userId, String username) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(userId).get();

    TextEditingController usernameController = TextEditingController(
      text: userDoc["username"],
    );
    bool isAdmin = userDoc["Admin"];
    bool isPSala = userDoc["PSala"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar Usuário'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isAdmin,
                        onChanged: (value) {
                          setState(() => isAdmin = value!);
                        },
                      ),
                      Text('Admin'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isPSala,
                        onChanged: (value) {
                          setState(() => isPSala = value!);
                        },
                      ),
                      Text('PSala'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String newUsername = usernameController.text.trim();
                    if (newUsername.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Preencha o username!')),
                      );
                      return;
                    }

                    try {
                      // Atualiza Firestore
                      await _firestore.collection('Users').doc(userId).update({
                        "username": newUsername,
                        "Admin": isAdmin,
                        "PSala": isPSala,
                      });

                      // Atualiza Firebase Auth (email)
                      final functions = FirebaseFunctions.instance;
                      await functions.httpsCallable('updateUserEmail').call({
                        "uid": userId,
                        "newEmail": "$newUsername@example.com",
                      });

                      Navigator.pop(context);
                      _buscarLogin();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Usuário atualizado com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  },
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUser(String userId) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Excluir Usuário"),
            content: Text("Tem certeza que deseja excluir este usuário?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Excluir"),
              ),
            ],
          ),
    );

    confirmDelete ??= false;

    if (confirmDelete) {
      try {
        // Deleta do Firestore
        await _firestore.collection('Users').doc(userId).delete();

        // Deleta do Firebase Auth
        final functions = FirebaseFunctions.instance;
        await functions.httpsCallable('deleteUser').call({"uid": userId});

        _buscarLogin(); // Atualiza a lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
    _buscarLogin();
  }

  @override
  void initState() {
    super.initState();
    _buscarLogin();
  }

  Future<void> _buscarLogin() async {
    await Future.delayed(Duration(seconds: 1));
    try {
      QuerySnapshot snapshot = await _firestore.collection('Users').get();
      setState(() {
        dados =
            snapshot.docs.map((doc) {
              return {
                "id": doc.id,
                "username": doc["username"] ?? "Sem Nome",
                "Admin": doc["Admin"] ?? false,
                "PSala": doc["PSala"] ?? false,
              };
            }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin'), backgroundColor: Color(0xFF63bfd8)),
      body: Container(
        color: Color(0xFFDDFFF7),
        padding: EdgeInsets.all(10),
        child: RefreshIndicator(
          onRefresh: _buscarLogin,
          child: Column(
            children: [
              // Cabeçalho fixo
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
                          'Nome',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Editar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Apagar',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista rolável das linhas
              Expanded(
                child: ListView.builder(
                  itemCount: dados.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color:
                          index % 2 == 0
                              ? Color(0xFF9FD9E8)
                              : Color(0xFF77C8DE), // Linhas alternadas
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Center(
                              child: Text(
                                dados[index]["username"],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: IconButton(
                                onPressed: () {
                                  updateUserEmail(
                                    dados[index]["id"],
                                    dados[index]["username"],
                                  );
                                },
                                icon: Icon(Icons.edit),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: IconButton(
                                onPressed: () {
                                  _deleteUser(dados[index]["id"]);
                                },
                                icon: Icon(Icons.delete),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF319FBD),
        onPressed: _showRegisterDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
