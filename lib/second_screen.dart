import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miembros/mongoDB/db.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Second Screen',
          style: TextStyle(color: Colors.white, fontFamily: 'nuevo'),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 29.0,
          ), // Ajusta el valor según necesites
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              if (kDebugMode) {
                if (MongoDataBase.db!.isConnected) {
                  print("db esta conectado ${MongoDataBase.db}");
                } else {
                  print("db no esta conectado");
                }
              }
              Navigator.pop(context, true);
            },
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Second Screen!',
          style:
              TextStyle(fontSize: 24, color: Colors.white, fontFamily: 'nuevo'),
        ),
      ),
    );
  }
}
