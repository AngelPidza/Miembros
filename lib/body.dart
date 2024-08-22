import 'package:flutter/material.dart';
import 'package:miembros/assets/style/AppColors.dart';
import 'package:miembros/mongoDB/db.dart';

class Body extends StatefulWidget {
  final VoidCallback callFunction;
  final Function(double) onScroll;

  const Body({super.key, required this.callFunction, required this.onScroll});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final ScrollController _scrollController = ScrollController();
  late Future<List<Map<String, dynamic>>> _futureData;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _futureData = MongoDataBase.getData();
  }

  void _scrollListener() {
    widget.onScroll(_scrollController.offset);
  }

  Future<void> _refreshData() async {
    widget.callFunction();
    setState(() {
      _futureData = MongoDataBase.getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('!snapshot.hasData'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('snapshot.data!.isEmpty'));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              controller: _scrollController,
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data[index]['imageBytes'] != null
                        ? MemoryImage(data[index]['imageBytes'])
                        : null,
                    child: data[index]['imageBytes'] == null
                        ? Text(
                            data[index]['userName'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    data[index]['email'] ?? 'No name',
                    style: const TextStyle(
                      fontFamily: 'nuevo',
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    data[index]['userName'] ?? 'No description',
                    style: const TextStyle(
                      fontFamily: 'nuevo',
                      color: AppColors.cardColor,
                    ),
                  ),
                  trailing: Text(
                    data[index]['password'] ?? 'hola',
                    style: const TextStyle(
                      fontFamily: 'nuevo',
                      color: AppColors.onlyColor,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
