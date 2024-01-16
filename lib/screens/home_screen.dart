import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:productos_app/screens/clientes_screen.dart';
import 'package:productos_app/screens/dashboard_screen.dart';
import 'package:productos_app/screens/listar_pedidos.dart';
import 'package:productos_app/screens/profile_screen.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:productos_app/screens/sincronizar.dart';
import 'package:productos_app/screens/cartera.dart';
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
  int _selectedScreenIndex = 0;
  Timer? _timer;

  final List _screens = [
    {"screen": const DashboardPage(), "title": "Dashboard"},
    {"screen": const ClientesPage(), "title": "Clientes"},
    {"screen": SincronizarPage(), "title": "Sincronizar"},
    {"screen": ListarPedidosPage(), "title": "Pedidos"},
    {"screen": CarteraPage(), "title": "Cartera"},
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
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedScreenIndex,
          onTap: _selectScreen,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.data_saver_off_outlined), label: "Dash"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_pin_circle_rounded), label: 'Clientes'),
            BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'Sincro'),
            BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined), label: 'Pedidos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_box), label: 'Cartera'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil')
          ],
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
      title: Text("Atención"),
      content: Text("Está seguro que desea salir de la aplicación?"),
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

  Widget bottomNavigationBar(BuildContext context) {
    return Obx(() => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Container(
          height: 70,
          child: BottomNavigationBar(
            showUnselectedLabels: true,
            showSelectedLabels: true,
            onTap: (value) {
              // if (value == 0) Navigator.of(context).push(MaterialPageRoute(builder: (context) => DashboardPage()));
              // if (value == 1) Navigator.of(context).push(MaterialPageRoute(builder: (context) => ClientesPage()));
              // if (value == 2) mostrarMenu();
              // if (value == 3) Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfilePage()));
            },
            currentIndex: con.tabIndex.value,
            backgroundColor: Colors.blue,
            unselectedItemColor: Colors.white.withOpacity(0.5),
            selectedItemColor: Colors.white,
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(
                    Icons.dashboard,
                    size: 30,
                  ),
                  label: 'Dashboard',
                  backgroundColor: Colors.yellow),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person,
                    size: 30,
                  ),
                  label: 'Clientes',
                  backgroundColor: Colors.yellow),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.sync,
                    size: 30,
                  ),
                  label: 'Sincronizar',
                  backgroundColor: Colors.yellow),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.store_outlined,
                    size: 30,
                  ),
                  label: 'Pedidos',
                  backgroundColor: Colors.yellow),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.account_box,
                    size: 30,
                  ),
                  label: 'Cartera',
                  backgroundColor: Colors.yellow),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person_pin_rounded,
                    size: 30,
                  ),
                  label: 'Perfil',
                  backgroundColor: Colors.yellow)
            ],
          ),
        )));
  }
}
