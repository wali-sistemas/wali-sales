import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:productos_app/screens/pedidos_guardados.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/screens/buscador_pedidos.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:productos_app/models/DatabaseHelper.dart';
import 'package:url_launcher/url_launcher.dart';

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

    _fetchData(year, mes, dia);
  }

  void _onDaySelected(DateTime selectedDay, DateTime selectedMes) {
    setState(
      () {
        _selectedDay = selectedDay;
        dia = selectedDay.day.toString();
        mes = selectedDay.month.toString();
        year = selectedDay.year.toString();
        //Consultar datos por ano, mes y día seleccionado
        _fetchData(year, mes, dia);
        //Ocultar calendario
        _showCalendar = false;
      },
    );
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

  Future<http.Response> _generateReportOrderDetail(String docNum) async {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/report/generate-report';
    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          'id': docNum,
          "copias": 0,
          "documento": "orderDetail",
          "companyName": empresa,
          "origen": "S",
          "imprimir": false
        },
      ),
    );
  }

  Future<void> _downloadDetailOrderPDF(
      String pdfUrl, String dateDoc, String docNum) async {
    final response = await http.get(Uri.parse(pdfUrl));

    if (response.statusCode == 200) {
      final Uint8List pdfBytes = response.bodyBytes;
      final pdfFile = File('/storage/emulated/0/Download/Detalle-Orden[' +
          docNum +
          '-' +
          dateDoc +
          '].pdf');
      await pdfFile.writeAsBytes(pdfBytes);
    } else {
      throw Exception('Error al descargar el detalle de la orden');
    }
  }

  /*void _mostrarPedidos() {
    setState(() {
      _showPedidos = !_showPedidos;
    });
  }*/

  Future<void> _fetchData(String year, String mes, String dia) async {
    bool isConnected = await checkConnectivity();
    if (isConnected == true) {
      //if (GetStorage().read('ventas') == null) {
      final String apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/list-order/' +
              empresa +
              '?slpcode=' +
              usuario +
              '&year=' +
              year +
              '&month=' +
              mes +
              '&day=' +
              dia;
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        _ventas = [];
      } else {
        final data = resp["content"];
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
      backgroundColor: Colors.white,
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
            'Buscar enviados',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _toggleCalendar,
                ),
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PedidosGuardadosPage(),
                      ),
                    );
                  },
                ),
              ],
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
                            label: Text(
                              '',
                            ),
                            icon: Icon(Icons.add),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
              color: Color.fromRGBO(250, 251, 253, 1),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha: ' +
                                _ventas[index]["docDate"].toString() +
                                ' - Nit: ' +
                                _ventas[index]["cardCode"].toString() +
                                '\n' +
                                _ventas[index]["cardName"].toString() +
                                '\n' +
                                'Orden: ' +
                                _ventas[index]["docNum"].toString() +
                                '\n' +
                                'Estado: ' +
                                _ventas[index]["status"].toString(),
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "Total: " + total,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          http.Response response =
                              await _generateReportOrderDetail(
                                  _ventas[index]["docNum"].toString());

                          Map<String, dynamic> resultado =
                              jsonDecode(response.body);

                          if (response.statusCode == 200 &&
                              resultado['content'] != "") {
                            final Uri url = Uri.parse(
                              "https://drive.google.com/viewerng/viewer?embedded=true&url=http://wali.igbcolombia.com:8080/shared/" +
                                  GetStorage().read('empresa') +
                                  "/sales/orderDetail/" +
                                  _ventas[index]["docNum"].toString() +
                                  ".pdf",
                            );

                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              launchUrl(url);
                            }
                            /*_downloadDetailOrderPDF(
                              'http://wali.igbcolombia.com:8080/shared/' +
                                  GetStorage().read('empresa') +
                                  '/sales/orderDetail/' +
                                  _ventas[index]["docNum"].toString() +
                                  '.pdf',
                              DateFormat("yyyyMMdd-hhmm").format(now),
                              _ventas[index]["docNum"].toString(),
                            );*/

                            /*ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Detalle de la orden guardada en descargas',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );*/
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se pudo guardar el pedido, error de red, verifique conectividad por favor',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al generar el reporte para ver el detalle de la orden',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.remove_red_eye_outlined),
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
