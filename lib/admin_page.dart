import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stock_manager/drawer.dart';

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

  @override
  void initState() {
    super.initState();
    _buscarLogin();
  }

  void _buscarLogin() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Users').get();
      setState(() {
        dados =
            snapshot.docs
                .map((doc) => {"username": doc["username"] ?? "Sem Nome"})
                .toList();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin'), backgroundColor: Color(0xFF63bfd8)),
      drawer: CustomDrawer(),
      body: Container(
        color: Color(0xFFDDFFF7),
        padding: EdgeInsets.all(10),
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
                              onPressed: () {},
                              icon: Icon(Icons.edit),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: IconButton(
                              onPressed: () {},
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF63bfd8),
        onPressed: _showRegisterDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
