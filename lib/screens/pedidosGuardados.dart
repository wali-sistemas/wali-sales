import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/screens/buscador_pedidos.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity/connectivity.dart';
import 'package:productos_app/models/DatabaseHelper.dart';

class PedidosGuardadosPage extends StatefulWidget {
  const PedidosGuardadosPage({Key? key}) : super(key: key);

  @override
  State<PedidosGuardadosPage> createState() => _PedidosGuardadosPageState();
}

class _PedidosGuardadosPageState extends State<PedidosGuardadosPage> {
  List _ventas = [];

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

  final pedidoInicial = {
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
      print("Dia seleccionado: $diaSel");
      _showCalendar =
          false; // Oculta el calendario después de seleccionar un día
      // if(GetStorage().read('ventas')!=null)
      //   print(GetStorage().read('ventas'));
      //storage.remove("ventas");
    });

    //_fetchData("2023", mesSel, diaSel);
  }

  Future<void> actualizarEstadoPedGuardado(int idP) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/process-saved-order/' +
            empresa +
            '?id=' +
            idP.toString() +
            '&docNum=0&status=C';
    //print ("URL ACTUALIZARSERVICIO2: ");print (apiUrl);
    final response = await http.get(Uri.parse(apiUrl));
    //print ("Respuesta actualizarServicio2: ");print (response.body);
    if (response.body == "true") {
      print("Se cambió estado a C");
    } else {
      print("No se pudo cambiar el estado a C");
    }
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  List<Pedido> pedidosG = [];
  List ordenesGuardadasServidor = [];

  Future<void> consultarGuardados() async {
    List<Pedido> pedidos = [];
    DatabaseHelper dbHelper = DatabaseHelper();
    pedidos = await dbHelper.getPedidos();
    setState(() {
      pedidosG = pedidos;
    });
  }

  void showConfirmOrderSave(BuildContext context, int idOrder, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Atención"),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Cierra el diálogo al presionar este botón
                Navigator.pop(context);
              },
              child: Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (!mounted) return;
                  actualizarEstadoPedGuardado(idOrder);
                  storage.remove('pedidoGuardado');
                });
                // Cierra el diálogo al presionar este botón
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("Si"),
            ),
          ],
        );
      },
    );
  }

  List<dynamic> data = [];
  ////// Traer pedidos guardados del sevidor
  Future<List<dynamic>> getOrdenesGuardadasServidor() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-order-saves/' +
            empresa! +
            '?slpcode=' +
            usuario! +
            '&year=' +
            year.toString() +
            '&month=' +
            mes.toString() +
            '&day=' +
            dia.toString();
    final response = await http.get(Uri.parse(apiUrl));
    data = jsonDecode(response.body);

    setState(() {
      if (!mounted) return;
      ordenesGuardadasServidor = data;
    });

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
    if (data != null)
      return data;
    else
      return [];
  }

  ///

  void _mostrarPedidos() {
    setState(() {
      _showPedidos = !_showPedidos;
    });
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
                delegate: CustomSearchDelegate(),
              );
            },
            title: Text('Buscar', style: TextStyle(color: Colors.white)),
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
                ),
              ),
            pedidosGuardados(context),
          ],
        )));
  }

  Widget pedidosGuardados(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<dynamic>>(
        future: getOrdenesGuardadasServidor(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          var data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
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
                                            "¿Está seguro de eliminar la orden guardada?");
                                      },
                                    )),
                              ],
                            ),
                            ListTile(
                                title: Text(
                                  'Fecha: ' +
                                      snapshot.data![index]["docDate"]
                                          .toString() +
                                      '\n' +
                                      snapshot.data![index]["cardCode"]
                                          .toString() +
                                      '\n' +
                                      snapshot.data![index]["cardName"]
                                          .toString() +
                                      '\n' +
                                      'Orden: ' +
                                      snapshot.data![index]["id"].toString(),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Observación: ' +
                                      snapshot.data![index]["comments"]
                                          .toString(),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  /*children: [
                                    SizedBox(height: 30),
                                  ],*/
                                )),
                            ListTile(
                              title: Text(
                                "Total: " + totalTxt,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
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
                                      if (GetStorage().read('pedido') == null)
                                        storage.write('pedido', {});
                                      Map<String, dynamic> pedidoFinal =
                                          pedidoInicial; //GetStorage().read('pedido');
                                      pedidoFinal['cardCode'] =
                                          snapshot.data![index]["cardCode"];
                                      pedidoFinal['companyName'] =
                                          snapshot.data![index]["companyName"];
                                      pedidoFinal['comments'] =
                                          snapshot.data![index]["comments"];
                                      pedidoFinal['numAtCard'] =
                                          snapshot.data![index]["numAtCard"];
                                      pedidoFinal['shipToCode'] =
                                          snapshot.data![index]["shipToCode"];
                                      pedidoFinal['payToCode'] =
                                          snapshot.data![index]["payToCode"];
                                      pedidoFinal['discountPercent'] = snapshot
                                          .data![index]["discountPercent"];
                                      pedidoFinal['docTotal'] = totalTxt;
                                      pedidoFinal['lineNum'] =
                                          snapshot.data![index]["lineNum"] ??
                                              '';
                                      pedidoFinal['id'] =
                                          snapshot.data![index]["id"];

                                      List tempItemsList = snapshot.data![index]
                                          ["detailSalesOrderSave"];

                                      /// Pasar a texto campo "quantity" "iva" y "price" que viende del servicio
                                      tempItemsList.forEach((k) {
                                        k['quantity'] =
                                            k['quantity'].toString();
                                        k['price'] = k['price'].toString();
                                        k['iva'] = k['iva'].toString();
                                      });

                                      //pedidoFinal['detailSalesOrder']=snapshot.data![index]["detailSalesOrderSave"];
                                      pedidoFinal['detailSalesOrder'] =
                                          tempItemsList;
                                      // print ("items Ordenes de venta: ");
                                      // print (snapshot.data![index]["detailSalesOrderSave"]);

                                      setState(() {
                                        storage.write(
                                            'pedidoGuardado', pedidoFinal);
                                        storage.write(
                                            'itemsPedido',
                                            snapshot.data![index]
                                                ["detailSalesOrderSave"]);
                                        storage.write('pedido', pedidoFinal);
                                        int idG = snapshot.data![index]["id"];
                                        actualizarPedidoGuardado["id"] =
                                            idG.toString();
                                        storage.write('cardCode',
                                            snapshot.data![index]["cardCode"]);
                                        storage.write(
                                            'actualizarPedidoGuardado',
                                            actualizarPedidoGuardado);
                                        storage.write(
                                            'estadoPedido', 'guardado');
                                      });
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PedidosPage()),
                                      );
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
                  });
            }
          }
        },
      ),
    );
  }
}
