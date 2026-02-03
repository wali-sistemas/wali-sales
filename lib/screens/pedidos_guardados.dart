import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:productos_app/models/DatabaseHelper.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidosGuardadosPage extends StatefulWidget {
  const PedidosGuardadosPage({Key? key}) : super(key: key);

  @override
  State<PedidosGuardadosPage> createState() => _PedidosGuardadosPageState();
}

class _PedidosGuardadosPageState extends State<PedidosGuardadosPage> {
  final String codigo = GetStorage().read('slpCode');
  final GetStorage storage = GetStorage();
  final String usuario = GetStorage().read('usuario');
  final String empresa = GetStorage().read('empresa');

  final DateTime now = DateTime.now();
  final NumberFormat numberFormat = NumberFormat.simpleCurrency();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = false;

  String year = "";
  String mes = "";
  String dia = "";

  final Connectivity _connectivity = Connectivity();

  List<Pedido> pedidosG = [];
  List ordenesGuardadasServidor = [];
  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> data = [];
  List clientes = [];

  final Set<DateTime> _markedDays = {};

  late Future<List<dynamic>> _ordenesFuture;

  final Map<String, dynamic> pedidoInicial = {
    "cardCode": "",
    "cardName": "",
    "nit": "",
    "comments": "",
    "companyName": "IGB",
    "numAtCard": "",
    "shipToCode": "",
    "payToCode": "",
    "slpCode": 0,
    "discountPercent": 0.0,
    "docTotal": ""
  };

  final Map<String, dynamic> actualizarPedidoGuardado = {
    "id": "",
    "docNum": ""
  };

  @override
  void initState() {
    super.initState();

    year = now.year.toString();
    mes = now.month.toString();
    dia = now.day.toString();

    _ordenesFuture = getOrdenesGuardadasServidor();
    getOrdersMarkedDays();
  }

  void _toggleCalendar() {
    setState(() => _showCalendar = !_showCalendar);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;

      dia = selectedDay.day.toString();
      mes = selectedDay.month.toString();
      year = selectedDay.year.toString();

      _showCalendar = false;

      _ordenesFuture = getOrdenesGuardadasServidor();
    });
  }

  Future<void> getOrdersMarkedDays() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/marked-days-saved-order/$empresa?slpcode=$usuario';

    final response = await http.get(Uri.parse(apiUrl));
    data = jsonDecode(response.body);

    final DateFormat dateFormat = DateFormat("yyyy-MM-dd");

    _markedDays.clear();
    for (final obj in data) {
      final DateTime f = dateFormat.parse(obj.toString());
      _markedDays.add(DateTime(f.year, f.month, f.day));
    }

    if (!mounted) return;
    // Para repintar markers
    setState(() {});
  }

  Future<void> actualizarEstadoPedGuardado(int idP) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/process-saved-order/$empresa?id=${idP.toString()}&docNum=0&status=C';

    await http.get(Uri.parse(apiUrl));
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> consultarGuardados() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final pedidos = await dbHelper.getPedidos();

    if (!mounted) return;
    setState(() => pedidosG = pedidos);
  }

  void showConfirmOrderSave(BuildContext context, int idOrder, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Text("Atención!"),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NO"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await actualizarEstadoPedGuardado(idOrder);
                storage.remove('pedidoGuardado');

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("SI"),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> getOrdenesGuardadasServidor() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-order-saves/$empresa?slpcode=$usuario&year=$year&month=$mes&day=$dia';

    final response = await http.get(Uri.parse(apiUrl));
    data = jsonDecode(response.body);
    return data;
  }

  Future<http.Response> _generateReportOrderSaved(String docNum) async {
    const String url =
        'http://wali.igbcolombia.com:8080/manager/res/report/generate-report';

    return http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          'id': docNum,
          'copias': 0,
          'documento': 'orderSaved',
          'companyName': empresa,
          'origen': 'W',
          'imprimir': false,
        },
      ),
    );
  }

  void showAlertDialogItemsInShoppingCart(BuildContext context) {
    final Widget cancelButton = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text("NO"),
    );

    final Widget continueButton = ElevatedButton(
      onPressed: () {
        storage.remove("observaciones");
        storage.remove("pedido");
        storage.remove("itemsPedido");
        storage.remove("dirEnvio");
        storage.remove("pedidoGuardado");
        storage.write("estadoPedido", "nuevo");

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
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
      content: const Text(
        "Tiene ítems agregados al carrito, si continúa se borrarán e iniciará un pedido nuevo.\n¿Desea continuar?",
      ),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => alert,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onTap: () {
            storage.remove('observaciones');
            storage.remove("pedido");
            storage.remove("dirEnvio");
            storage.remove("pedidoGuardado");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: const [
          CarritoPedido(),
        ],
        title: const ListTile(
          title: Text(
            'Pedidos guardados',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _toggleCalendar,
            ),
            if (_showCalendar)
              TableCalendar(
                calendarFormat: _calendarFormat,
                focusedDay: _focusedDay,
                firstDay: DateTime(2000),
                lastDay: DateTime(2050),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final d = DateTime(date.year, date.month, date.day);
                    if (_markedDays.contains(d)) {
                      return const Positioned(
                        right: 5,
                        top: 5,
                        child: _MarkerDot(),
                      );
                    }
                    return null;
                  },
                  selectedBuilder: (context, date, _) =>
                      _SelectedDay(date: date),
                ),
              ),
            _pedidosGuardados(context),
          ],
        ),
      ),
    );
  }

  Widget _pedidosGuardados(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<dynamic>>(
        future: _ordenesFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (data == null) {
            return const Center(
              child: Text('Error al tratar de realizar la consulta'),
            );
          }

          if (data.isEmpty ||
              (data.isNotEmpty &&
                  data[0] is Map &&
                  data[0]["content"] ==
                      "No se encontraron ordenes guardadas para mostrar.")) {
            return const Center(
              child: Text('No se encontraron ordenes guardadas para mostrar'),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              String totalTxt = numberFormat.format(data[index]["docTotal"]);
              if (totalTxt.length >= 3) {
                totalTxt = totalTxt.substring(0, totalTxt.length - 3);
              }

              return Card(
                color: const Color.fromRGBO(250, 251, 253, 1),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 40,
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              showConfirmOrderSave(
                                context,
                                data[index]["id"],
                                "¿Está seguro de eliminar la orden guardada?",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Text(
                        'Fecha: ' +
                            data[index]["docDate"].toString() +
                            '\n' +
                            data[index]["cardCode"].toString() +
                            '\n' +
                            data[index]["cardName"].toString() +
                            '\n' +
                            'Orden: ' +
                            data[index]["id"].toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Observación: ' + data[index]["comments"].toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        "Total: " + totalTxt,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          child: IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            onPressed: () async {
                              try {
                                final http.Response response =
                                    await _generateReportOrderSaved(
                                  data[index]["id"].toString(),
                                );

                                final Map<String, dynamic> resultado =
                                    jsonDecode(response.body);

                                if (response.statusCode == 200 &&
                                    resultado['content'] != "") {
                                  final Uri url = Uri.parse(
                                    "https://drive.google.com/viewerng/viewer?embedded=true&url=http://wali.igbcolombia.com:8080/shared/" +
                                        GetStorage().read('empresa') +
                                        "/sales/orderSaved/" +
                                        data[index]["id"].toString() +
                                        ".pdf",
                                  );

                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    await launchUrl(url);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No se pudo generar el documento, error de red, verifique conectividad por favor',
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No fue posible ver el detalle de la orden guardada.',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                          width: 50,
                        ),
                        SizedBox(
                          child: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (GetStorage().read('itemsPedido') == null) {
                                if (GetStorage().read('pedido') == null) {
                                  storage.write('pedido', {});
                                  return;
                                }

                                final Map<String, dynamic> pedidoFinal =
                                    Map<String, dynamic>.from(pedidoInicial);

                                pedidoFinal['cardCode'] =
                                    data[index]["cardCode"];
                                pedidoFinal['companyName'] =
                                    data[index]["companyName"];
                                pedidoFinal['comments'] =
                                    data[index]["comments"];
                                pedidoFinal['numAtCard'] =
                                    data[index]["numAtCard"];
                                pedidoFinal['shipToCode'] =
                                    data[index]["shipToCode"];
                                pedidoFinal['payToCode'] =
                                    data[index]["payToCode"];
                                pedidoFinal['discountPercent'] =
                                    data[index]["discountPercent"];
                                pedidoFinal['docTotal'] = totalTxt;
                                pedidoFinal['lineNum'] =
                                    data[index]["lineNum"] ?? '';
                                pedidoFinal['id'] = data[index]["id"];

                                final List tempItemsList = List.from(
                                  data[index]["detailSalesOrderSave"],
                                );

                                for (final k in tempItemsList) {
                                  k['quantity'] = k['quantity'].toString();
                                  k['price'] = k['price'].toString();
                                  k['iva'] = k['iva'].toString();
                                }

                                pedidoFinal['detailSalesOrder'] = tempItemsList;

                                storage.write('pedidoGuardado', pedidoFinal);
                                storage.write('itemsPedido', tempItemsList);
                                storage.write('pedido', pedidoFinal);

                                final int idG = data[index]["id"];
                                actualizarPedidoGuardado["id"] = idG.toString();

                                storage.write(
                                    'cardCode', data[index]["cardCode"]);
                                storage.write('actualizarPedidoGuardado',
                                    actualizarPedidoGuardado);
                                storage.write('estadoPedido', 'guardado');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PedidosPage(),
                                  ),
                                );
                              } else {
                                showAlertDialogItemsInShoppingCart(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SelectedDay extends StatelessWidget {
  final DateTime date;

  const _SelectedDay({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(4.0),
      color: Colors.blue,
      child: Center(
        child: Text(
          '${date.day}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
