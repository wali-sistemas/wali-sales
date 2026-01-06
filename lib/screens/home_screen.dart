import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:productos_app/controllers/home_controller.dart';
import 'package:productos_app/icomoon.dart';
import 'package:productos_app/screens/ai_chat_screen.dart';
import 'package:productos_app/screens/clientes_screen.dart';
import 'package:productos_app/screens/dashboard_screen.dart';
import 'package:productos_app/screens/employee.dart';
import 'package:productos_app/screens/listar_pedidos.dart';
import 'package:productos_app/screens/profile_screen.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:productos_app/screens/sincronizar.dart';
import 'package:productos_app/screens/cartera.dart';
import 'package:productos_app/screens/productos_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController con = Get.put(HomeController());
  final GetStorage storage = GetStorage();
  final String? usuario = GetStorage().read('usuario');
  final String empresa = GetStorage().read('empresa');

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  void _startTimer() {
    const duration = Duration(hours: 24);
    _timer = Timer(duration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  Future mostrarMenu() {
    return showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000.0, 1000.0, 0.0, 0.0),
      items: const <PopupMenuItem<String>>[
        PopupMenuItem<String>(child: Text('test1'), value: 'test1'),
        PopupMenuItem<String>(child: Text('test2'), value: 'test2'),
      ],
      elevation: 8.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showAlertDialog(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      const Positioned(
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
                            _itemBottomSheet(
                              context,
                              icon: Icons.wallet_outlined,
                              text: 'Cartera de clientes',
                              page: const CarteraPage(),
                            ),
                            _itemBottomSheet(
                              context,
                              icon: Icons.image_search_rounded,
                              text: 'Catálogo de productos',
                              page: ProductosPage(),
                            ),
                            _itemBottomSheet(
                              context,
                              icon: Icons.store_outlined,
                              text: 'Pedidos enviados y guardados',
                              page: ListarPedidosPage(),
                            ),
                            _itemBottomSheet(
                              context,
                              icon: null,
                              customIcon: const Icon(Icomoon.microchipAI),
                              text: 'Chatbot',
                              page: AIChatScreen(),
                            ),
                            _itemBottomSheet(
                              context,
                              icon: null,
                              customIcon: const Icon(Icomoon.groups),
                              text: 'Empleado',
                              page: const EmployeePage(),
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
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: const Color.fromRGBO(0, 55, 114, 1),
          shape: const CircleBorder(),
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color.fromRGBO(30, 129, 235, 1),
          height: 67,
          shape: const CircularNotchedRectangle(),
          notchMargin: 4.0,
          clipBehavior: Clip.antiAlias,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedScreenIndex,
            onTap: _selectScreen,
            selectedItemColor: Colors.white,
            unselectedItemColor: const Color.fromRGBO(1, 39, 80, 1),
            selectedFontSize: 8,
            unselectedFontSize: 12.5,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.data_saver_off_outlined),
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
        body: _screens[_selectedScreenIndex]["screen"],
      ),
    );
  }

  Widget _itemBottomSheet(
    BuildContext context, {
    IconData? icon,
    Icon? customIcon,
    required String text,
    required Widget page,
  }) {
    return Row(
      children: [
        const SizedBox(width: 10),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          icon: customIcon ?? Icon(icon),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: const Text(
            '',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  void showAlertDialog(BuildContext context) {
    final Widget cancelButton = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text("NO"),
    );

    final Widget continueButton = ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      },
      child: const Text("SI"),
    );

    final AlertDialog alert = AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.error, color: Colors.orange),
          SizedBox(width: 8),
          Text("Atención!"),
        ],
      ),
      content: const Text("¿Está seguro que desea salir de la aplicación?"),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
    );
  }
}
