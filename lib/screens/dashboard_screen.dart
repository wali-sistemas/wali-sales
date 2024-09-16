import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:pie_chart/pie_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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
      //TODO: actualiza rel estado de la orden 'NOTIFICADO APP'
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
            "effectiveness": 0.0
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
        SystemNavigator.pop();
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

  String apkUrl = 'https://administradores.cito.club/t/nuevaversion.apk';

  Future<void> checkAndUpdateApk() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final appDirectory = await getExternalStorageDirectory();

      final downloadDirectory = '${appDirectory?.path}/Download';
      //Directory dir = Directory('/storage/emulated/0/Download');
      final savedDir = Directory(downloadDirectory);
      if (!savedDir.existsSync()) {
        savedDir.createSync(recursive: true);
      }
      final savedFile = File('$downloadDirectory/nuevaversion.apk');

      final response = await http.head(Uri.parse(apkUrl));

      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        final remoteFileSize = int.tryParse(contentLength ?? '0') ?? 0;
        final localFileSize =
            savedFile.existsSync() ? await savedFile.length() : 0;

        if (localFileSize != remoteFileSize) {
          // Descargar el nuevo archivo APK
          await FlutterDownloader.enqueue(
            url: apkUrl,
            savedDir: downloadDirectory,
            fileName: 'nuevaversion.apk',
            showNotification: true,
            openFileFromNotification: true,
          );
        }
      } else {
        _showSnackBar(context, "No se encontró nueva versión");
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3), // Duración de la notificación
      ),
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
                    if (presupuestoT == 0 ||
                        presupuestoT.isNaN ||
                        presupuestoT == null) {
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
                        Divider(),
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
                        PieChart(
                          dataMap: dataMap,
                          chartType: ChartType.ring,
                          baseChartColor: Colors.grey[50]!.withOpacity(0.15),
                          colorList: colorList,
                          chartValuesOptions: ChartValuesOptions(
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
                              )),
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
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _datosBarras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!["content"]
                            .toString()
                            .contains("Ocurrio un error") ||
                        snapshot.data!["content"] ==
                            "No se encontraron datos para graficar la efectividad.") {
                    } else {
                      base = snapshot.data!["content"]["base"];
                      impacto = snapshot.data!["content"]["impact"];
                      efectividad = snapshot.data!["content"]["effectiveness"];
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
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              width: double.infinity,
              height: 0.2,
              color: Colors.black,
            ),
            SizedBox(
              height: 5,
            ),
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
                  )),
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
            SizedBox(
              height: 10,
            ),
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
