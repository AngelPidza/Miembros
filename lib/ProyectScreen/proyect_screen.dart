import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProyectScreen extends StatefulWidget {
  final int idProyect;

  const ProyectScreen({super.key, required this.idProyect});

  @override
  State<ProyectScreen> createState() => ProyectScreenState();
}

class ProyectScreenState extends State<ProyectScreen> {
  // Define los controladores para cada campo
  final TextEditingController _question1Controller = TextEditingController();
  final TextEditingController _question2Controller = TextEditingController();
  final TextEditingController _question3Controller = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  double _progress = 0.0;

  // Método para calcular el progreso
  void _updateProgress() {
    setState(() {
      int filledFields = 0;
      if (_question1Controller.text.isNotEmpty) filledFields++;
      if (_question2Controller.text.isNotEmpty) filledFields++;
      if (_question3Controller.text.isNotEmpty) filledFields++;

      _progress = filledFields / 3; // Progreso basado en 3 preguntas
    });
  }

  // Método para enviar la información
  void _submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isAdmin') ?? false == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No puedes enviar el formulario, eres administrador')),
      );
      Navigator.maybePop(context);
    } else if (_formKey.currentState!.validate()) {
      try {
        if (prefs.getBool('isLoggedIn') ?? false == true) {
          prefs.getString('email');
          if (kDebugMode) {
            print(
                "El getBool(isLoggedIn) es verdadero y el getStr(email) es: ${prefs.getString('email')}");
          }
          String email = prefs.getString('email')!;
          int id = widget.idProyect;
          bool success = await MongoDataBase.submitForm(email, id);
          if (success) {
            if (kDebugMode) {
              print('Formulario enviado correctamente');
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Formulario enviado correctamente')),
              );
              Navigator.pop(context);
            }
          } else {
            if (kDebugMode) {
              print('Error al enviar el formulario');
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al enviar el formulario')),
              );
            }
          }
        } else {
          if (kDebugMode) {
            print("El getBool(isLoggedIn) es falso");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No iniciaste sesion')),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error al enviar el formulario: $e');
        }
      }
    }
  }

  // Método para cancelar la información
  void _cancelForm() {
    _formKey.currentState?.reset();
    _question1Controller.clear();
    _question2Controller.clear();
    _question3Controller.clear();
    _updateProgress();
  }

  // Método para borrar la información
  void _clearForm() {
    _question1Controller.clear();
    _question2Controller.clear();
    _question3Controller.clear();
    _updateProgress();
  }

  //variables de colores
  var colorTitleCard = AppColors.secondaryColor;
  var colorSubtitleCard = AppColors.cardColor;
  var colorBackgroundCard = AppColors.backgroundColor;
  var colorIconCard = AppColors.onlyColor;

  late Future<Map<String, dynamic>> _projectDataFuture;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _projectDataFuture = _loadProjectData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadProjectData() async {
    try {
      final data =
          await MongoDataBase.collectionProyectInformation(widget.idProyect);
      if (_mounted) {
        return data;
      } else {
        throw Exception('Widget was disposed');
      }
    } catch (e) {
      if (_mounted) {
        throw e;
      } else {
        throw Exception('Widget was disposed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppColors.secondaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            Text(
              'Proyecto Nro ${widget.idProyect}',
              style: const TextStyle(
                  color: AppColors.secondaryColor, fontFamily: 'nuevo'),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _projectDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: AppColors.backgroundColor,
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No se encontraron datos del proyecto'));
          }

          final projectData = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard('Título', projectData['Nombre'], Icons.title),
                  _buildInfoCard('Área', projectData['Área'], Icons.category),
                  _buildInfoCard(
                      'Tipo de Aplicación',
                      projectData['Tipo de Aplicación'],
                      Icons.app_settings_alt),
                  _buildInfoCard(
                      'Estado', projectData['Estado'], Icons.info_outline),
                  _buildInfoCard('Tiempo de Desarrollo',
                      projectData['Tiempo de Desarrollo'], Icons.access_time),
                  _buildExpandableCard('Descripción',
                      projectData['Descripción'], Icons.description),
                  _buildExpandableCard(
                      'Objetivos', projectData['Objetivos'], Icons.flag),
                  _buildExpandableCard(
                      'Especialidades Requeridas',
                      projectData['Especialidades Requeridas'],
                      Icons.psychology),
                  const SizedBox(height: 120),
                  // Formulario de Ingreso de Proyectos
                  const Center(
                    child: Text(
                      'Formulario de Ingreso de Proyectos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundColor,
                        fontFamily: 'nuevo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.cardColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.onlyColor),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    onChanged: _updateProgress,
                    child: Column(
                      children: [
                        _buildQuestionCard(
                          'Pregunta 1',
                          '¿Cuál es el nombre del proyecto?',
                          Icons.question_answer,
                          _question1Controller,
                        ),
                        _buildQuestionCard(
                          'Pregunta 2',
                          '¿Cuál es el área principal del proyecto?',
                          Icons.question_answer,
                          _question2Controller,
                        ),
                        _buildQuestionCard(
                          'Pregunta 3',
                          '¿Cuánto tiempo tomará el desarrollo?',
                          Icons.question_answer,
                          _question3Controller,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _cancelForm,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColors.onlyColor,
                          backgroundColor: AppColors.backgroundColor,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _clearForm,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColors.onlyColor,
                          backgroundColor: AppColors.backgroundColor,
                        ),
                        child: const Text('Borrar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Seleccionar Proyecto'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.onlyColor,
                        backgroundColor: AppColors.backgroundColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        textStyle: const TextStyle(
                            fontFamily: 'nuevo', fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        _submitForm();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      color: colorBackgroundCard,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colorIconCard),
        title: Text(title,
            style: TextStyle(
                fontFamily: 'nuevo',
                fontWeight: FontWeight.w600,
                color: colorTitleCard)),
        subtitle: Text(
          content,
          style: TextStyle(
            fontFamily: 'nuevo',
            fontWeight: FontWeight.w400,
            color: colorSubtitleCard,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCard(String title, String content, IconData icon) {
    return Card(
      color: colorBackgroundCard,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: ExpansionTile(
        iconColor: colorBackgroundCard,
        collapsedIconColor: colorIconCard,
        leading: Icon(icon, color: colorIconCard),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'nuevo',
            fontWeight: FontWeight.w600,
            color: colorTitleCard,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                content,
                style: TextStyle(
                    fontFamily: 'nuevo',
                    fontWeight: FontWeight.w400,
                    color: colorSubtitleCard),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String title, String hint, IconData icon,
      TextEditingController controller) {
    return Card(
      color: colorBackgroundCard,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colorIconCard),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'nuevo',
            fontWeight: FontWeight.w700,
            color: colorTitleCard,
          ),
        ),
        subtitle: TextFormField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'nuevo',
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryColor,
          ),
          decoration: InputDecoration(
            errorStyle: const TextStyle(
              fontFamily: 'nuevo',
              color: AppColors.errorColor,
              fontWeight: FontWeight.w700,
            ),
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'nuevo',
              color: colorSubtitleCard,
            ),
            border: InputBorder.none,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, completa esta pregunta';
            }
            return null;
          },
          onChanged: (value) => _updateProgress(),
        ),
      ),
    );
  }
}
