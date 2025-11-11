import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart' as pc;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:productos_app/services/notifications_extranet_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Ejecuta el método después de 15 segundos.
    Timer.periodic(
      Duration(seconds: 15),
      (Timer t) {
        sendNotification();
      },
    );
  }

  var dataMap = <String, double>{
    "Ventas": 0,
    "Presupuesto": 0,
    "Pend. por facturar": 0,
  };

  final colorList = <Color>[
    const Color.fromRGBO(242, 83, 75, 1),
    const Color.fromRGBO(51, 51, 51, 1),
    const Color.fromRGBO(201, 204, 209, 1),
    const Color(0xffe17055),
    const Color(0xff6c5ce7),
  ];

  GetStorage storage = GetStorage();
  String? usuario = GetStorage().read('usuario');
  String? empresa = GetStorage().read('empresa');
  DateTime now = new DateTime.now();
  int presupuestoT = 0;
  double presupuestoP = 0;
  double ventasT = 0;
  int base = 0;
  int impacto = 0;
  double efectividad = 0;
  int nroOrderSaved = 0;
  double valorOrderSaved = 0;
  var numberFormat = new NumberFormat('#,##0.00', 'en_Us');

  void sendNotification() async {
    dynamic response = await _findOrderExtranetInprogress();

    if (response != null) {
      WidgetsFlutterBinding.ensureInitialized();
      showNotification(response);
      //actualiza el estado de la orden 'NOTIFICADO APP'
      _updateStatusNotificationOrderExtranet(response["docNum"]);
    }
  }

  Future<Map<String, dynamic>> _datosDashboard2() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/budget-sales/' +
            empresa! +
            '?slpcode=' +
            usuario! +
            '+&year=' +
            now.year.toString() +
            '&month=' +
            now.month.toString();
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    Map<String, dynamic> data = {};
    if (!resp["content"].toString().contains("Ocurrio un error")) {
      return resp;
    } else {
      data = {
        "code": 0,
        "content": [
          {
            "year": 2023,
            "slpCode": "56",
            "companyName": "IGB",
            "month": "04",
            "ventas": 00.00,
            "presupuesto": 00,
            "pendiente": 00.00,
            "whsDefTire": "01"
          }
        ]
      };
      return data;
    }
  }

  Future<Map<String, dynamic>> _datosBarras() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/effectiveness-sales/' +
            empresa! +
            '?slpcode=' +
            usuario! +
            '+&year=' +
            now.year.toString() +
            '&month=' +
            now.month.toString();
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp1 = jsonDecode(response.body);
    Map<String, dynamic> data = {};
    if (!resp1["content"].toString().contains("Ocurrio un error") ||
        !resp1["content"].toString().contains("No se encontraron")) {
      return resp1;
    } else {
      data = {
        "code": 0,
        "content": [
          {
            "slpCode": "56",
            "slpName": "SEBASTIAN KIZA LANCHEROS",
            "year": 2023,
            "month": 1,
            "base": 0,
            "impact": 0,
            "effectiveness": 0
          }
        ]
      };
      return data;
    }
  }

  Future<Map<String, dynamic>> _getSavedOrdersReport() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/report-saved-order/' +
            empresa! +
            '?slpcode=' +
            usuario!;
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    Map<String, dynamic> data = {};
    if (resp["code"] == 0) {
      data = {
        "code": 0,
        "content": [
          {
            "nroOrder": resp["content"][0],
            "valorOrder": resp["content"][1],
          }
        ]
      };
      return data;
    } else {
      return resp;
    }
  }

  Future<dynamic> _findOrderExtranetInprogress() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/find-order-extranet-inprogress/' +
            empresa! +
            "/" +
            usuario!;
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    if (resp["code"] == 0) {
      return resp["content"];
    } else {
      return null;
    }
  }

  Future<void> _updateStatusNotificationOrderExtranet(String docNum) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/update-status-order-extranet/' +
            empresa! +
            "/" +
            docNum;
    final response = await http.put(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp["code"] == 0) {
      resp["content"];
    }
  }

  Future<dynamic> _findSalesBudgetByBrandAndSeller() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-budget-brand/' +
            empresa! +
            '?slpcode=' +
            usuario!;
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    if (resp["code"] == 0) {
      return resp["content"];
    } else {
      return null;
    }
  }

  void showAlertDialog(BuildContext context) {
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed: () {
        storage.remove('emailAsesor');
        storage.remove('nombreAsesor');
        storage.remove('datosClientes');
        storage.remove('empresa');
        storage.remove('observaciones');
        storage.remove('chat_history');

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

  BarChartGroupData makeGroupData(int x, double x1, double x2) {
    return BarChartGroupData(
      x: x,
      barsSpace: 8,
      barRods: [
        BarChartRodData(
          toY: 100,
          width: 40,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, x1, Color.fromRGBO(15, 178, 242, 1)),
            BarChartRodStackItem(x1, x1 + x2, Color.fromRGBO(207, 240, 252, 1)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String monthName = "";
    switch (now.month) {
      case 01:
        monthName = "Enero";
        break;
      case 02:
        monthName = "Febrero";
        break;
      case 03:
        monthName = "Marzo";
        break;
      case 04:
        monthName = "Abril";
        break;
      case 05:
        monthName = "Mayo";
        break;
      case 06:
        monthName = "Junio";
        break;
      case 07:
        monthName = "Julio";
        break;
      case 08:
        monthName = "Agosto";
        break;
      case 09:
        monthName = "Septiembre";
        break;
      case 10:
        monthName = "Octubre";
        break;
      case 11:
        monthName = "Noviembre";
        break;
      case 12:
        monthName = "Diciembre";
        break;
      default:
        monthName = "Sin Definir";
    }
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
            showAlertDialog(context);
          },
        ),
        actions: [
          CarritoPedido(),
        ],
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _datosDashboard2(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    double ventasPendientes = 0.0;
                    double presupuestoPendiente = 0.0;
                    ventasT = snapshot.data!["content"][0]["ventas"];
                    presupuestoT = snapshot.data!["content"][0]["presupuesto"];
                    presupuestoP = snapshot.data!["content"][0]["pendiente"];
                    storage.write("nombreAsesor",
                        snapshot.data!["content"][0]["slpName"]);
                    storage.write(
                        "emailAsesor", snapshot.data!["content"][0]["mail"]);
                    storage.write(
                        "zona", snapshot.data!["content"][0]["whsDefTire"]);
                    storage.write("urlFoto",
                        snapshot.data!["content"][0]["urlSlpPicture"]);
                    if (presupuestoT == 0 || presupuestoT.isNaN) {
                      dataMap["Ventas"] = 0;
                      dataMap["Presupuesto"] = 0;
                      dataMap["Pend. por facturar"] = 0;
                    } else {
                      ventasPendientes = (ventasT / presupuestoT) * 100;
                      ventasPendientes =
                          double.parse((ventasPendientes).toStringAsFixed(2));
                      presupuestoPendiente =
                          (presupuestoP / presupuestoT) * 100;
                      presupuestoPendiente = double.parse(
                          (presupuestoPendiente).toStringAsFixed(2));
                      dataMap["Ventas"] = ventasT;
                      dataMap["Presupuesto"] =
                          presupuestoT.toDouble() - ventasT;
                      dataMap["Pend. por facturar"] = presupuestoP.toDouble();
                    }

                    String presupuestoTstr = numberFormat.format(presupuestoT);
                    if (presupuestoTstr.length > 2)
                      presupuestoTstr =
                          "\$" + presupuestoTstr.replaceAll(".00", "");

                    String ventastStr = numberFormat.format(ventasT);
                    if (ventastStr.contains('.')) {
                      int decimalIndex = ventastStr.indexOf('.');
                      ventastStr = "\$" + ventastStr.substring(0, decimalIndex);
                    }

                    String presupuestoPstr = numberFormat.format(presupuestoP);
                    if (presupuestoPstr.contains('.')) {
                      int decimalIndex = presupuestoPstr.indexOf('.');
                      presupuestoPstr =
                          "\$" + presupuestoPstr.substring(0, decimalIndex);
                    }
                    return Column(
                      children: [
                        SizedBox(height: 5),
                        Text(
                          "Presupuesto de ventas",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          monthName + " - " + now.year.toString(),
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 0),
                        Text(
                          presupuestoTstr,
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                '%$ventasPendientes',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                'Ventas',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                '%$presupuestoPendiente',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                'Pendiente por facturar',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        pc.PieChart(
                          dataMap: dataMap,
                          chartType: pc.ChartType.ring,
                          baseChartColor: Colors.grey[50]!.withOpacity(0.15),
                          colorList: colorList,
                          chartValuesOptions: pc.ChartValuesOptions(
                            showChartValues: false,
                            showChartValuesInPercentage: false,
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                '$ventastStr',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                'Ventas',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                '$presupuestoPstr',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Center(
                                              child: Text(
                                                'Pendiente por facturar',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error al tratar de realizar la consulta');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            Divider(),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Efectividad de clientes',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          '%$efectividad',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _datosBarras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    print("***********");
                    print(snapshot.data!["content"]);
                    print("***********");

                    if (snapshot.data!["content"]
                            .toString()
                            .contains("Ocurrio un error") ||
                        snapshot.data!["content"] ==
                            "No se encontraron datos para graficar la efectividad.") {
                    } else {
                      efectividad = 1.1;

                      base = snapshot.data!["content"]["base"];
                      impacto = snapshot.data!["content"]["impact"];
                      //efectividad = snapshot.data!["content"]["effectiveness"];
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            textBaseline: TextBaseline.ideographic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              SizedBox(height: 10),
                              Row(
                                textBaseline: TextBaseline.ideographic,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BarraGrafica(
                                    color: Color.fromRGBO(0, 55, 114, 1),
                                    valor: base.toDouble(),
                                    etiqueta: base.toString(),
                                  ),
                                  SizedBox(width: 10),
                                  BarraGrafica(
                                    color: Color.fromRGBO(51, 51, 51, 1),
                                    valor: impacto.toDouble(),
                                    etiqueta: impacto.toString(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EtiquetaBullet(
                              color: Color.fromRGBO(0, 55, 114, 1),
                              texto: 'Clientes efectivos',
                            ),
                            EtiquetaBullet(
                              color: Color.fromRGBO(51, 51, 51, 1),
                              texto: 'Presupuestado',
                            ),
                          ],
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error al tratar de realizar la consulta');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            Divider(),
            SizedBox(height: 5),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Ordenes guardadas',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getSavedOrdersReport(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    String valorOrderSavedStr = "\$0";
                    if (snapshot.data!["code"] == 0) {
                      nroOrderSaved = snapshot.data!["content"][0]["nroOrder"];
                      valorOrderSaved =
                          snapshot.data!["content"][0]["valorOrder"];
                      valorOrderSavedStr = numberFormat.format(valorOrderSaved);
                      if (valorOrderSavedStr.contains('.')) {
                        int decimalIndex = valorOrderSavedStr.indexOf('.');
                        valorOrderSavedStr = "\$" +
                            valorOrderSavedStr.substring(0, decimalIndex);
                      }
                    }
                    return Center(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        child: Center(
                                          child: Text(
                                            '$nroOrderSaved',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        child: Center(
                                          child: Text(
                                            '#',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        child: Center(
                                          child: Text(
                                            '$valorOrderSavedStr',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        child: Center(
                                          child: Text(
                                            'Total',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
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
                  } else if (snapshot.hasError) {
                    return Text('Error al tratar de realizar la consulta');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            Divider(),
            SizedBox(height: 5),
            Container(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Presupuesto por marcas',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Container(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EtiquetaBullet(
                          color: Color.fromRGBO(15, 178, 242, 1),
                          texto: 'Facturado',
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EtiquetaBullet(
                          color: Color.fromRGBO(207, 240, 252, 1),
                          texto: 'Presupuesto',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            if (empresa == "IGB")
              Container(
                child: FutureBuilder<dynamic>(
                  future: _findSalesBudgetByBrandAndSeller(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        height: 500,
                        padding: EdgeInsets.all(15),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: [
                                makeGroupData(
                                  0,
                                  snapshot.data![0]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  1,
                                  snapshot.data![1]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  2,
                                  snapshot.data![2]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  3,
                                  snapshot.data![3]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  4,
                                  snapshot.data![4]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  5,
                                  snapshot.data![5]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  6,
                                  snapshot.data![6]["percent"].toDouble(),
                                  100,
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 150,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  snapshot.data![0]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![0]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![0]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 1:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![1]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![1]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![1]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 2:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![2]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![2]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![2]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 3:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![3]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![3]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![3]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 4:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![4]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![4]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![4]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 5:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![5]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![5]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![5]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 6:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![6]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![6]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![6]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        default:
                                          return const SizedBox();
                                      }
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(enabled: true),
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return const Text(
                        'Error al tratar de realizar la consulta',
                      );
                    } else if (snapshot.data == null) {
                      return const Text(
                        'En el momento no tiene presupuesto de marca asignado',
                        textAlign: TextAlign.center,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            if (empresa == "VARROC")
              Container(
                child: FutureBuilder<dynamic>(
                  future: _findSalesBudgetByBrandAndSeller(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        height: 500,
                        padding: EdgeInsets.all(15),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: [
                                makeGroupData(
                                  0,
                                  snapshot.data![0]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  1,
                                  snapshot.data![1]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  2,
                                  snapshot.data![2]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  3,
                                  snapshot.data![3]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  4,
                                  snapshot.data![4]["percent"].toDouble(),
                                  100,
                                ),
                                makeGroupData(
                                  5,
                                  snapshot.data![5]["percent"].toDouble(),
                                  100,
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 150,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  snapshot.data![0]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![0]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![0]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 1:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![1]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![1]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![1]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 2:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![2]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![2]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![2]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 3:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              children: [
                                                Text(
                                                  snapshot.data![3]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![3]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![3]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 4:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  snapshot.data![4]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![4]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![4]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        case 5:
                                          return RotatedBox(
                                            quarterTurns: -1,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  snapshot.data![5]["result"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![5]["brand"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  snapshot.data![5]["percent"]
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        default:
                                          return const SizedBox();
                                      }
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(enabled: true),
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return const Text(
                        'Error al tratar de realizar la consulta',
                      );
                    } else if (snapshot.data == null) {
                      return const Text(
                        'En el momento no tiene presupuesto de marca asignado',
                        textAlign: TextAlign.center,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class BarraGrafica extends StatelessWidget {
  final Color color;
  final double valor;
  final String etiqueta;

  const BarraGrafica(
      {required this.color, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(etiqueta),
        Container(
          width: 35,
          height: valor,
          color: color,
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

class EtiquetaBullet extends StatelessWidget {
  final Color color;
  final String texto;

  const EtiquetaBullet({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
