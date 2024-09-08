import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/mongoDB/db.dart';
import 'package:miembros/ProyectScreen/proyect_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  final VoidCallback callFunction;
  final Function(double) onScroll;

  const Body({super.key, required this.callFunction, required this.onScroll});

  @override
  BodyState createState() => BodyState();

  void callFunctionFromBody() {
    callFunction();
    if (kDebugMode) {
      print('Function called from Body');
    }
  }
}

class BodyState extends State<Body> {
  final ScrollController _scrollController = ScrollController();
  late Future<Map<String, dynamic>> _futureData;
  String emailState = '';
  bool isAdmin = false;

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
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final admin = pref.getBool('isAdmin') ?? false;
      if (admin == true) {
        pref.setBool('isLoggedIn', true);
        setState(() {
          isAdmin = admin;
        });
      } else {
        setState(() {
          isAdmin = false;
        });
      }
      final login = pref.getBool('isLoggedIn') ?? false;
      print("Is admin: $isAdmin");
      print("Is logged in: $login");

      final projectsData = isAdmin
          ? await MongoDataBase.getAdminData()
          : await MongoDataBase.getData();
      print("Projects data length: ${projectsData.length}");

      final canSelectMore = await _userCanSelectProject();
      print("Can select more: $canSelectMore");

      return {
        'login': login,
        'projects': projectsData,
        'canSelectMore': canSelectMore,
      };
    } catch (e) {
      print("Error in _loadData: $e");
      return {
        'login': false,
        'projects': [],
        'canSelectMore': false,
      };
    }
  }

  Future<void> refreshData() async {
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
      onRefresh: refreshData,
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
          final login = snapshot.data!['login'] as bool;

          return ListView.separated(
            controller: _scrollController,
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppColors.cardColor,
              height: 0.5,
            ),
            itemBuilder: (context, index) {
              // Verificar si el usuario puede seleccionar el proyecto segun casos:
              // 0. Si inicio sesion puede elegir proyectos, sino no.
              final zeroCase = login;
              // 1. El campo 'Integrantes' (que es campo que contiene el numero
              // maximmo de integrantes que puede entrar al proyecto) tiene que
              // ser mayor que el campo 'Dipuestos:' (campo que dice cuantos
              // usuarios ya estan en el proyecto) pero si no existe, por defecto
              // sera 0;
              final firstCase =
                  data[index]['Integrantes'] > (data[index]['Dispuestos'] ?? 0);
              // 2. Verifica si el usuario puede añadir mas proyectos (max: 3);
              final secondCase = canSelectMore;
              // 3. Revisa si en el campo de 'Participantes:' del proyecto, esta
              // o no el usuario que intenta apuntarse al proyecto (es decir,
              // seleccionar dos veces el mismo proyecto, no esta permitido)
              final thirdCase =
                  !(data[index]['Participantes']?.contains(emailState) ??
                      false);
              // Aca se verifica los tres casos, si son verdaderos, significa que
              // todo esta correcto y se puede proceder a elegir los proyectos.
              final isAvailable =
                  zeroCase && firstCase && secondCase && thirdCase;
              int determinarCasoN(bool zeroCase, bool firstCase,
                  bool secondCase, bool thirdCase) {
                return !zeroCase
                    ? 0
                    : !firstCase
                        ? 1
                        : !secondCase
                            ? 2
                            : !thirdCase
                                ? 3
                                : -1;
              }

              // Uso de la función:
              final int n =
                  determinarCasoN(zeroCase, firstCase, secondCase, thirdCase);
              return Slidable(
                key: Key(data[index]['ID']
                    .toString()), // Cada elemento necesita una key única
                endActionPane: ActionPane(
                  extentRatio: 0.3,
                  motion: const ScrollMotion(),
                  children: [
                    if (isAdmin) ...[
                      SlidableAction(
                        onPressed: (context) {
                          // Acción para editar
                          // Implementar lógica aquí
                        },
                        backgroundColor: AppColors.onlyColor,
                        foregroundColor: AppColors.backgroundColor,
                        icon: Icons.edit,
                      ),
                      SlidableAction(
                        onPressed: (context) {
                          deleteProjectByBody(data[index]['ID']);
                        },
                        backgroundColor: AppColors.cardColor,
                        foregroundColor: AppColors.onlyColor,
                        icon: Icons.delete,
                      ),
                    ],
                  ],
                ),
                child: Opacity(
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data[index]['Descripción'] ?? 'No description',
                          style: const TextStyle(
                            fontFamily: 'nuevo',
                            color: AppColors.cardColor,
                          ),
                        ),
                        // Dentro del ListTile
                        if (isAdmin) ...[
                          const SizedBox(height: 8),
                          const Text('Participantes:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          if (data[index]['participantesInfo'] != null)
                            ...(data[index]['participantesInfo']
                                    as List<dynamic>)
                                .map<Widget>((participante) => Text(
                                    '${participante['name']} (${participante['username']}) - ${participante['phone']}'))
                                .toList(),
                          Text(
                              'Especialidades: ${data[index]['Especialidades Requeridas']}'),
                          Text('Estado: ${data[index]['Estado']}'),
                          Text(
                              'Tiempo de Desarrollo: ${data[index]['Tiempo de Desarrollo']}'),
                        ],
                      ],
                    ),
                    trailing: !isAdmin
                        ? Text(data[index]['Tipo de Aplicación'] ?? 'hola',
                            style: const TextStyle(
                              fontFamily: 'nuevo',
                              color: AppColors.onlyColor,
                              fontWeight: FontWeight.w700,
                            ))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data[index]['Tipo de Aplicación'] ?? 'hola',
                                style: const TextStyle(
                                  fontFamily: 'nuevo',
                                  color: AppColors.onlyColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.admin_panel_settings_outlined,
                                  color: AppColors.onlyColor),
                            ],
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
                            String getErrorMessage(int n) {
                              switch (n) {
                                case 0:
                                  return 'No iniciaste sesion.';
                                case 1:
                                  return 'Este proyecto ya está lleno.';
                                case 2:
                                  return 'Ya no puedes añadir más proyectos.';
                                case 3:
                                  return 'Ya seleccionaste este proyecto.';
                                default:
                                  return 'Algo anda mal';
                              }
                            }

                            //Mostrar un mensaje explicando por qué no se puede seleccionar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(getErrorMessage(n)),
                              ),
                            );
                          },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void deleteProjectByBody(data) async {
    if (kDebugMode) {
      print(data);
    }
    bool success = await MongoDataBase.deleteProyect(data);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyecto eliminado'),
        ),
      );
      refreshData();
    }
  }
}
