import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/mongoDB/db.dart';
import 'MyHomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Cargar el archivo .env

  await MongoDataBase.connect();
  //Esto solamente hace que la aplicacion sea inmersiva, enfocada en solamente la misma
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blurry',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom:
                  Radius.circular(0), // Ajusta el radio según tu preferencia
            ),
          ),
        ),
        scaffoldBackgroundColor: AppColors.secondaryColor,
      ),
      home: const Myhomepage(),
    );
  }
}
