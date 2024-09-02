import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/login/UserData.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Text(
                'Inicio de Sesión',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontFamily: 'nuevo',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
              if (kDebugMode) print("Volviendo a Myhomepage.dart");
              Navigator.pop(context, false);
            },
          ),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  bool isValidSharedPreferences = true;
//----------------------------------------------------------
//Backend
//----------------------------------------------------------
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    validatorSharedPreferences().then((value) {
      setState(() {
        isValidSharedPreferences = value;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm(bool a) async {
    if (_formKey.currentState!.validate()) {
      try {
        SharedPreferences pref = await SharedPreferences.getInstance();
        if (kDebugMode) {
          print("El email: ${_emailController.text}");
          print("El password: ${_passwordController.text}");
          print("El email del pref: ${pref.getString('email')}");
        }
        final emailList = pref.getStringList('EmailList') ?? [];
        //CASO EN EL QUE EL USUARIO ESTE ENTRANDO CON SU MISMA CUENTA
        if (_emailController.text == pref.getString('email')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ya estas iniciado sesion con esta cuenta')),
          );
          Navigator.maybePop(context, false);
        } else if (_emailController.text == 'admin@admin.admin' &&
            _passwordController.text == 'admin') {
          pref.setString('email', _emailController.text);
          pref.setBool('isLoggedIn', true);
          pref.setBool('isAdmin', true);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bienvenido Administrador')),
          );
          Navigator.maybePop(context, true);
        } else if (emailList.isNotEmpty &&
            emailList.contains(_emailController.text)) {
          if (kDebugMode) {
            print(
                'La lista de usuarios no es nula ${pref.getStringList('EmailList')}');
          }
          //SI LA LISTA DE USUARIOS NO ES NULA
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya tenias esta cuenta en tu lista')),
          );
          Navigator.maybePop(context, false);
        }
        //SI NO ES EL CASO, PROSEGUIR
        else {
          Map<String, dynamic> data = {
            "email": _emailController.text,
            "password": _passwordController.text
          };
          if (kDebugMode) {
            print(
                "email: ${_emailController.text} \n password: ${_passwordController.text}");
          }

          bool success;

          //REGISTRANDOSE
          if (a) {
            if (kDebugMode) {
              print("Registrando");
            }
            success = await MongoDataBase.sesion(data, a);

            if (success) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Paso 1/2 completado para registrarse')),
              );
              pref.setString('email', _emailController.text);
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 600),
                  pageBuilder: (_, __, ___) => Userdata(),
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
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Correo ya registrado con otro usuario')),
              );
            }
          }
          //INICIANDO SESION
          else if (a == false) {
            success = await MongoDataBase.sesion(data, a);
            if (success) {
              MongoDataBase.email_ = _emailController.text;
              //SHARED PREFERENCES
              await pref.setBool('isLoggedIn', true);
              await pref.setString('email', _emailController.text);
              List<String> emailList = pref.getStringList('EmailList') ?? [];
              emailList.add(_emailController.text);
              await pref.setStringList('EmailList', emailList);
              if (kDebugMode) {
                print('La lista (EmailList) de correos es: $emailList');
              }
              //------------------------------------------------------------
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciaste sesion')),
              );
              if (kDebugMode) print("Volviendo a Myhomepage.dart");
              Navigator.maybePop(context, true);
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraseña o correo invalido')),
              );
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      if (kDebugMode) {
        print('Algo esta mal');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Algo esta fallando')),
      );
    }
  }

  Future<bool> validatorSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? emailList = prefs.getStringList('EmailList');

    return emailList == null || emailList.length <= 4;
  }

//----------------------------------------------------------
//Frontend
//----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const errorColor = AppColors.cardColor;
    return Scaffold(
      appBar: null,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Form(
                key: _formKey,
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Esta línea es nueva
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 200, // Ajusta el ancho del contenedor
                        height: 200, // Ajusta la altura del contenedor
                        child: Image.asset(
                          'lib/assets/images/image_foot_cheetah.webp',
                          fit: BoxFit
                              .contain, // Ajusta cómo se debe ajustar la imagen dentro de su contenedor
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ), // Espacio entre la imagen y el siguiente elemento
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(
                          fontFamily: 'nuevo',
                          color: AppColors.backgroundColor,
                        ),
                        decoration: const InputDecoration(
                          //---------------------------------------------------------------
                          //Estilo de lo errores:
                          errorStyle: TextStyle(
                            color: errorColor, // Color del texto de error
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  errorColor, // Color de la línea de error cuando no está enfocado
                            ),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  errorColor, // Color de la línea de error cuando está enfocado
                            ),
                          ),
                          //---------------------------------------------------------------
                          labelText: 'Correo electrónico',
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(
                            fontFamily: 'nuevo',
                            color: AppColors.backgroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        validator: (value) {
                          if (!isValidSharedPreferences) {
                            return "Limite de cuentas";
                          }
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          // Validación de que contiene un '@' y termina en '.com'
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]{2,6}$')
                              .hasMatch(value)) {
                            return 'Por favor ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(
                          fontFamily: 'nuevo',
                          color: AppColors.backgroundColor,
                        ),
                        decoration: const InputDecoration(
                          //---------------------------------------------------------------
                          //Estilo de lo errores:
                          errorStyle: TextStyle(
                            color: errorColor, // Color del texto de error
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  errorColor, // Color de la línea de error cuando no está enfocado
                            ),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  errorColor, // Color de la línea de error cuando está enfocado
                            ),
                          ),
                          //---------------------------------------------------------------
                          labelText: 'Contraseña',
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(
                            fontFamily: 'nuevo',
                            color: AppColors.backgroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (!isValidSharedPreferences) {
                            return "Limite de cuentas";
                          }
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32.0),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 43, 43, 43)),
                            ),
                            onPressed: () {
                              _submitForm(false);
                              if (kDebugMode) {
                                print('Login button pressed');
                              }
                            },
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: AppColors.onlyColor,
                                fontFamily: 'nuevo',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 43, 43, 43)),
                            ),
                            onPressed: () {
                              _submitForm(true);
                              if (kDebugMode) {
                                print('Registred button pressed');
                              }
                            },
                            child: const Text(
                              'Registrarse',
                              style: TextStyle(
                                color: AppColors.onlyColor,
                                fontFamily: 'nuevo',
                                fontWeight: FontWeight.w500,
                              ),
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
      ),
    );
  }
}
