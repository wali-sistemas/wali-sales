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

class PedidosGuardadosPage extends StatefulWidget {
  const PedidosGuardadosPage({Key? key}) : super(key: key);

  @override
  State<PedidosGuardadosPage> createState() => _PedidosGuardadosPageState();
}

class _PedidosGuardadosPageState extends State<PedidosGuardadosPage> {
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
  List<Pedido> pedidosG = [];
  List ordenesGuardadasServidor = [];
  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> data = [];
  List clientes = [];
  final Set<DateTime> _markedDays = {};

  Map<String, dynamic> pedidoInicial = {
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

  final actualizarPedidoGuardado = {"id": "", "docNum": ""};

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  @override
  void initState() {
    year = now.year.toString();
    mes = now.month.toString();
    dia = now.day.toString();

    super.initState();
    getOrdersMarkedDays();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(
      () {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        dia = selectedDay.day.toString();
        mes = selectedDay.month.toString();
        year = selectedDay.year.toString();
        // Oculta el calendario después de seleccionar un día
        _showCalendar = false;
      },
    );
  }

  Future<void> getOrdersMarkedDays() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/marked-days-saved-order/' +
            empresa +
            '?slpcode=' +
            usuario;
    final response = await http.get(Uri.parse(apiUrl));
    data = jsonDecode(response.body);

    for (String obj in data) {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd");
      DateTime f = dateFormat.parse(obj);

      _markedDays.add(f);
    }
  }

  Future<void> actualizarEstadoPedGuardado(int idP) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/process-saved-order/' +
            empresa +
            '?id=' +
            idP.toString() +
            '&docNum=0&status=C';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.body == "true") {
      //print("Se cambió estado a C");
    } else {
      //print("No se pudo cambiar el estado a C");
    }
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> consultarGuardados() async {
    List<Pedido> pedidos = [];
    DatabaseHelper dbHelper = DatabaseHelper();
    pedidos = await dbHelper.getPedidos();
    setState(
      () {
        pedidosG = pedidos;
      },
    );
  }

  void showConfirmOrderSave(BuildContext context, int idOrder, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Atención"),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("NO"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () {
                    if (!mounted) return;
                    actualizarEstadoPedGuardado(idOrder);
                    storage.remove('pedidoGuardado');
                  },
                );
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("SI"),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> getOrdenesGuardadasServidor() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-order-saves/' +
            empresa +
            '?slpcode=' +
            usuario +
            '&year=' +
            year.toString() +
            '&month=' +
            mes.toString() +
            '&day=' +
            dia.toString();
    final response = await http.get(Uri.parse(apiUrl));
    data = jsonDecode(response.body);

    // setState(() {
    //   if (!mounted) return;
    //   ordenesGuardadasServidor = data;
    // });

    //ordenesGuardadasServidor.add(data[0]);

    // if (!resp["content"].toString().contains("Ocurrio un error")) {
    //  data = resp["content"];
    //  ordenesGuardadasServidor.add(data);
    //
    // }
    // else {
    //   data={"code":-1,"content":"Ocurrio un error"};
    //
    // }
    return data;
  }

  void _mostrarPedidos() {
    setState(
      () {
        _showPedidos = !_showPedidos;
      },
    );
  }

  void showAlertDialogItemsInShoppingCart(BuildContext context) {
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed: () {
        storage.remove("observaciones");
        storage.remove("pedido");
        storage.remove("itemsPedido");
        storage.remove("dirEnvio");
        storage.remove("pedidoGuardado");
        storage.write("estadoPedido", "nuevo");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text(
        "Tiene ítems agregados al carrito, si continúa se borrarán e iniciará un pedido nuevo, desea continuar?",
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
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
            storage.remove('observaciones');
            storage.remove("pedido");
            storage.remove("dirEnvio");
            storage.remove("pedidoGuardado");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          },
        ),
        actions: [
          CarritoPedido(),
        ],
        title: ListTile(
          onTap: () {
            /*showSearch(
              context: context,
              delegate: CustomSearchDelegatePedidos(),
            );*/
          },
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
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (_markedDays.contains(
                          DateTime(date.year, date.month, date.day))) {
                        return Positioned(
                          right: 5,
                          top: 5,
                          child: _buildMarker(),
                        );
                      }
                      return null;
                    },
                    selectedBuilder: (context, date, _) {
                      return _buildSelectedMarker(date);
                    },
                  ),
                ),
              ),
            pedidosGuardados(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSelectedMarker(DateTime date) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(4.0),
      color: Colors.blue,
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle().copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget pedidosGuardados(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<dynamic>>(
        future: getOrdenesGuardadasServidor(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          var data = snapshot.data;
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            var datalength = data.length;
            if (datalength == 0 ||
                snapshot.data![0]["content"] ==
                    "No se encontraron ordenes guardadas para mostrar.") {
              return const Center(
                child: Text('No se encontraron ordenes guardadas para mostrar'),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  String totalTxt =
                      numberFormat.format(snapshot.data![index]["docTotal"]);
                  totalTxt = totalTxt.substring(0, totalTxt.length - 3);
                  if (snapshot.hasData) {
                    return Card(
                      color: Color.fromRGBO(250, 251, 253, 1),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 40,
                                child: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    showConfirmOrderSave(
                                      context,
                                      snapshot.data![index]["id"],
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
                                  snapshot.data![index]["docDate"].toString() +
                                  '\n' +
                                  snapshot.data![index]["cardCode"].toString() +
                                  '\n' +
                                  snapshot.data![index]["cardName"].toString() +
                                  '\n' +
                                  'Orden: ' +
                                  snapshot.data![index]["id"].toString(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Observación: ' +
                                  snapshot.data![index]["comments"].toString(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                          ),
                          ListTile(
                            title: Text(
                              "Total: " + totalTxt,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 40,
                                child: IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    if (GetStorage().read('itemsPedido') ==
                                        null) {
                                      if (GetStorage().read('pedido') == null) {
                                        storage.write('pedido', {});
                                      } else {
                                        Map<String, dynamic> pedidoFinal =
                                            Map<String, dynamic>.from(
                                                pedidoInicial);
                                        pedidoFinal['cardCode'] =
                                            snapshot.data![index]["cardCode"];
                                        pedidoFinal['companyName'] = snapshot
                                            .data![index]["companyName"];
                                        pedidoFinal['comments'] =
                                            snapshot.data![index]["comments"];
                                        pedidoFinal['numAtCard'] =
                                            snapshot.data![index]["numAtCard"];
                                        pedidoFinal['shipToCode'] =
                                            snapshot.data![index]["shipToCode"];
                                        pedidoFinal['payToCode'] =
                                            snapshot.data![index]["payToCode"];
                                        pedidoFinal['discountPercent'] =
                                            snapshot.data![index]
                                                ["discountPercent"];
                                        pedidoFinal['docTotal'] = totalTxt;
                                        pedidoFinal['lineNum'] =
                                            snapshot.data![index]["lineNum"] ??
                                                '';
                                        pedidoFinal['id'] =
                                            snapshot.data![index]["id"];

                                        List tempItemsList =
                                            snapshot.data![index]
                                                ["detailSalesOrderSave"];

                                        /// Pasar a texto campo "quantity" "iva" y "price" que viende del servicio
                                        tempItemsList.forEach((k) {
                                          k['quantity'] =
                                              k['quantity'].toString();
                                          k['price'] = k['price'].toString();
                                          k['iva'] = k['iva'].toString();
                                        });

                                        pedidoFinal['detailSalesOrder'] =
                                            tempItemsList;

                                        setState(
                                          () {
                                            storage.write(
                                                'pedidoGuardado', pedidoFinal);
                                            storage.write(
                                                'itemsPedido',
                                                snapshot.data![index]
                                                    ["detailSalesOrderSave"]);
                                            storage.write(
                                                'pedido', pedidoFinal);
                                            int idG =
                                                snapshot.data![index]["id"];
                                            actualizarPedidoGuardado["id"] =
                                                idG.toString();
                                            storage.write(
                                                'cardCode',
                                                snapshot.data![index]
                                                    ["cardCode"]);
                                            storage.write(
                                                'actualizarPedidoGuardado',
                                                actualizarPedidoGuardado);
                                            storage.write(
                                                'estadoPedido', 'guardado');
                                          },
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PedidosPage(),
                                          ),
                                        );
                                      }
                                    } else {
                                      showAlertDialogItemsInShoppingCart(
                                        context,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Text('Error al tratar de realizar la consulta');
                  }
                },
              );
            }
          }
        },
      ),
    );
  }
}
