import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_linking.dart'; // Assurez-vous que le chemin est bon

class HelloUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Récupération de l'instance du Provider
    var contractLink = Provider.of<ContractLinking>(context); // [cite: 349]

    TextEditingController yourNameController =
        TextEditingController(); // [cite: 349]

    return Scaffold(
      appBar: AppBar(
        title: Text("Hello World Dapp"),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
        elevation: 8,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade900, Colors.cyan.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: contractLink.isLoading
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Form(
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white.withOpacity(0.95),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Hello ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                Text(
                                  contractLink.deployedName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                    color: Colors.cyan[700],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: TextFormField(
                                controller: yourNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Your Name",
                                  hintText: "What is your name?",
                                  prefixIcon: Icon(Icons.drive_file_rename_outline, color: Colors.teal[700]),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  child: Text(
                                    'Set Name',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    contractLink.setName(
                                      yourNameController.text,
                                    );
                                    yourNameController.clear();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
