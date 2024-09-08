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
  static DbCollection? proyectCollection;
  static DbCollection? questionCollection;
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
      db ??= await Db.create(dotenv.env['MONGO_CONN_URL_ATLAS_PUBLIC']!);
      if (kDebugMode) {
        print(
            "Base de datos conectada con ${dotenv.env['MONGO_CONN_URL_ATLAS_PUBLIC']}");
      }
      if (!db!.isConnected) {
        await db!.open();
        print("Base de datos abierta y conectada");
      }

      userCollection = db!.collection(dotenv.env['USER_COLLECTION']!);
      blurryCollection = db!.collection(dotenv.env['BLURRY_COLLECTION']!);
      proyectCollection = db!.collection(dotenv.env['PROYECT_COLLECTION']!);
      questionCollection = db!.collection(dotenv.env['QUESTION_COLLECTION']!);

      await proyectCollection!.createIndex(keys: {'ID': 1}, unique: true);
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

      if (proyectCollection != null) {
        print('Coleccion obtenida e iniciada.');
      } else {
        print('Fallo al obtener la coleccion.');
      }
      if (proyectCollection == null) {
        throw Exception('Collection is not initialized en el getData');
      }
      final data = await proyectCollection!.find().toList();

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
          //Registrando un nuevo usuario
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
          'now': data["now"],
          'gender': data["gender"],
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
  static Future<List<Map<String, dynamic>>?> blurry() {
    return execute((db) async {
      try {
        if (proyectCollection != null) {
          print('Coleccion obtenida e iniciada.');
        } else {
          print('Fallo al obtener la coleccion blurry.');
        }
        if (proyectCollection == null) {
          throw Exception('Collection is not initialized en el getData');
        }
        final data = await proyectCollection!.find().toList();

        // Obtener un documento aleatorio
        final randomIndex = Random().nextInt(data.length);
        final randomDocument = data[randomIndex];

        // Obtener el array del documento aleatorio (cambia 'arrayField' al nombre real de tu campo de array)
        final elemento = randomDocument['Nombre'];
        final elemento2 = randomDocument['ID'];

        Set<Map<String, dynamic>> data2 = {
          {
            "Nombre": elemento,
            "ID": elemento2,
          }
        };
        return data2.toList();
      } catch (e) {
        print("El error fue: $e");
        return null;
      }
    });
  }

  static Future<Map<String, dynamic>> collectionProyectInformation(int id) {
    return execute((db) async {
      try {
        if (proyectCollection == null || questionCollection == null) {
          throw Exception('Las colecciones no están inicializadas');
        }

        final query = where.eq('ID', id);
        final proyecto = await proyectCollection!.findOne(query);

        if (proyecto == null) {
          print('No se encontró ningún proyecto con el ID: $id');
          return {};
        }

        // Buscar las preguntas asociadas al proyecto
        final preguntasQuery = where.eq('proyectoId', id);
        final preguntasDoc = await questionCollection!.findOne(preguntasQuery);

        List<Map<String, dynamic>> preguntas = [];
        if (preguntasDoc != null && preguntasDoc['preguntas'] != null) {
          preguntas =
              List<Map<String, dynamic>>.from(preguntasDoc['preguntas']);
        }

        return {
          "Nombre": proyecto['Nombre'] as String? ?? '',
          "ID": proyecto['ID'] as int? ?? 0,
          "Descripción": proyecto['Descripción'] as String? ?? '',
          "Tipo de Aplicación": proyecto['Tipo de Aplicación'] as String? ?? '',
          "Área": proyecto['Área'] as String? ?? '',
          "Objetivos": proyecto['Objetivos'] as String? ?? '',
          "Especialidades Requeridas":
              proyecto['Especialidades Requeridas'] as String? ?? '',
          "Estado": proyecto['Estado'] as String? ?? '',
          "Tiempo de Desarrollo":
              proyecto['Tiempo de Desarrollo'] as String? ?? '',
          "Preguntas": preguntas,
        };
      } catch (e) {
        print("Error al buscar el proyecto: $e");
        return {};
      }
    });
  }

  static Future<bool> submitFormWithAnswers(
      String email, int proyectId, List<Map<String, dynamic>> respuestas) {
    return execute((db) async {
      try {
        final userQuery = where.eq('email', email);
        final user = await userCollection!.findOne(userQuery);
        if (user == null) {
          throw Exception('El usuario no existe');
        }

        final projectQuery = where.eq('ID', proyectId);
        final project = await proyectCollection!.findOne(projectQuery);
        if (project == null) {
          throw Exception('El proyecto no existe');
        }

        // Verificar si el usuario ya está en este proyecto
        final List<dynamic> userProjects = user['proyectos'] ?? [];
        if (userProjects.contains(proyectId)) {
          print("El usuario ya está en este proyecto");
          return false;
        }

        // Verificar si el proyecto ya está lleno
        final int integrantes = project['Integrantes'] ?? 0;
        final int dispuestos = project['Dispuestos'] ?? 0;
        if (dispuestos >= integrantes) {
          print("El proyecto ya está lleno");
          return false;
        }

        // Actualizar usuario
        await userCollection!.updateOne(
            userQuery, modify.set('proyectos', [...userProjects, proyectId]));

        // Actualizar proyecto
        final List<dynamic> projectParticipants =
            project['Participantes'] ?? [];
        await proyectCollection!.updateOne(
            projectQuery,
            modify.set('Participantes', [...projectParticipants, email]).inc(
                'Dispuestos', 1));

        // Guardar respuestas
        final preguntasQuery = where.eq('proyectoId', proyectId);
        await questionCollection!.updateOne(
            preguntasQuery,
            modify.push('respuestas',
                {'usuarioEmail': email, 'respuestas': respuestas}));

        print("Formulario y respuestas enviados con éxito");
        return true;
      } catch (e) {
        print("Error al enviar formulario y respuestas: $e");
        return false;
      }
    });
  }

  static Future<List<dynamic>> getProyectList(String email) async {
    return execute(
      (db) async {
        try {
          final query = where.eq('email', email);
          final user = await userCollection!.findOne(query);

          if (user == null) {
            throw Exception('Usuario no encontrado');
          }

          final proyectos = user['proyectos'] ?? [];

          return proyectos;
        } catch (e) {
          print('Error en getProyectList: $e');
          return [];
        }
      },
    );
  }

  static Future<bool> deleteProyect(int proyectId) async {
    return execute(
      (db) async {
        try {
          final query = where.eq('ID', proyectId);
          final project = await proyectCollection!.findOne(query);
          if (project == null) {
            throw Exception('Proyecto no encontrado');
          }

          await proyectCollection!.deleteOne(query);
          return true;
        } catch (e) {
          print('Error en deleteProyect: $e');
          return false;
        }
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getAdminData() async {
    return execute((db) async {
      try {
        // Primero, obtenemos todos los proyectos
        var projects = await proyectCollection!.find().toList();

        // Luego, para cada proyecto, buscamos la información de los participantes
        var result = await Future.wait(projects.map((project) async {
          var participantEmails = project['Participantes'] as List? ?? [];
          var participantInfos = await userCollection!
              .find(where.oneFrom('email', participantEmails))
              .toList();

          // Mapeamos la información de los participantes al formato deseado
          var mappedParticipants = participantInfos
              .map((p) => {
                    'username': p['userName'],
                    'name': p['name'],
                    'phone': p['phone'],
                    'email': p['email'],
                    'birthdate': p['birthdate'],
                    'gender': p['gender'],
                  })
              .toList();

          // Añadimos la información de los participantes al proyecto
          project['participantesInfo'] = mappedParticipants;
          return project;
        }));

        print("Número de proyectos obtenidos: ${result.length}");

        for (var project in result) {
          print("Proyecto ID: ${project['ID']}");
          print(
              "Número de participantes: ${project['participantesInfo'].length}");
        }

        return result;
      } catch (e) {
        print('Error al obtener datos de proyectos para admin: $e');
        return [];
      }
    });
  }

  static Future<int> generateSequentialId() async {
    return execute((db) async {
      try {
        // Buscar el proyecto con el ID más alto
        var highestProject = await proyectCollection!
            .find(where.sortBy('ID', descending: true))
            .toList();

        // Si no hay proyectos, empezar desde 1
        if (highestProject.isEmpty) {
          return 1;
        }

        // Tomar el ID más alto y sumarle 1
        int highestId = highestProject.first['ID'];
        return highestId + 1;
      } catch (e) {
        print('Error al generar ID secuencial: $e');
        // En caso de error, generar un ID basado en el timestamp actual
        return DateTime.now().millisecondsSinceEpoch;
      }
    });
  }

  static Future<bool> createProjectWithQuestions(
      Map<String, dynamic> projectData, List<String> questions) async {
    return execute((db) async {
      if (questions.length < 3) {
        throw Exception(
            'Se requieren al menos 3 preguntas para crear un proyecto.');
      }

      try {
        // Buscar el proyecto con el ID más alto
        var highestProject = await proyectCollection!
            .find(where.sortBy('ID', descending: true))
            .toList();

        // Tomar el ID más alto y sumarle 1
        int highestId = highestProject.first['ID'];
        // Generar el nuevo ID
        int newId = highestId + 1;

        // Crear el proyecto
        var projectDoc = {
          '_id': ObjectId(),
          'ID': newId,
          'Nombre': projectData['Nombre'],
          'Tipo de Aplicación': projectData['Tipo de Aplicación'],
          'Área': projectData['Área'],
          'Descripción': projectData['Descripción'],
          'Objetivos': projectData['Objetivos'],
          'Estado': projectData['Estado'],
          'Tiempo de Desarrollo': projectData['Tiempo de Desarrollo'],
          'Integrantes': int.parse(projectData['Integrantes']),
          'Especialidades Requeridas': projectData['Especialidades Requeridas'],
          'Dispuestos': 0,
          'Participantes': [],
        };

        var projectResult = await proyectCollection!.insertOne(projectDoc);

        // Crear las preguntas
        var questionsDoc = {
          'proyectoId': newId,
          'preguntas': questions
              .asMap()
              .entries
              .map((entry) =>
                  {'id': entry.key + 1, 'texto': entry.value, 'tipo': 'texto'})
              .toList(),
          'respuestas': []
        };

        var questionResult = await questionCollection!.insertOne(questionsDoc);

        // Actualizar el proyecto con la referencia a las preguntas
        await proyectCollection!.updateOne(where.eq('_id', projectResult.id),
            modify.set('preguntasId', questionResult.id));

        return true;
      } catch (e) {
        print('Error al crear proyecto con preguntas: $e');
        return false;
      }
    });
  }
}
