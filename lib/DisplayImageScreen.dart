import 'package:flutter/material.dart';
import 'package:miembros/MyHomePage.dart';
import 'dart:typed_data';

import 'package:miembros/mongoDB/db.dart';

class DisplayImageScreen extends StatefulWidget {
  final String email = MongoDataBase.email_!;

  DisplayImageScreen({super.key});

  @override
  _DisplayImageScreenState createState() => _DisplayImageScreenState();
}

class _DisplayImageScreenState extends State<DisplayImageScreen> {
  Uint8List? imageData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      isLoading = true;
    });

    final downloadedImage = await MongoDataBase.downloadImage();

    setState(() {
      imageData = downloadedImage;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Imagen de Perfil',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(
              left: 23.0), // Ajusta el valor según necesites
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Myhomepage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : imageData != null
                ? Image.memory(imageData!)
                : const Text('No se encontró ninguna imagen'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadImage,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
