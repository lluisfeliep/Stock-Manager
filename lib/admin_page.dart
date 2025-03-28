import 'package:flutter/material.dart';
import 'package:stock_manager/drawer.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    List<List<String>> dados = [
      ['Ana'],
      ['Carlos'],
      ['Mariana'],
      ['Pedro'],
      ['Lucas'],
      ['Fernanda'],
      ['Juliana'],
      ['Rafael'],
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Admin'), backgroundColor: Color(0xFF63bfd8)),
      drawer: CustomDrawer(
        extraWidgets: [
          GestureDetector(
            child: Container(
              color: Color(0xFF9FD9E8),
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Adicionar Login",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
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
                              dados[index][0],
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
    );
  }
}
