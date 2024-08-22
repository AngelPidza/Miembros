import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miembros/UserProfile.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/body.dart';
import 'package:miembros/login/login.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:miembros/second_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Myhomepage extends StatefulWidget {
  const Myhomepage({super.key});

  @override
  State<Myhomepage> createState() => _MyhomepageState();
}

class _MyhomepageState extends State<Myhomepage> {
//VARIABLES------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController textController = TextEditingController();

  double _opacity = 1.0;
  Timer? _timer;
  List<String> emailList = [];
  bool isLoggedIn = false;
  String userEmail = '';
  Uint8List? _userImageData;

  double _scrollOffset = 0.0;
//----------------------------

//override's------------------------------------------------
  @override
  void initState() {
    if (kDebugMode) print("initState del MyhomepageState");
    super.initState();
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
          "SharedPreferences: pref.getBool('isLoggin'): \n ${prefs.getBool('isLoggedIn') != null ? 'true' : 'false'}");
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

    if (loggedIn) {
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
  Future<String>? textBlurry() async {
    String? data = await MongoDataBase.blurry();
    if (kDebugMode) {
      print('data:  $data');
    }
    return data!;
  }
//-----------------------------------------------------

//TIEMPO DE OPACIDAD DEL BOTON DERECHO INFERIOR
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _opacity = 1.0;
    });
  }

  void _resetOpacity() {
    _timer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _opacity = 0.5;
      });
    });
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

//FUNCION PARA MOSTRAR UN 'BLURRY' (parte derecha superior de la pantalla)
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
                  height: MediaQuery.of(context).size.width * 0.6,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FutureBuilder<String>(
                        future: textBlurry(),
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else {
                            return Center(
                              child: Text(
                                snapshot.data!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'nuevo',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: AppColors.secondaryColor,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors
                              .secondaryColor, // Cambia este color al que prefieras
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            color: AppColors.onlyColor,
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

//FUNCION PARA AÑADIR UN 'BLURRY'
  void showAnimatedDialogAdd(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Hace que el fondo sea transparente
        barrierColor:
            const Color.fromARGB(115, 0, 0, 0), // Color del fondo negro
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          var buttonStyle = ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all<Color>(AppColors.secondaryColor),
          );
          const submitStyles = TextStyle(color: AppColors.primaryColor);
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .pop(); // Cierra el diálogo al tocar fuera
                },
                child: Container(
                  color: Colors
                      .transparent, // Fondo extra para detectar si se pickea fuera y salir del modal
                ),
              ),
              ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutBack,
                  ),
                ),
                child: Center(
                  child: Dialog(
                    insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Crea un Blurry',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'nuevo',
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: AppColors.onlyColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: formKey,
                            child: TextFormField(
                              controller: textController,
                              decoration: InputDecoration(
                                labelText: 'Ingrese algo',
                                labelStyle: const TextStyle(
                                  color: AppColors.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Radio de esquina para el borde
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(
                                        255, 242, 149, 10), // Color del borde
                                    width: 2.0, // Grosor del borde
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors
                                        .primaryColor, // Color del borde cuando el campo está enfocado
                                    width: 2.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors
                                        .primaryColor, // Color del borde cuando el campo está habilitado
                                    width: 2.0,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors
                                        .onlyColor, // Color del borde cuando hay un error
                                    width: 2.0,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors
                                        .onlyColor, // Color del borde cuando hay un error y el campo está enfocado
                                    width: 2.0,
                                  ),
                                ),
                                errorStyle: const TextStyle(
                                  color: AppColors.onlyColor,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese algún texto';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              ElevatedButton(
                                style: buttonStyle,
                                onPressed: () {
                                  textController.clear();
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Cancelar',
                                  style: submitStyles,
                                ),
                              ),
                              const Spacer(), // Añade un espacio flexible entre los botones
                              ElevatedButton(
                                style: buttonStyle,
                                onPressed: () {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    if (kDebugMode) {
                                      print(
                                          'el textController: ${textController.text}');
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor:
                                            AppColors.backgroundColor,
                                        content: Column(
                                          children: [
                                            Text(
                                              '¡¡BLURRY!!',
                                              style: TextStyle(
                                                  fontFamily: 'nuevo',
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Icon(
                                              Icons.bolt,
                                              color: AppColors.onlyColor,
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                    textController.clear();
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text(
                                  'Enviar',
                                  style: submitStyles,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        transitionsBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
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
  }
//-----------------------------------------------------

//Modal de los Emails para poder cambiar segun guardado en el SharePreferences
  void emailsModal(BuildContext context) {
    if (emailList.isEmpty) {
      if (kDebugMode) print("la lista está vacía");
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
                    child: Text('No hay cuentas guardadas'),
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
    );
  }
//-----------------------------------------------------

  Future<void> open() async {
    MongoDataBase.db!.isConnected
        ? print('${MongoDataBase.db} \n db open')
        : print('${MongoDataBase.db} \n db closed');
  }

//WIDGET PADRE------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    //Calculos para la animacion de ocultar el AppBar al scrollear
    double opacityButton = 1.0 - (_scrollOffset / 100);
    double appBarHeight = 200.0 - _scrollOffset;
    double titleFontSize = 30 + (_scrollOffset / 14);
    double titlePositionRight = 170 - (_scrollOffset * 1.4);
    double titlePositionTop = 100 - (_scrollOffset / 1.6);
    //Variables
    const labelStyleFloatingActionButton = TextStyle(
      fontFamily: 'nuevo',
      fontWeight: FontWeight.w700,
    );
    //Return...
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
                    'Blurry',
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
                          onTap: () => {emailsModal(context)},
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
                                const Color.fromARGB(255, 0, 0, 0)
                                    .withOpacity(0.2)),
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
                          onPressed: () {
                            Navigator.push(
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
                            ).then((_) {
                              print("Regresé a la pantalla anterior");
                              _checkLoginStatus();
                            });
                          },
                          child: const Text(
                            'I/R sesión',
                            style: TextStyle(color: AppColors.secondaryColor),
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
      body: Body(callFunction: _checkLoginStatus, onScroll: _handleScroll),
      floatingActionButton: GestureDetector(
        onTap: _resetOpacity,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 300),
          child: SpeedDial(
            icon: Icons.view_stream,
            activeIcon: Icons.close,
            overlayColor: Colors.black, // Color de la superposición
            overlayOpacity: 0.0, // Opacidad de la superposición
            backgroundColor: const Color.fromARGB(255, 222, 222, 222),
            foregroundColor: Colors.black,
            children: [
              //Boton Login
              SpeedDialChild(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 600),
                      pageBuilder: (_, __, ___) => const LoginPage(),
                      transitionsBuilder: (_, animation, __, child) {
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
                    ),
                  ).then((_) {
                    print("Regresé a Myhomepage.dart");
                    _checkLoginStatus();
                  });
                },
                child: const Icon(
                  Icons.login,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                label: 'Salir de la sesion',
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),
              //Boton de cambiar usuario
              SpeedDialChild(
                onTap: () {
                  emailsModal(context);
                },
                child: const Icon(
                  Icons.group_add,
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 30.0,
                ),
                label: 'Agregar Usuario',
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),
              //Boton de añadir publicacion
              SpeedDialChild(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 600),
                      pageBuilder: (_, __, ___) => const SecondScreen(),
                      transitionsBuilder: (_, animation, __, child) {
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
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      if (kDebugMode) {
                        print(
                            "Estoy en MyHomePage.dart, y el result de la seccond_screen devolvio true");
                      }
                      _checkLoginStatus();
                    });
                  }
                },
                child: const Icon(
                  Icons.add_card,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                label: 'Agregar BlurryPost',
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),
              //USER PROFILE BUTTON
              SpeedDialChild(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 600),
                      pageBuilder: (_, __, ___) => const UserProfile(),
                      transitionsBuilder: (_, animation, __, child) {
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
                    ),
                  );
                },
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 31.0,
                ),
                label: 'Cuenta',
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),
              //Boton para agregar un BLURRY
              SpeedDialChild(
                onTap: () => showAnimatedDialogAdd(context),
                child: const Icon(
                  Icons.add,
                  color: Color.fromARGB(255, 213, 161, 4),
                  size: 31.0,
                ),
                label: 'BLURRY',
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),
//BOTON DE CONTROL DE RIESGOS:
              SpeedDialChild(
                onTap: () => open(),
                child: const CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: 'BASE DE DATOS',
                labelStyle: labelStyleFloatingActionButton,
                shape: const CircleBorder(),
              ),
            ],
            onOpen: () => _startTimer(),
            onClose: () => _resetOpacity(),
          ),
        ),
      ),
    );
  }
}
