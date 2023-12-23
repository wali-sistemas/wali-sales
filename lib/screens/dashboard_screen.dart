import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:pie_chart/pie_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:productos_app/widgets/carrito.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  var dataMap = <String, double>{
    "Ventas": 0,
    "Presupuesto": 0,
    "Pend. por facturar": 0,
  };

  final colorList = <Color>[
    const Color(0xfffdcb6e),
    const Color(0xff0984e3),
    const Color(0xfffd79a8),
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
  double efectividad = 0.0;
  var numberFormat = new NumberFormat('#,##0.00', 'en_Us');

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
    //print("REspuesta Dashboard: --------------------");
    //print(resp.toString());
    Map<String, dynamic> data = {};
    if (!resp["content"].toString().contains("Ocurrio un error")) {
      return resp;

      // if (GetStorage().read('presupuesto') == null) {
      //   storage.write('presupuesto', resp["content"]);
      //   return resp;
      //}
      //else { Map<String, dynamic>  _presupuesto=GetStorage().read('presupuesto'); return _presupuesto;}
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
    //print("REspuesta Barras: --------------------");
    //print(resp1.toString());
    Map<String, dynamic> data = {};
    if (!resp1["content"].toString().contains("Ocurrio un error") ||
        !resp1["content"].toString().contains("No se encontraron")) {
      return resp1;

      // if (GetStorage().read('presupuesto') == null) {
      //   storage.write('presupuesto', resp["content"]);
      //   return resp;
      //}
      //else { Map<String, dynamic>  _presupuesto=GetStorage().read('presupuesto'); return _presupuesto;}
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

  showAlertDialog(BuildContext context) {
    // set up the buttons
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
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => LoginScreen()),
        // );
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text("Está seguro que desea salir de la aplicación?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
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
      //print("Directorio: ");
      //print(appDirectory);
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
    //_datosDashboard();
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
          child: Column(children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _datosDashboard2(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    //print("datos ---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>--------------------");
                    //print (snapshot.data!["content"][0]["ventas"]);
                    //print (snapshot.data!["content"][0]["slpName"]);
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
                    //presupuestoTstr=presupuestoTstr.substring(0,presupuestoTstr.length-3);
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

                    return Column(children: [
                      SizedBox(height: 50),
                      Text(
                        "Presupuesto",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        presupuestoTstr,
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      Text("Presupuesto total"),
                      SizedBox(height: 50),
                      Center(
                        child: Text(
                          'Ventas $ventasPendientes %    Pendiente \n                        por facturar  $presupuestoPendiente %',
                          style: TextStyle(fontSize: 20),
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
                        //totalValue: 100,
                      ),
                      SizedBox(height: 50),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Text(ventastStr + '\n    Ventas',
                                  style: TextStyle(fontSize: 18)),
                            ),
                            Expanded(
                              child: Text(
                                presupuestoPstr + '\nPend. por facturar',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  } else if (snapshot.hasError) {
                    return Text('Error al tratar de realizar la consulta');
                  }

                  // By default, show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _datosBarras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    //print("datos ---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>--------------------");
                    //print(snapshot.data!["content"].toString());
                    //print (snapshot.data!["content"][0]["ventas"]);
                    //print (snapshot.data!["content"][0]["slpName"]);
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

                    // if(presupuestoTstr.length>2)
                    //   presupuestoTstr="\$"+presupuestoTstr.replaceAll(".00", "");
                    // //presupuestoTstr=presupuestoTstr.substring(0,presupuestoTstr.length-3);
                    // String ventastStr=numberFormat.format(ventasT);
                    // if (ventastStr.contains('.')) {
                    //   int decimalIndex = ventastStr.indexOf('.');
                    //   ventastStr="\$"+ventastStr.substring(0, decimalIndex);
                    // }
                    // String presupuestoPstr=numberFormat.format(presupuestoP);
                    //
                    // if (presupuestoPstr.contains('.')) {
                    //   int decimalIndex = presupuestoPstr.indexOf('.');
                    //   presupuestoPstr="\$"+presupuestoPstr.substring(0, decimalIndex);
                    // }

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            textBaseline: TextBaseline.ideographic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              SizedBox(height: 16),
                              Center(
                                child: Text(
                                  '           Efectividad',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                              SizedBox(height: 45),
                              Row(
                                textBaseline: TextBaseline.ideographic,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BarraGrafica(
                                      color: Colors.blue,
                                      valor: base.toDouble(),
                                      etiqueta: base.toString()),
                                  SizedBox(width: 16),
                                  BarraGrafica(
                                      color: Colors.yellow,
                                      valor: impacto.toDouble(),
                                      etiqueta: impacto.toString()),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$efectividad %',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            EtiquetaBullet(
                                color: Colors.yellow,
                                texto: 'Clientes efectivos'),
                            SizedBox(height: 16),
                            EtiquetaBullet(
                                color: Colors.blue,
                                texto: 'Presupuesto \nde clientes'),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error al tratar de realizar la consulta');
                  }

                  // By default, show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1),
              width: double.infinity,
              height: 2,
              color: Colors.red,
            ),
          ]),
        ));
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
        Text(texto,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
