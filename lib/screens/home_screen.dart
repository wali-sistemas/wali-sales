// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:productos_app/screens/ai_chat_screen.dart';
import 'package:productos_app/screens/clientes_screen.dart';
import 'package:productos_app/screens/dashboard_screen.dart';
import 'package:productos_app/screens/listar_pedidos.dart';
import 'package:productos_app/screens/profile_screen.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:productos_app/screens/sincronizar.dart';
import 'package:productos_app/screens/cartera.dart';
import 'package:productos_app/screens/productos_screen.dart';
import '../controllers/home_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeController con = Get.put(HomeController());
  GetStorage storage = GetStorage();
  String? usuario = GetStorage().read('usuario');
  String empresa = GetStorage().read('empresa');
  int _selectedScreenIndex = 0;
  Timer? _timer;

  final List _screens = [
    {"screen": DashboardPage(), "title": "Dashboard"},
    {"screen": ClientesPage(), "title": "Clientes"},
    {"screen": SincronizarPage(), "title": "Sincronizar"},
    {"screen": ProfilePage(), "title": "Perfil"},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _selectScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  void _startTimer() {
    const duration = Duration(hours: 24);
    _timer = Timer(duration, () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    });
  }

  Future mostrarMenu() {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 1000.0, 0.0, 0.0),
      items: <PopupMenuItem<String>>[
        new PopupMenuItem<String>(child: const Text('test1'), value: 'test1'),
        new PopupMenuItem<String>(child: const Text('test2'), value: 'test2'),
      ],
      elevation: 8.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 300,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Icon(Icons.horizontal_rule_rounded, size: 50),
                      ),
                      Positioned(
                        top: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CarteraPage(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.wallet_outlined),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CarteraPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Cartera de clientes',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductosPage(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.image_search_rounded),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductosPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Catálogo de productos',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ListarPedidosPage(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.store_outlined),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ListarPedidosPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Pedidos enviados y guardados',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ListarPedidosPage(),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.mark_unread_chat_alt_rounded,
                                  ),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AIChatScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Chatbot AI',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Color.fromRGBO(0, 55, 114, 1),
          shape: CircleBorder(),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Color.fromRGBO(30, 129, 235, 1),
          height: 67,
          shape: CircularNotchedRectangle(),
          notchMargin: 4.0,
          clipBehavior: Clip.antiAlias,
          child: Container(
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedScreenIndex,
              onTap: _selectScreen,
              selectedItemColor: Colors.white,
              unselectedItemColor: Color.fromRGBO(1, 39, 80, 1),
              selectedFontSize: 8,
              unselectedFontSize: 12.5,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.data_saver_off_outlined,
                  ),
                  label: 'Dash',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_pin_circle_rounded),
                  label: 'Clientes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sync),
                  label: 'Sincronizar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
        body: _screens[_selectedScreenIndex]["screen"],
      ),
      onWillPop: () async {
        showAlertDialog(context);
        return false;
      },
    );
  }

  showAlertDialog(BuildContext context) {
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      },
    );
    AlertDialog alert = AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error,
            color: Colors.orange,
          ),
          SizedBox(width: 8),
          Text("Atención!"),
        ],
      ),
      content: Text("¿Está seguro que desea salir de la aplicación?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
