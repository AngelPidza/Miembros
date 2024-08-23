import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:miembros/ProyectScreen/proyect_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  final VoidCallback callFunction;
  final Function(double) onScroll;

  const Body({super.key, required this.callFunction, required this.onScroll});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final ScrollController _scrollController = ScrollController();
  late Future<Map<String, dynamic>> _futureData;
  String emailState = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _futureData = _loadData();
  }

  void _scrollListener() {
    widget.onScroll(_scrollController.offset);
  }

  Future<Map<String, dynamic>> _loadData() async {
    final projectsData = await MongoDataBase.getData();
    final canSelectMore = await _userCanSelectProject();
    return {
      'projects': projectsData,
      'canSelectMore': canSelectMore,
    };
  }

  Future<void> _refreshData() async {
    widget.callFunction();
    setState(() {
      _futureData = _loadData();
    });
  }

  Future<bool> _userCanSelectProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) return false;
      setState(() {
        emailState = email;
      });
      final proyectList = await MongoDataBase.getProyectList(email);
      print(
          "Enviando el proyecto: $proyectList y tiene el tamaño de proyectos: ${proyectList.length} de $email al servidor");
      return proyectList.length < 3;
    } catch (e) {
      print('Error al verificar los proyectos del usuario: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: AppColors.backgroundColor,
      color: AppColors.onlyColor,
      onRefresh: _refreshData,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: AppColors.backgroundColor,
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['projects'].isEmpty) {
            return const Center(child: Text('No hay datos disponibles'));
          }
          final data = snapshot.data!['projects'] as List<Map<String, dynamic>>;
          final canSelectMore = snapshot.data!['canSelectMore'] as bool;

          return ListView.separated(
            controller: _scrollController,
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppColors.cardColor,
              height: 0.5,
            ),
            itemBuilder: (context, index) {
              final isAvailable = data[index]['Integrantes'] >
                      (data[index]['Dispuestos'] ?? 0) &&
                  canSelectMore &&
                  !(data[index]['Participantes']?.contains(emailState) ??
                      false);
              return Opacity(
                opacity: isAvailable ? 1.0 : 0.5,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.backgroundColor,
                    child: Text(
                      data[index]['ID'].toString(),
                      style: const TextStyle(
                        fontFamily: 'nuevo',
                        color: AppColors.onlyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    data[index]['Nombre'] ?? 'No name',
                    style: const TextStyle(
                        fontFamily: 'nuevo',
                        color: AppColors.backgroundColor,
                        fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    data[index]['Descripción'] ?? 'No description',
                    style: const TextStyle(
                      fontFamily: 'nuevo',
                      color: AppColors.cardColor,
                    ),
                  ),
                  trailing: Text(
                    data[index]['Tipo de Aplicación'] ?? 'hola',
                    style: const TextStyle(
                      fontFamily: 'nuevo',
                      color: AppColors.onlyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 600),
                              pageBuilder: (_, __, ___) =>
                                  ProyectScreen(idProyect: data[index]['ID']),
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
                          if (kDebugMode) print(data[index]['ID'].toString());
                        }
                      : () {
                          // Opcional: Mostrar un mensaje explicando por qué no se puede seleccionar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(canSelectMore
                                  ? 'Este proyecto ya está lleno.'
                                  : 'Ya has seleccionado el máximo de proyectos permitidos.'),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
