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
                  color: AppColors.textSecondary,
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
              Navigator.maybePop(context);
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
      SharedPreferences pref = await SharedPreferences.getInstance();
      //VERIFICANDO QUE NO SE HAYA INICIADO SESION CON ESTA CUENTA
      if (_emailController.text == pref.getString('email')) {
        if (pref.getStringList('EmailList') != null) {
          if (kDebugMode) {
            print("Entrando al if(pref.getStringList('EmailList') != null)");
          }
          if (kDebugMode) {
            print(
                "${!pref.getStringList('EmailList')!.contains(_emailController.text)}");
          }
          if (kDebugMode) {
            print("${pref.getStringList('EmailList')}");
          }
          if (kDebugMode) {
            print(_emailController.text);
          }
          if (!pref
              .getStringList('EmailList')!
              .contains(_emailController.text)) {
            List<String>? data = pref.getStringList('EmailList');
            data!.add(_emailController.text);
            pref.setStringList('EmailList', data);
          }
        } else {
          if (kDebugMode) {
            print("Entrando al if(pref.getStringList('EmailList') != null)");
          }
          List<String>? data = [];
          data.add(_emailController.text);
          pref.setStringList('EmailList', data);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ya estas iniciado sesion con esta cuenta')),
        );
        Navigator.maybePop(context);
      } else if (pref
              .getStringList('EmailList')!
              .contains(_emailController.text) &&
          pref.getString('email') != _emailController.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya tenias esta cuenta en tu lista')),
        );
        Navigator.maybePop(context);
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
          success = await MongoDataBase.sesion(data, a);

          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario registrado exitosamente')),
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
            List<String>? emailList = pref.getStringList('EmailList');
            emailList?.add(_emailController.text);
            await pref.setStringList('EmailList', emailList!);
            //------------------------------------------------------------
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Iniciaste sesion')),
            );
            if (kDebugMode) print("Volviendo a Myhomepage.dart");
            Navigator.maybePop(context);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña o correo invalido')),
            );
          }
        }
      }
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
    return Form(
      key: _formKey,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Esta línea es nueva
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
                color: Colors.white,
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
                  color: Colors.white,
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
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]{2,6}$').hasMatch(value)) {
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
                color: Colors.white,
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
                  color: Colors.white,
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
                  onPressed: () => _submitForm(false),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
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
                  onPressed: () => _submitForm(true),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
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
    );
  }
}
