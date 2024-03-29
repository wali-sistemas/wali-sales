import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:productos_app/screens/pedidosGuardados.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/screens/buscador_pedidos.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity/connectivity.dart';
import 'package:productos_app/models/DatabaseHelper.dart';

class ListarPedidosPage extends StatefulWidget {
  const ListarPedidosPage({Key? key}) : super(key: key);

  @override
  State<ListarPedidosPage> createState() => _ListarPedidosPageState();
}

class _ListarPedidosPageState extends State<ListarPedidosPage> {
  List _ventas = [];
  List<Pedido> pedidosG = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String usuario = GetStorage().read('usuario');
  String empresa = GetStorage().read('empresa');
  DateTime now = new DateTime.now();
  final numberFormat = new NumberFormat.simpleCurrency();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;
  bool _showPedidos = false;
  String year = "";
  String mes = "";
  String dia = "";
  Connectivity _connectivity = Connectivity();

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  void initState() {
    year = now.year.toString();
    mes = now.month.toString();
    dia = now.day.toString();
  }

  void _onDaySelected(DateTime selectedDay, DateTime selectedMes) {
    String diaSel = "";
    String mesSel = "";
    String yearSel = "";
    setState(() {
      _selectedDay = selectedDay;
      dia = selectedDay.day.toString();
      mes = selectedDay.month.toString();
      year = selectedDay.year.toString();
      //print("Dia seleccionado: $diaSel");
      _showCalendar =
          false; // Oculta el calendario después de seleccionar un día
      if (GetStorage().read('ventas') != null) {
        //print(GetStorage().read('ventas'));
        //storage.remove("ventas");
      }
    });
    //_fetchData("2023", mesSel, diaSel);
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> listarPedidosGuardados() async {
    List<Pedido> pedidos = [];
    DatabaseHelper dbHelper = DatabaseHelper();
    pedidos = await dbHelper.getPedidos();
    pedidosG = pedidos;
  }

  void _mostrarPedidos() {
    setState(() {
      _showPedidos = !_showPedidos;
    });
  }

  Future<void> _fetchData(String year, String mes, String dia) async {
    bool isConnected = await checkConnectivity();
    if (isConnected == true) {
      //if (GetStorage().read('ventas') == null) {
      final String apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/list-order/' +
              empresa! +
              '?slpcode=' +
              usuario! +
              '&year=' +
              year +
              '&month=' +
              mes +
              '&day=' +
              dia;
      //print(apiUrl);
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        //print("codigoError: $codigoError");
        _ventas = [];
      } else {
        final data = resp["content"];
        //print(data.toString());
        if (!mounted) return;
        setState(
          () {
            _ventas = data;

            /// GUARDAR
            storage.write('ventas', _ventas);
          },
        );
      }
    } else {
      _ventas = GetStorage().read('ventas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          CarritoPedido(),
        ],
        title: ListTile(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegatePedidos(),
            );
          },
          title: Text(
            'Buscar pedido',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PedidosGuardadosPage(),
                  ),
                );
              },
            ),
            if (_showPedidos)
              Expanded(
                child: ListView.builder(
                  itemCount: pedidosG.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            'Fecha: ' +
                                pedidosG[index].id.toString() +
                                ' - Nit: ' +
                                pedidosG[index].cardCode.toString() +
                                '\n' +
                                pedidosG[index].cardName.toString() +
                                '\n' +
                                'Orden: ' +
                                pedidosG[index].id.toString(),
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Total: " + pedidosG[index].docTotal.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: TextButton.icon(
                            onPressed: () {},
                            label: const Text(
                              '',
                            ),
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: _toggleCalendar,
            ),
            if (_showCalendar)
              Container(
                child: TableCalendar(
                  calendarFormat: _calendarFormat,
                  focusedDay: _focusedDay,
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2050),
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: _onDaySelected,
                ),
              ),
            pedidos(context),
          ],
        ),
      ),
    );
  }

  Widget pedidos(BuildContext context) {
    // if (_ventas.isNotEmpty)
    _fetchData(year, mes, dia);
    return Expanded(
      child: ListView.builder(
        itemCount: _ventas.length,
        itemBuilder: (context, index) {
          String total = numberFormat.format(_ventas[index]['docTotal']);
          if (total.contains('.')) {
            int decimalIndex = total.indexOf('.');
            total = total.substring(0, decimalIndex);
          }
          return Card(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    'Fecha: ' +
                        _ventas[index]["docDate"].toString() +
                        ' - Nit: ' +
                        _ventas[index]["cardCode"].toString() +
                        '\n' +
                        _ventas[index]["cardName"].toString() +
                        '\n' +
                        'Orden: ' +
                        _ventas[index]["docNum"].toString(),
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    "Total: " + total,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget pedidosGuardados(BuildContext context) {
    listarPedidosGuardados();
    return Expanded(
      child: ListView.builder(
        itemCount: pedidosG.length,
        itemBuilder: (context, index) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  pedidosG[index].toString(),
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
