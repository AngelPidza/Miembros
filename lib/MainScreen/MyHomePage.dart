import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:miembros/ProfileScreen/UserProfile.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/MainScreen/body.dart';
import 'package:miembros/login/login.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Myhomepage extends StatefulWidget {
  const Myhomepage({super.key});

  @override
  State<Myhomepage> createState() => _MyhomepageState();
}

class _MyhomepageState extends State<Myhomepage> {
//Widgets--------------------
  late GlobalKey<BodyState> bodyKey;
//VARIABLES------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController textController = TextEditingController();

  double _opacity = 1.0;
  Timer? _timer;
  List<String> emailList = [];
  bool isLoggedIn = false;
  String userEmail = '';
  Uint8List? _userImageData;
  int n = 0;
  bool isAdmin = false;

  double _scrollOffset = 0.0;
//----------------------------

//override's------------------------------------------------
  @override
  void initState() {
    if (kDebugMode) print("initState del MyhomepageState");
    super.initState();
    bodyKey = GlobalKey<BodyState>();
    _checkLoginStatus();
    _startTimer();
    _getEmailsFromSharedPreferences();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleScroll(double scrollOffset) {
    setState(() {
      _scrollOffset = scrollOffset.clamp(0.0, 100.0);
    });
  }
//-----------------------------------------------------------

//Checkea el estado y devuelve valores si no es nulo
  Future<void> _checkLoginStatus() async {
    _getEmailsFromSharedPreferences();
    if (kDebugMode) {
      print(
          "_checkLoginStatus.running------------------------------------------------------");
    }
    final prefs = await SharedPreferences.getInstance();

    if (kDebugMode) {
      print(
          "SharedPreferences: pref.getBool('isLoggedIn'): \n ${prefs.getBool('isLoggedIn') != null ? 'true' : 'false'}");
      print(
          "SharedPreferences: prefs.getString('email'): \n ${prefs.getString('email') != null ? '${prefs.getString('email')}' : 'email nulo'}");
      print(
          "SharedPreferences: prefs.getString('EmailList'): \n ${prefs.getStringList('EmailList') != null ? '${prefs.getStringList('EmailList')}' : 'emailList nulo'}");
    }

    if (kDebugMode) {
      print(
          " _checkLoginStatus: VERIFICANDO SI EL pref.getBool('isLoggIn') ES NULO: ");
    }
    if (prefs.getBool('isLoggedIn') != null) {
      prefs.getBool('isLoggedIn')!
          ? print("Inicio sesion, verificado")
          : print("No inicio sesion o no existe");
    } else {
      if (kDebugMode) {
        print("no existe ningun isLoggin");
      }
    }

    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    bool admin = prefs.getBool('isAdmin') ?? false;
    if (kDebugMode) {
      print("isAdmin: $admin");
    }
    if (admin) {
      prefs.setBool('isLoggedIn', true);
      setState(() {
        userEmail = 'Admin';
        isLoggedIn = true;
        isAdmin = true;
      });
    } else if (loggedIn) {
      try {
        //Extraer la variable del email del usuario cargado como 'email' del SharedPreferences
        String email = prefs.getString('email')!;
        //Sacando un Map que contiene {userName: ???, image: ???} del usuario
        Map<String, dynamic>? user = await MongoDataBase.download(email);
        final imageData = user!['image'];
        final userName = user['userName'];
        //el setState añade los valores obtenidos a las 'variables de estado'
        setState(() {
          //El (_userImageData), (userEmail) y (isLoggedIn) es una 'variable de estado'
          isLoggedIn = loggedIn;
          userEmail = userName ?? 'usuario';
          _userImageData = imageData;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error al obtener el nombre de usuario: $e');
        }
        setState(() {
          isLoggedIn = false;
          userEmail = 'Error';
        });
      }
    } else {
      setState(() {
        isLoggedIn = false;
        userEmail = 'No logeado';
      });
    }
    if (kDebugMode) {
      print(
          "--------------------------------------------------------------------------------");
    }
  }
//-----------------------------------------------------------

//Funcion para traer un Blurry aleatorio
  Future<List<Map<String, dynamic>>?> textBlurry() async {
    List<Map<String, dynamic>>? data = await MongoDataBase.blurry();
    if (kDebugMode) {
      print('data:  $data');
    }
    return data!;
  }
//-----------------------------------------------------

//TIEMPO DE OPACIDAD DEL BOTON DERECHO INFERIOR
  Future<void> _startTimer() async {
    _timer?.cancel();
    setState(() {
      _opacity = 1;
    });
  }

  void _resetOpacity() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      var number =
          await MongoDataBase.getProyectList(preferences.getString('email')!);
      if (kDebugMode) {
        print(
            '${number.length} es el tamaño de la lista de proyectos del usuario');
      }
      _timer = Timer(const Duration(seconds: 1), () {
        setState(() {
          n = number.length;
          _opacity = 0.5;
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error al resetear la opacidad: $e');
      }
    }
  }
//------------------------------------------------

//REMUEVE EMAILS DE LA LISTA
  Future<void> _removeEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (email == prefs.getString('email')) {
      prefs.remove('email');
      prefs.setBool('isLoggedIn', false);
    }
    setState(() {
      emailList.remove(email);
    });
    await prefs.setStringList('EmailList', emailList);
  }
//-------------------------------------------------

//RECIBIR LOS EMAILS GUARDADOS
  Future<void> _getEmailsFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (kDebugMode) {
        print('EmailList: ${prefs.getStringList('EmailList')}');
      }
      emailList = prefs.getStringList('EmailList') ?? [];
    });
  }
//---------------------------------------------------

//CAMBIO DE USUARIO DESDE DE LA LISTA DE EMAILS GUARDADOS
  Future<void> userChanged(String email) async {
    print("Entrando a userChanged()");
    final cambio = await SharedPreferences.getInstance();
    _checkLoginStatus();
    cambio.setString('email', email);
  }
//----------------------------------------------------

//FUNCION PARA MOSTRAR UN 'PROYECTO' (parte derecha superior de la pantalla)
  void showAnimatedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return SafeArea(
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FutureBuilder<List<Map<String, dynamic>>?>(
                          future: textBlurry(),
                          builder: (BuildContext context,
                              AsyncSnapshot<List<Map<String, dynamic>>?>
                                  snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.secondaryColor,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text('No data available'));
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final data = snapshot.data![index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              AppColors.secondaryColor,
                                          child: Text(
                                            data['ID'].toString(),
                                            style: const TextStyle(
                                              fontFamily: 'nuevo',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20,
                                              color: AppColors.onlyColor,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          data['Nombre'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'nuevo',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            color: AppColors.secondaryColor,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              color: AppColors.onlyColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color.fromARGB(115, 0, 0, 0),
      transitionDuration: const Duration(milliseconds: 600),
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutBack,
            ),
          ),
          child: child,
        );
      },
    );
  }
//-----------------------------------------------------

//FUNCION PARA AÑADIR UN 'PROYECTO'
  void showProjectCreationModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final List<TextEditingController> questionControllers = [
      TextEditingController()
    ];
    final projectDataControllers =
        List.generate(4, (_) => TextEditingController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: Navigator.of(context),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AnimatedBuilder(
              animation: CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeInOut,
              ),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0.0,
                      (1 - ModalRoute.of(context)!.animation!.value) * 400),
                  child: child,
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.81,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Crea tu Proyecto',
                        style: TextStyle(
                          color: AppColors.onlyColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...List.generate(4, (index) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: TextFormField(
                                      controller: projectDataControllers[index],
                                      decoration: InputDecoration(
                                        labelText:
                                            'Dato del proyecto ${index + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Este campo es obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  );
                                }),
                                const Text(
                                  'Preguntas personalizadas (mínimo 3):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onlyColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...questionControllers
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int idx = entry.key;
                                  var controller = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller,
                                            decoration: InputDecoration(
                                              labelText: 'Pregunta ${idx + 1}',
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove,
                                              color: AppColors.errorColor),
                                          onPressed:
                                              questionControllers.length > 3
                                                  ? () {
                                                      setState(() {
                                                        questionControllers
                                                            .removeAt(idx);
                                                      });
                                                    }
                                                  : null,
                                        ),
                                        if (idx ==
                                            questionControllers.length - 1)
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                color: AppColors.primaryColor),
                                            onPressed: () {
                                              setState(() {
                                                questionControllers.add(
                                                    TextEditingController());
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: AppColors.errorColor),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: AppColors.onlyColor,
                              backgroundColor: AppColors.primaryColor,
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                if (questionControllers.length < 3) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Debes añadir al menos 3 preguntas personalizadas.')),
                                  );
                                } else {
                                  List<String> projectData =
                                      projectDataControllers
                                          .map((controller) => controller.text)
                                          .toList();
                                  List<String> questions = questionControllers
                                      .map((controller) => controller.text)
                                      .toList();
                                  print('Datos del proyecto: $projectData');
                                  print('Preguntas personalizadas: $questions');
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            child: const Text('Crear Proyecto'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
//-----------------------------------------------------

//Modal de los Emails para poder cambiar segun guardado en el SharePreferences
  void emailsModal(BuildContext context) async {
    if (emailList.isEmpty) {
      if (kDebugMode) print("la lista está vacía");
      SharedPreferences email = await SharedPreferences.getInstance();
      email.getStringList('EmailList') != null
          ? emailList = email.getStringList('EmailList')!
          : null;
    } else {
      for (var data in emailList) {
        int count = 1;
        if (kDebugMode) print("$count.- $data");
        count++;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: Navigator.of(context),
      ),
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeInOutBack,
          ),
          builder: (context, child) {
            return Transform.scale(
              scale: CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeInOutBack,
              ).value,
              child: child,
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: emailList.isEmpty
                ? const Center(
                    child: Text(
                      'No hay cuentas guardadas',
                      style: TextStyle(
                        color: AppColors.onlyColor,
                        fontFamily: 'nuevo',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: emailList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(
                          Icons.email,
                          color: AppColors.primaryColor,
                        ),
                        title: Text(
                          emailList[index],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'nuevo',
                          ),
                        ),
                        trailing: IconButton(
                          color: AppColors.primaryColor,
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            bool confirmar = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.primaryColor,
                                  title: const Text(
                                    'Advertencia',
                                    style: TextStyle(),
                                  ),
                                  content: const Text(
                                      '¿Estás seguro de que quieres eliminar este correo electrónico?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                            color: AppColors.secondaryColor),
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                            color: AppColors.backgroundColor),
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmar == true) {
                              await _removeEmail(emailList[index]);
                            }
                          },
                        ),
                        onTap: () {
                          userChanged(emailList[index]);
                          if (kDebugMode) {
                            print('Cuenta seleccionada: ${emailList[index]}');
                          }
                          print("Regrese del show en onTops");
                          _checkLoginStatus();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    ).then((_) {
      _checkLoginStatus();
    });
  }
//-----------------------------------------------------

//Funcion para cerrar sesion
  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isAdmin') ?? false) {
      prefs.remove('isAdmin');
      prefs.remove('email');
      prefs.setBool('isLoggedIn', false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cerraste sesion Admin'),
        ),
      );
    } else if (prefs.getBool('isLoggedIn') ?? false) {
      List<String> prefsEmailList = prefs.getStringList('EmailList') ?? [];
      prefsEmailList.remove(prefs.getString('email'));
      prefs.setStringList('EmailList', prefsEmailList);
      prefs.remove('email');
      prefs.setBool('isLoggedIn', false);
      if (kDebugMode) {
        print('Cerraste sesion');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cerraste sesion'),
          ),
        );
      }
    } else {
      final logger = Logger();
      prefs.getString('email') != null
          ? {
              if (kDebugMode)
                logger.d('el email existe: ${prefs.getString('email')}')
            }
          : {
              if (kDebugMode)
                logger.d('el email no existe: ${prefs.getString('email')}')
            };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No iniciaste sesion aún'),
          ),
        );
      }
    }
    _checkLoginStatus();
    bodyKey.currentState!.refreshData();
  }

//WIDGET PADRE------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    //Calculos para la animacion de ocultar el AppBar al scrollear
    double opacityButton = 1.0 - (_scrollOffset / 100);
    double appBarHeight = 200.0 - _scrollOffset;
    double titleFontSize = 30 + (_scrollOffset / 14);
    double titlePositionRight = 124 - (_scrollOffset * 1.1);
    double titlePositionTop = 100 - (_scrollOffset / 1.6);
    //Variables
    const labelStyleFloatingActionButton = TextStyle(
      fontFamily: 'nuevo',
      fontWeight: FontWeight.w700,
    );
    //Return...
    var speedDialChildBackgroundColor = AppColors.secondaryColor;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          height: appBarHeight,
          child: AppBar(
            backgroundColor: AppColors.backgroundColor,
            flexibleSpace: Stack(
              children: [
                Positioned(
                  right: titlePositionRight,
                  top: titlePositionTop,
                  child: Text(
                    'Prorandom',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'nuevo',
                      fontSize: titleFontSize,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: isLoggedIn
                      ? GestureDetector(
                          onTap: () => !isAdmin
                              ? Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 600),
                                    pageBuilder: (_, __, ___) =>
                                        const UserProfile(),
                                    transitionsBuilder:
                                        (_, animation, __, child) {
                                      return ScaleTransition(
                                        scale:
                                            Tween<double>(begin: 0.0, end: 1.0)
                                                .animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutBack,
                                          ),
                                        ),
                                        child: child,
                                      );
                                    },
                                  ),
                                )
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.secondaryColor,
                                  backgroundImage: _userImageData != null
                                      ? MemoryImage(_userImageData!)
                                      : null,
                                  child: _userImageData == null
                                      ? Text(
                                          userEmail[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(
                                    width:
                                        8), // Espacio entre el avatar y el email
                                Text(
                                  userEmail,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        )
                      : TextButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(
                                AppColors.onlyColor),
                            foregroundColor: WidgetStateProperty.all<Color>(
                                AppColors.secondaryColor),
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.white.withOpacity(0.04);
                                }
                                if (states.contains(WidgetState.focused) ||
                                    states.contains(WidgetState.pressed)) {
                                  return Colors.white.withOpacity(0.12);
                                }
                                return null;
                              },
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                            ),
                          ),
                          onPressed: () async {
                            if (!mounted) return;
                            final success = await Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 600),
                                pageBuilder: (_, __, ___) => const LoginPage(),
                                transitionsBuilder: (_, animation, __, child) {
                                  return ScaleTransition(
                                    scale: Tween<double>(begin: 0.0, end: 1.0)
                                        .animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOutBack,
                                      ),
                                    ),
                                    child: child,
                                  );
                                },
                              ),
                            );
                            if (success) {
                              if (kDebugMode) {
                                print("LLEGO CON EXITO");
                              }
                              bodyKey.currentState!.refreshData();
                            }
                            if (kDebugMode) {
                              print("Porque sucess es $success");
                            }
                          },
                          child: const Text(
                            'I/R sesión',
                            style: TextStyle(
                                color: AppColors.backgroundColor,
                                fontFamily: 'nuevo',
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
                Positioned(
                  top: 40,
                  right: 30,
                  child: isLoggedIn
                      ? AnimatedOpacity(
                          opacity: opacityButton,
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            height: 45,
                            width: 45,
                            child: opacityButton > 0.01
                                ? FloatingActionButton(
                                    onPressed: () =>
                                        showAnimatedDialog(context),
                                    backgroundColor: AppColors
                                        .secondaryColor, // Cambia el icono según lo necesites
                                    shape:
                                        const CircleBorder(), // Cambia este color según lo necesites
                                    child: const Icon(
                                      Icons.bolt,
                                      color: AppColors.onlyColor,
                                    ),
                                  )
                                : null,
                          ),
                        )
                      : const Offstage(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Body(
        key: bodyKey,
        callFunction: _checkLoginStatus,
        onScroll: _handleScroll,
      ),
      floatingActionButton: GestureDetector(
        onTap: _resetOpacity,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 300),
          child: SpeedDial(
            activeIcon: Icons.close,
            overlayColor: Colors.black, // Color de la superposición
            overlayOpacity: 0.0, // Opacidad de la superposición
            backgroundColor: AppColors.secondaryColor,
            foregroundColor: Colors.black,
            children: [
              //Boton para salir
              SpeedDialChild(
                backgroundColor: speedDialChildBackgroundColor,
                onTap: () => _signOut(),
                child: const Icon(
                  Icons.login,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                label: 'Salir de la sesion',
                labelBackgroundColor: speedDialChildBackgroundColor,
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),

              //Boton para agregar un proyecto
              ...!isAdmin
                  ? [
                      //Boton de Bandeja de cuentas
                      SpeedDialChild(
                        backgroundColor: speedDialChildBackgroundColor,
                        onTap: () {
                          // final result = await Navigator.push(
                          //   context,
                          //   PageRouteBuilder(
                          //     transitionDuration: const Duration(milliseconds: 600),
                          //     pageBuilder: (_, __, ___) => const SecondScreen(),
                          //     transitionsBuilder: (_, animation, __, child) {
                          //       return ScaleTransition(
                          //         scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                          //           CurvedAnimation(
                          //             parent: animation,
                          //             curve: Curves.easeInOutBack,
                          //           ),
                          //         ),
                          //         child: child,
                          //       );
                          //     },
                          //   ),
                          // );
                          // if (result == true) {
                          //   setState(() {
                          //     if (kDebugMode) {
                          //       print(
                          //           "Estoy en MyHomePage.dart, y el result de la seccond_screen devolvio true");
                          //     }
                          //     _checkLoginStatus();
                          //   });
                          // }
                          //ESTO FUE UNA BUENA MANERA DE IR A UNA PANTALLA Y ME DEVUELVA UN DATO BOOLEANO
                          //SOLO DEBIA PONER EN UN BOTON DE LA OTRA PANTALLA: Navigator.pop(context, true/false);
                          emailsModal(context);
                        },
                        child: const Icon(
                          Icons.add_card,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        label: 'Bandeja de cuentas',
                        labelBackgroundColor: speedDialChildBackgroundColor,
                        labelStyle: labelStyleFloatingActionButton,
                        shape: const CircleBorder(),
                      ),
                      //Boton de Agregar usuarios
                      SpeedDialChild(
                        backgroundColor: speedDialChildBackgroundColor,
                        onTap: () async {
                          final success = await Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 600),
                              pageBuilder: (_, __, ___) => const LoginPage(),
                              transitionsBuilder: (_, animation, __, child) {
                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOutBack,
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                            ),
                          )
                              // APRENDI QUE SI USAS ESTO, NO PUEDES USAR Navigator.pop(context, true/false)
                              // YA QUE, O RECIBE ALGO DE LA PANTALLA SIGUIENTE Y LO ALMACENA (success) O
                              // HACE ALGO EN LA SIGUIENTE PANTALLA, LO TERMINA Y HACE ALGO (.then(_))
                              //
                              // .then((_) {
                              //   if (kDebugMode) {
                              //     print(".then(_): Regresé a Myhomepage.dart");
                              //   }
                              //   _checkLoginStatus();
                              // })
                              //
                              ;
                          if (success) {
                            if (kDebugMode) {
                              print("LLEGO CON EXITO");
                            }
                            bodyKey.currentState?.refreshData();
                          }
                          if (kDebugMode) {
                            print("Porque sucess es $success");
                          }
                        },
                        child: const Icon(
                          Icons.group_add,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 30.0,
                        ),
                        label: 'Agregar Usuario',
                        labelBackgroundColor: speedDialChildBackgroundColor,
                        labelStyle: labelStyleFloatingActionButton,
                        shape: const CircleBorder(),
                      ),
                      //Boton de Cuenta
                      SpeedDialChild(
                        backgroundColor: speedDialChildBackgroundColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 600),
                              pageBuilder: (_, __, ___) => const UserProfile(),
                              transitionsBuilder: (_, animation, __, child) {
                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOutBack,
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.account_circle_outlined,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 31.0,
                        ),
                        label: 'Cuenta',
                        labelBackgroundColor: speedDialChildBackgroundColor,
                        labelStyle: labelStyleFloatingActionButton,
                        shape: const CircleBorder(),
                      ),
                      SpeedDialChild(
                        backgroundColor: speedDialChildBackgroundColor,
                        onTap: () => showProjectCreationModal(context),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.onlyColor,
                          size: 31.0,
                        ),
                        label: 'Proyect.add',
                        labelBackgroundColor: speedDialChildBackgroundColor,
                        labelStyle: labelStyleFloatingActionButton,
                        shape: const CircleBorder(),
                      )
                    ]
                  : [
                      SpeedDialChild(
                        backgroundColor: AppColors.backgroundColor,
                        onTap: () {
                          if (kDebugMode) {
                            print('isAdmin: $isAdmin \n Logiado: $isLoggedIn');
                          }
                        },
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.onlyColor,
                          size: 25.0,
                        ),
                        label: 'Admin y Logeado',
                        labelBackgroundColor: speedDialChildBackgroundColor,
                        labelStyle: labelStyleFloatingActionButton,
                        shape: const CircleBorder(),
                      )
                    ],
            ],
            onOpen: () => _startTimer(),
            onClose: () => _resetOpacity(),
            child: _opacity == 0.5 || isAdmin
                ? const Icon(Icons.view_stream)
                : Text(
                    '$n/3',
                  ),
          ),
        ),
      ),
    );
  }
}
