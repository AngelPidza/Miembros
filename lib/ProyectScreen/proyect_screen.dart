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
  late List<TextEditingController> _questionControllers;
  final _formKey = GlobalKey<FormState>();
  double _progress = 0.0;
  late Future<Map<String, dynamic>> _projectDataFuture;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _projectDataFuture = _loadProjectData();
    _questionControllers = [];
  }

  @override
  void dispose() {
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    _mounted = false;
    super.dispose();
  }

  // Método para calcular el progreso
  void _updateProgress() {
    setState(() {
      int filledFields = _questionControllers
          .where((controller) => controller.text.isNotEmpty)
          .length;
      _progress = filledFields / _questionControllers.length;
    });
  }

  // Método para enviar la información
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el email del usuario')),
        );
        return;
      }

      List<Map<String, dynamic>> respuestas = [];
      for (int i = 0; i < _questionControllers.length; i++) {
        respuestas.add({
          'preguntaId': i + 1,
          'respuesta': _questionControllers[i].text,
        });
      }

      bool success = await MongoDataBase.submitFormWithAnswers(
          email, widget.idProyect, respuestas);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respuestas enviadas correctamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar las respuestas')),
        );
      }
    }
  }

  // Método para cancelar la información
  void _cancelForm() {
    _formKey.currentState?.reset();
    _updateProgress();
  }

  // Método para borrar la información
  void _clearForm() {
    _updateProgress();
  }

  //variables de colores
  var colorTitleCard = AppColors.secondaryColor;
  var colorSubtitleCard = AppColors.cardColor;
  var colorBackgroundCard = AppColors.backgroundColor;
  var colorIconCard = AppColors.onlyColor;

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
          final preguntas = projectData['Preguntas'] as List<dynamic>;

          if (_questionControllers.isEmpty) {
            _questionControllers =
                List.generate(preguntas.length, (_) => TextEditingController());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                        'Título', projectData['Nombre'], Icons.title),
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
                    ...preguntas.asMap().entries.map((entry) {
                      int index = entry.key;
                      var pregunta = entry.value;
                      return _buildQuestionCard(
                        'Pregunta ${index + 1}',
                        pregunta['texto'],
                        Icons.question_answer,
                        _questionControllers[index],
                      );
                    }),
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

  Widget _buildQuestionCard(String title, String question, IconData icon,
      TextEditingController controller) {
    return Card(
      color: AppColors.backgroundColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.onlyColor),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'nuevo',
                    fontWeight: FontWeight.w700,
                    color: AppColors.onlyColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              question,
              style: TextStyle(
                fontFamily: 'nuevo',
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryColor,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'nuevo',
                color: AppColors.onlyColor,
              ),
              decoration: InputDecoration(
                hintText: 'Escribe tu respuesta aquí',
                hintStyle: TextStyle(color: AppColors.cardColor),
                filled: true,
                fillColor: AppColors.backgroundColor.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.onlyColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.onlyColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, responde esta pregunta';
                }
                return null;
              },
              onChanged: (value) {
                print('Texto cambiado: $value');
                _updateProgress();
              },
            )
          ],
        ),
      ),
    );
  }
}
