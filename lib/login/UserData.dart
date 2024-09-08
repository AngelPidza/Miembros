import 'dart:io';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:bottom_picker/resources/arrays.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Asegúrate de agregar intl en tu pubspec.yaml

class Userdata extends StatelessWidget {
  const Userdata({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Spacer(),
            Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Text(
                'Datos del Usuario',
                style: TextStyle(
                  color: Colors.white,
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
              Navigator.of(context).pop(false);
            },
          ),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: UserDataBody(),
      ),
    );
  }
}

class UserDataBody extends StatefulWidget {
  const UserDataBody({super.key});

  @override
  UserDataBodyState createState() => UserDataBodyState();
}

class UserDataBodyState extends State<UserDataBody> {
//----------------------------------------------------------
//Backend
//----------------------------------------------------------
  late String userEmail;

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  String? _selectedGender;
  String _name = '';

  //Esto inicia el UserDataBodyState con el email enviado
  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      userEmail = pref.getString('email') ?? '';
    });
  }

  void _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = XFile(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _name = ''; // Opcional: Limpia el nombre si es necesario
    });
  }

  void submitUseData() async {
    if (_formKey.currentState!.validate()) {
      DateTime fechaNacimiento =
          DateFormat('dd/MM/yyyy').parse(_dateController.text);
      DateTime fechaCreacion = DateTime.now();

      Map<String, dynamic> data = {
        'name': _nameController.text,
        'userName': _userNameController.text,
        'phone': _phoneController.text,
        'birthdate': fechaNacimiento.toIso8601String(),
        'now': fechaCreacion.toIso8601String(),
        'gender': _selectedGender,
      };
      if (kDebugMode) {
        print("user_name: ${_userNameController.text} \n"
            "name: ${_nameController.text} \n"
            "phone: ${_phoneController.text} \n"
            "fecha de nacimiento: ${fechaNacimiento.toIso8601String()} \n"
            "fecha de creación: ${fechaCreacion.toIso8601String()} \n"
            "genero: $_selectedGender \n");
      }
      bool success;
      success = await MongoDataBase.insertDataRegister(_image, data);
      if (success) {
        if (!mounted) return; // Verificación de mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenido a Prorandom =D')),
        );
        MongoDataBase.email_ = userEmail;
        //SHARED PREFERENCES
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString('email', userEmail);
        await pref.setBool('isLoggedIn', true);
        List<String> emailList = pref.getStringList('EmailList') ?? [];
        emailList.add(userEmail);
        var hola = emailList.toList();
        if (kDebugMode) print("Se añadio el email a la lista: $hola");
        await pref.setStringList('EmailList', emailList);
        if (!mounted) return; // Verificación de mounted
        Navigator.of(context).pop(true);
        // Agregar un pequeño retraso antes de navegar de vuelta a MyHomePage
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      } else {
        if (!mounted) return; // Verificación de mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error')),
        );
      }
    }
  }

//----------------------------------------------------------
//Frontend
//----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      //Fondo del CircleAvatar
                      backgroundColor: AppColors.backgroundColor,
                      radius: 50,
                      backgroundImage:
                          _image != null ? FileImage(File(_image!.path)) : null,
                      child: _image == null
                          ? Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : '',
                              style: const TextStyle(
                                  fontSize: 40,
                                  color: AppColors.secondaryColor),
                            )
                          : null,
                    ),
                  ),
                  if (_image != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SizedBox(
                        width: 27, // Tamaño del botón
                        height: 27,
                        child: ClipOval(
                          child: Container(
                            color: AppColors.backgroundColor, // Fondo blanco
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 18, // Tamaño del icono dentro del botón
                              ),
                              onPressed: _removeImage, // Acción del botón
                              padding: EdgeInsets
                                  .zero, // Elimina el padding predeterminado
                              iconSize: 24, // Tamaño del icono dentro del botón
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 30,
              ), // Espacio entre la imagen y el siguiente elemento
              TextFormField(
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                controller: _userNameController,
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
                style: const TextStyle(
                  color: AppColors.backgroundColor,
                  fontFamily: 'nuevo',
                  fontWeight: FontWeight.w300,
                ),
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    fontFamily: 'nuevo',
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (value.contains(' ')) {
                    return 'El nombre no debe tener espacios';
                  }
                  // Verifica que el valor comience con una letra
                  if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
                    return 'El nombre de usuario debe comenzar con una letra';
                  }
                  return null;
                },
              ),
              const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Lim. de caracteres: 10',
                      style: TextStyle(
                          color: Color.fromARGB(65, 245, 245, 245),
                          fontSize: 12),
                    ),
                  )
                ],
              ), // Espacio entre la imagen y el siguiente elemento
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.backgroundColor,
                  fontFamily: 'nuevo',
                  fontWeight: FontWeight.w300,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    fontFamily: 'nuevo',
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    fontFamily: 'nuevo',
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.backgroundColor,
                  fontFamily: 'nuevo',
                  fontWeight: FontWeight.w300,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa su número';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Solo se permiten números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              GenderSelectionField(
                initialValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    fontFamily: 'nuevo',
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(
                        top: 15.0), // Ajusta el valor según sea necesario
                    child: Icon(
                      Icons.calendar_today,
                      size: 24, // Tamaño del icono
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.backgroundColor,
                  fontFamily: 'nuevo',
                  fontWeight: FontWeight.w300,
                ),
                readOnly: true,
                onTap: () {
                  BottomPicker.date(
                    buttonContent: const Center(
                      child: Text(
                        'Aceptar',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'nuevo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    pickerTitle: const Text(
                      'Fecha de nacimiento',
                      style: TextStyle(
                        fontFamily: 'nuevo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    dateOrder: DatePickerDateOrder.dmy,
                    initialDateTime: DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                    maxDateTime: DateTime(2030),
                    minDateTime: DateTime(1980),
                    pickerTextStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onChange: (dateTime) {
                      // Esta función se llama cuando cambia el valor en el picker
                      if (kDebugMode) {
                        print(dateTime);
                      } // Solo para debug
                    },
                    onSubmit: (dateTime) {
                      // Esta función se llama cuando se confirma la selección
                      if (kDebugMode) {
                        print(dateTime);
                      } // Solo para debug
                      // Formatea la fecha y actualiza el controlador
                      _dateController.text =
                          '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                    },
                    bottomPickerTheme: BottomPickerTheme.blue,
                    buttonSingleColor: const Color.fromARGB(255, 0, 0, 0),
                    backgroundColor: AppColors.backgroundColor,
                  ).show(context);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa su fecha de nacimiento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              Row(
                children: [
                  //Este es el boton de "Atras"
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          AppColors.backgroundColor),
                    ),
                    onPressed: () {
                      // Cerrar la pantalla
                      if (kDebugMode) {
                        print(
                            'Se esta cerrando el formulario para crear un nuevo usuario');
                      }
                      cancelRegister();
                    },
                    child: const Text(
                      'Atras',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontFamily: 'nuevo',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  //Este es el boton de "Continuar"
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          AppColors.backgroundColor),
                    ),
                    onPressed: () => submitUseData(),
                    child: const Text(
                      'Continuar',
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
      ),
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _nameController.dispose();
    //_nameController.dispose();
    super.dispose();
  }

  void cancelRegister() {
    // Cerrar la pantalla
    MongoDataBase.email_ = '';
    MongoDataBase.password_ = '';
    Navigator.pop(context);
  }
}

//Clase para el seleccion del genero
class GenderSelectionField extends StatefulWidget {
  final Function(String?) onChanged;
  final String? initialValue;

  const GenderSelectionField({
    Key? key,
    required this.onChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  _GenderSelectionFieldState createState() => _GenderSelectionFieldState();
}

class _GenderSelectionFieldState extends State<GenderSelectionField> {
  String? _selectedGender;
  final TextEditingController _otherGenderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Género',
          style: TextStyle(
            fontFamily: 'nuevo',
            color: AppColors.backgroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          items: [
            'Masculino',
            'Femenino',
            'No binario',
            'Prefiero no decirlo',
            'Otro'
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
              if (newValue != 'Otro') {
                widget.onChanged(newValue);
              } else {
                widget.onChanged(_otherGenderController.text);
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona una opción';
            }
            return null;
          },
          style: const TextStyle(
            color: AppColors.backgroundColor,
            fontFamily: 'nuevo',
            fontWeight: FontWeight.w300,
          ),
        ),
        if (_selectedGender == 'Otro')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextFormField(
              controller: _otherGenderController,
              decoration: const InputDecoration(
                labelText: 'Especifica tu género',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.onChanged(value);
              },
              validator: (value) {
                if (_selectedGender == 'Otro' &&
                    (value == null || value.isEmpty)) {
                  return 'Por favor especifica tu género';
                }
                return null;
              },
              style: const TextStyle(
                color: AppColors.backgroundColor,
                fontFamily: 'nuevo',
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _otherGenderController.dispose();
    super.dispose();
  }
}
