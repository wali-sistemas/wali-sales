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
  bool _showPedidos = false;

  String year = '';
  String mes = '';
  String dia = '';

  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();

    year = now.year.toString();
    mes = now.month.toString();
    dia = now.day.toString();

    _fetchData(year, mes, dia);
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
    });

    _fetchData(year, mes, dia);
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> listarPedidosGuardados() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final pedidos = await dbHelper.getPedidos();

    if (!mounted) return;
    setState(() {
      pedidosG = pedidos;
    });
  }

  Future<http.Response> _generateReportOrderDetail(String docNum) async {
    const String url =
        'http://wali.igbcolombia.com:8080/manager/res/report/generate-report';

    return http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          'id': docNum,
          'copias': 0,
          'documento': 'orderDetail',
          'companyName': empresa,
          'origen': 'S',
          'imprimir': false,
        },
      ),
    );
  }

  Future<void> _fetchData(String year, String mes, String dia) async {
    final bool isConnected = await checkConnectivity();

    if (isConnected) {
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
      final Map<String, dynamic> resp = jsonDecode(response.body);

      final codigoError = resp['code'];

      if (!mounted) return;

      setState(() {
        if (codigoError == -1) {
          _ventas = [];
        } else {
          _ventas = resp['content'];
          storage.write('ventas', _ventas);
        }
      });
    } else {
      final cached = GetStorage().read('ventas');
      if (cached != null) {
        if (!mounted) return;
        setState(() => _ventas = cached);
      } else {
        if (!mounted) return;
        setState(() => _ventas = []);
      }
    }
  }

  String _formatTotal(dynamic value) {
    String total = numberFormat.format(value);
    final p = total.indexOf('.');
    if (p != -1) total = total.substring(0, p);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: const Icon(
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
        actions: const [
          CarritoPedido(),
        ],
        title: ListTile(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegatePedidos(),
            );
          },
          title: const Row(
            children: [
              Icon(Icons.search, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'Buscar enviados',
                style: TextStyle(color: Colors.white),
              ),
            ],
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
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _toggleCalendar,
                ),
                IconButton(
                  icon: const Icon(Icons.save),
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
                        padding: const EdgeInsets.all(8),
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
                            style: const TextStyle(fontSize: 15),
                          ),
                          subtitle: Text(
                            'Total: ' + pedidosG[index].docTotal.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: TextButton.icon(
                            onPressed: () {},
                            label: const Text(''),
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_showCalendar)
              TableCalendar(
                calendarFormat: _calendarFormat,
                focusedDay: _focusedDay,
                firstDay: DateTime(2000),
                lastDay: DateTime(2050),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            _pedidos(context),
          ],
        ),
      ),
    );
  }

  Widget _pedidos(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: _ventas.length,
        itemBuilder: (context, index) {
          final total = _formatTotal(_ventas[index]['docTotal']);

          return Card(
            child: Container(
              color: const Color.fromRGBO(250, 251, 253, 1),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha: ' +
                                _ventas[index]['docDate'].toString() +
                                ' - Nit: ' +
                                _ventas[index]['cardCode'].toString() +
                                '\n' +
                                _ventas[index]['cardName'].toString() +
                                '\n' +
                                'Orden: ' +
                                _ventas[index]['docNum'].toString() +
                                '\n' +
                                'Estado: ' +
                                _ventas[index]['status'].toString(),
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            'Total: ' + total,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () async {
                        try {
                          final http.Response response =
                              await _generateReportOrderDetail(
                            _ventas[index]['docNum'].toString(),
                          );

                          final Map<String, dynamic> resultado =
                              jsonDecode(response.body);

                          if (response.statusCode == 200 &&
                              resultado['content'] != "") {
                            final Uri url = Uri.parse(
                              "https://drive.google.com/viewerng/viewer?embedded=true&url=http://wali.igbcolombia.com:8080/shared/" +
                                  GetStorage().read('empresa') +
                                  "/sales/orderDetail/" +
                                  _ventas[index]['docNum'].toString() +
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
                                'No fue posible ver el detalle de la orden.',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
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
}
