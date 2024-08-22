import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart';

//Esta clase es la que hace todo el trabajo con la base de datos. El unico detalle son las variables
//que guarda y no estoy seguro si esta bien con respecto a la Seguridadd.
//Explicare brevente cada función, para no tener inconvenientes.
Completer<void>? _connectionCompleter;

class MongoDataBase {
  static Db? db;
  static DbCollection? userCollection;
  static DbCollection? blurryCollection;
  static String?
      email_; //No estoy seguro si poner esto aca o en el SharedPreferences,
  //por lo que un usuario puede tener maximo 5 cuentas
  static String?
      password_; //Peor esto, no se si hay temas de seguridad que apliquen guardar la contraseña aca

  //Este sera un prototipo para ver si funciona para
  //cerrar la conexion conn la base de datos y no mantenerla abierta

  // Función envolvente para ejecutar operaciones de base de datos

  // Método para ejecutar operaciones con la base de datos y cerrarla después de cada operación
  static final Queue<Completer<void>> _operationQueue = Queue();

  // Función de conexión
  static Future<void> connect() async {
    if (db != null && db!.isConnected) {
      print("La base de datos ya está conectada");
      return;
    }

    if (_connectionCompleter != null) {
      // Si ya hay una conexión en progreso, esperamos a que termine
      await _connectionCompleter!.future;
      return;
    }

    _connectionCompleter = Completer<void>();

    try {
      await dotenv.load();
      db ??= await Db.create(dotenv.env['MONGO_CONN_URL']!);
      if (!db!.isConnected) {
        await db!.open();
        print("Base de datos abierta y conectada");
      }

      userCollection = db!.collection(dotenv.env['USER_COLLECTION']!);
      blurryCollection = db!.collection(dotenv.env['BLURRY_COLLECTION']!);

      if (userCollection != null) {
        print('Collection initialized successfully.');
      } else {
        print('Failed to initialize collection.');
      }

      _connectionCompleter!.complete();
    } catch (e, stackTrace) {
      print('Error al conectar la base de datos: $e');
      print('Stack trace: $stackTrace');
      _connectionCompleter!.completeError(e);
      rethrow;
    } finally {
      _connectionCompleter = null;
    }
  }

  // Función para cerrar la conexión
  static Future<void> closeConnection() async {
    if (db != null && db!.isConnected) {
      await db!.close();
      print("Conexión a MongoDB cerrada.");
    }
  }

  // Función para ejecutar las operaciones de manera secuencial
  static Future<T> execute<T>(Future<T> Function(Db db) operation) async {
    final completer = Completer<void>();
    _operationQueue.add(completer);

    // Espera a que todas las operaciones previas en la cola se completen
    if (_operationQueue.length > 1) {
      await _operationQueue.elementAt(_operationQueue.length - 2).future;
    }

    if (db == null || !db!.isConnected) {
      await connect();
    }

    try {
      final result = await operation(db!);
      return result;
    } catch (e) {
      print("Error durante la operación de base de datos: $e");
      rethrow;
    } finally {
      await closeConnection();

      // Completa la operación actual y remuévela de la cola
      completer.complete();
      _operationQueue.remove(completer);
    }
  }

//Esto trae la lista de 'userCollection', no tiene tanto misterio
  static Future<List<Map<String, dynamic>>> getData() async {
    return execute((db) async {
      if (db.isConnected) {
        print("base de datos abierta {getData}");
      }
      userCollection = db.collection(dotenv.env['USER_COLLECTION']!);

      if (userCollection != null) {
        print('Coleccion obtenida e iniciada.');
      } else {
        print('Fallo al obtener la coleccion.');
      }
      if (userCollection == null) {
        throw Exception('Collection is not initialized en el getData');
      }
      final data = await userCollection!.find().toList();

      // Procesar las imágenes
      return data.map((doc) {
        if (doc['profileImage'] != null && doc['profileImage'] is Map) {
          final imageData = doc['profileImage']['data'];
          if (imageData != null && imageData is String) {
            // Decodificar la imagen de base64 a bytes
            final bytes = base64Decode(imageData);
            // Crear una imagen desde los bytes
            doc['decodedImage'] = Image.memory(Uint8List.fromList(bytes));
            // También guardamos los bytes por si los necesitas
            doc['imageBytes'] = bytes;
          }
          print(
              "Datos obtenidos: ${data.length} registros"); // Añade un log para verificar la cantidad de datos
        }
        return doc;
      }).toList();
    });
  }

//La funcion 'sesion' tiene dos funciones dentro gracias al bool 'selector', lo que pasa es que si el
//usuario esta intentando REGISTRARSE, va a ser true y prosiguiente a eso,
//y esta INICIANDO SESION sera false.
  static Future<bool> sesion(Map<String, dynamic> data, bool selector) async {
    return execute((db) async {
      try {
        if (data["email"] is! String) {
          throw ArgumentError("El correo debe ser un String");
        } else if (data["password"] is! String) {
          throw ArgumentError("La contraseña debe ser un String");
        } else {
          if (kDebugMode) {
            print("Ambos son String");
          }
        }
        var existingUser =
            await userCollection!.findOne({"email": data["email"]});
        if (kDebugMode) {
          print("Datos a insertar o verificar: $data");
        }
        if (selector) {
          //              Registrando un nuevo usuario
          if (existingUser == null) {
            // Si no existe, inserta el nuevo usuario
            // await userCollection?.insertOne(data);
            // en ves de eso vamos asignar valores a email_ y password_ (arriba)
            email_ = data["email"];
            password_ = data["password"];
            return true; // Indica que la inserción fue exitosa
          } else {
            // Si existe, no realiza la inserción
            return false; // Indica que la inserción falló debido a correo duplicado
          }
        } else {
          //              Iniciando sesión
          //Si el usuario existe con dicho "correo", se verificara con el que le mandamos igualmente
          //si es la misma contraseña: data["password"] == existingUser["password"]
          if (existingUser != null &&
              existingUser["password"] == data["password"]) {
            if (kDebugMode) {
              print(
                  'Las credenciales del que se esta comparando son, password: ${existingUser["password"]} y correo: ${existingUser["email"]}');
            }
            if (kDebugMode) print("Inicio de sesión exitoso");
            // Si el usuario existe y la contraseña coincide...
            return true; // Inicio de sesión exitoso
          } else {
            if (kDebugMode) print("Inicio de sesion fallido");
            return false; // Inicio de sesión fallido
          }
        }
      } catch (e, stacktrace) {
        if (kDebugMode) {
          print(
              'Error durante la inserción o verificación: $e \n Stacktrace: $stacktrace');
        }
        return false; // Error durante la inserción o verificación
      }
    });
  }

  //Esta funcion registra un usuario nuevo desde el UserData.dart (la anterior función
  //solamente enviaba el 'email' y el 'password', acá es donde envia los datos completos para el REGISTRO)
  static Future<bool> insertDataRegister(
    XFile? image,
    Map<String, dynamic> data,
  ) async {
    return execute((db) async {
      try {
        print("Conectado a la base de datos");
        final base64Image;
        if (image != null) {
          print("Insertaste una imaegn");
          final bytes = await image.readAsBytes();
          base64Image = base64Encode(bytes);
          print("Imagen codificada en base64");
        } else {
          print("Registrando sin imagen");
          base64Image = null;
        }
        final dataComplete = {
          'email': email_,
          'password': password_,
          'profileImage': {
            'filename': 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            'data': base64Image,
            'uploadDate': DateTime.now(),
          },
          'name': data["name"],
          'userName': data["userName"],
          'phone': data["phone"],
          'birthdate': data["birthdate"],
          'now': data["now"]
        };
        if (kDebugMode) {
          print("Buscando usuario con el userName: ${data['userName']}");
          print("Buscando usuario con el phone: ${data['phone']}");
          print("Buscando usuario con correo: $email_");
        }
        var emailExists =
            await userCollection!.findOne(where.eq('email', email_!));
        var userNameExists = await userCollection!
            .findOne(where.eq('userName', data['userName']));
        var phoneExists =
            await userCollection!.findOne(where.eq('phone', data['phone']));
        if (emailExists != null) {
          print(emailExists);
          print("Se encontro otro usuario con el email: $email_");
          return false;
        }
        if (userNameExists != null) {
          print(
              "Se encontro otro usuario con el userName: ${data['userName']}");
          return false;
        }
        if (phoneExists != null) {
          print("Se encontro otro usuario con el phone: ${data['phone']}}");
          return false;
        }
        await userCollection?.insertOne(dataComplete);

        return true;
      } catch (e) {
        print("Error durante la insercion: $e");
        return false;
      }
    });
  }

  //Esta funciona decodifica la imagen que se envio en 'base64Decode',
  //estoy pensando enviarle el emial para buscarlo, ya que un usuario puede tener varias (max. 5) cuentas
  static Future<Uint8List?> downloadImage() async {
    return execute((db) async {
      try {
        final user = await userCollection!.findOne(where.eq('email', email_));

        if (user != null && user['profileImage'] != null) {
          final base64Image = user['profileImage']['data'];
          return base64Decode(base64Image);
        }

        return null;
      } catch (e) {
        print("Error downloading image: $e");
        return null;
      }
    });
  }

//Esta funcion servia para lo que esta comentado en el body.dart
  static Future<Map<String, dynamic>?> download(String email) async {
    return execute((db) async {
      try {
        if (kDebugMode) print("Intentando download");
        final user = await userCollection!.findOne(where.eq('email', email));
        final bytes;
        if (user != null && user['profileImage'] != null) {
          print(
              "Se encontro la imagen || user no es nulo y [profileImage] tampoco");
          if (user['userName'] != null) {
            print("Se encontro el nombre del usuario");
            if (user['profileImage']['data'] != null) {
              final base64Image = user['profileImage']['data'];
              bytes = base64Decode(base64Image);
            } else {
              print("El data del profileImage es nula en este usuario");
              bytes = null;
            }
            print(
                "La descarga de la imagen y el nombre del usuario se esta devolvienedo correctamente");
            Map<String, dynamic> data = {
              'userName': user['userName'],
              'image': bytes,
            };
            return data;
          }
        }
        return null;
      } catch (e) {
        print("Error downloading image: $e");
        return null;
      }
    });
  }

  static Future<Map<String, dynamic>?> userProfile(String email) {
    return execute((db) async {
      try {
        if (kDebugMode) {
          print(
              "UserProfile() de db.dart en ejecucion------------------------------");
        }
        Map<String, dynamic> data = {};
        final info = await userCollection!.findOne(where.eq('email', email));
        if (info != null) {
          data = {
            "image": info['profileImage']['data'],
            "name": info['name'],
            "userName": info['userName'],
            "phone": info['phone'],
            "birthdate": info['birthdate'],
            "now": info['now']
          };
          return data;
        } else {
          if (kDebugMode) print("info no tiene nada (UserProfile by db.dart)");
        }
        if (kDebugMode) {
          print(
              "---------------------------------------------------------------------");
        }
        return data;
      } catch (e) {
        if (kDebugMode) {
          print(
              "Error en la función UserProfile-----------------------------------------");
        }
        return null;
      }
    });
  }

  //Este sera un metodo para recibir de una coleccion las diferentes frases
  static Future<String?> blurry() {
    return execute((db) async {
      try {
        if (blurryCollection != null) {
          print('Coleccion obtenida e iniciada.');
        } else {
          print('Fallo al obtener la coleccion blurry.');
        }
        if (blurryCollection == null) {
          throw Exception('Collection is not initialized en el getData');
        }
        final data = await blurryCollection!.find().toList();

        // Obtener un documento aleatorio
        final randomIndex = Random().nextInt(data.length);
        final randomDocument = data[randomIndex];

        // Obtener el array del documento aleatorio (cambia 'arrayField' al nombre real de tu campo de array)
        final array = randomDocument['blurry'];

        // Asegúrate de que el campo es un array y no está vacío
        if (array is List && array.isNotEmpty) {
          // Seleccionar un elemento aleatorio del array
          final randomElementIndex = Random().nextInt(array.length);
          final randomElement = array[randomElementIndex];

          print('Elemento aleatorio del array: $randomElement');
          return randomElement;
        } else {
          print('El campo no es un array o está vacío.');
          return null;
        }
      } catch (e) {
        print("El error fue: $e");
        return null;
      }
    });
  }
}
