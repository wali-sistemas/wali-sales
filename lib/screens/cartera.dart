
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:productos_app/screens/buscador_cartera.dart';
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class CarteraPage extends StatefulWidget {
  const CarteraPage({Key? key}) : super(key: key);
  @override
  State<CarteraPage> createState() => CarteraPageState();
}

class CarteraPageState extends State<CarteraPage> {
  List _cartera = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');
  String usuario = GetStorage().read('usuario');
  Connectivity _connectivity = Connectivity();
  Map<String, dynamic> pedidoLocal = {};
  List<dynamic> itemsPedidoLocal = [];
  List<Map<String, dynamic>> detalleCartera = [];
  List<Map<String, dynamic>> detallePortafolio = [];

  var numberFormat = new NumberFormat('#,##0.00', 'en_Us');

  @override
  void initState() {
    super.initState();
    _fetchDataCartera();
    _fetchDataDetailCartera();
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _fetchDataCartera() async {
    //if (GetStorage().read('datosCartera') == null) {
    String apiUrl = '';
    if (GetStorage().read('nitFiltroCartera') == null) {
      apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/customers-portfolio/' +
              empresa +
              '?slpcode=' +
              codigo;
    } else {
      apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/customers-portfolio/' +
              empresa +
              '?slpcode=' +
              codigo +
              '&cardcode=' +
              GetStorage().read('nitFiltroCartera');
    }

    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    String texto = "No se encontro cartera para asesor " +
        codigo +
        " en la empresa " +
        empresa;

    final codigoError = resp["code"];
    if (codigoError == -1) {
      var snackBar = SnackBar(
        content: Text(texto),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    final data = resp["content"];
    if (!mounted) return;
    setState(() {
      _cartera = data;

      /// GUARDAR EN LOCAL STORAGE
      _guardarDatos();
    });
    /*} else {
      _cartera = GetStorage().read('datosCartera');
    }*/
  }

  Future<void> _guardarDatos() async {
    // SharedPreferences pref = await SharedPreferences.getInstance();
    // //Map json = jsonDecode(jsonString);
    // String user = jsonEncode(_cartera);
    // pref.setString('datosCartera', user);
    storage.write('datosCartera', _cartera);
  }

  Map<String, dynamic>? findElementByCardCode(
      List<Map<String, dynamic>> list, String cardCode) {
    for (Map<String, dynamic> element in list) {
      if (element['cardCode'] == cardCode) {
        return element;
      }
    }
    return null;
  }

  Future<void> _fetchDataDetailCartera() async {
    String endpoint = '';
    if (GetStorage().read('nitFiltroCartera') == null) {
      endpoint =
          'http://wali.igbcolombia.com:8080/manager/res/app/detail-age-customer-portfolio/' +
              empresa +
              '?slpcode=' +
              codigo;
    } else {
      endpoint =
          'http://wali.igbcolombia.com:8080/manager/res/app/detail-age-customer-portfolio/' +
              empresa +
              '?slpcode=' +
              codigo +
              '&cardcode=' +
              GetStorage().read('nitFiltroCartera');
    }

    final response = await http.get(Uri.parse(endpoint));
    Map<String, dynamic> resp = jsonDecode(response.body);
    String texto = "No se encontraron datos de cartera para el usuario " +
        codigo +
        " y empresa " +
        empresa;

    final codigoError = resp["content"];
    if (codigoError == -1) {
      var snackBar = SnackBar(
        content: Text(texto),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    final data = resp["content"];

    if (!mounted) return;
    setState(
      () {
        List<Map<String, dynamic>> contentMapList =
            data.cast<Map<String, dynamic>>();
        detalleCartera = contentMapList;
      },
    );
  }

  Future<void> _launchPhone(String phone) async {
    final Uri telefonoUrl = Uri.parse('tel:$phone');

    if (await canLaunchUrl(telefonoUrl)) {
      await launchUrl(telefonoUrl);
    } else {
      throw Exception('No se pudo abrir la aplicación de teléfono.');
    }
  }

  Future<http.Response> _generateReport(
      String id, String document, String origen) async {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/report/generate-report';
    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          "id": id,
          "copias": 0,
          "documento": document,
          "companyName": empresa,
          "origen": origen,
          "imprimir": false
        },
      ),
    );
  }

  Future<void> _downloadReportPDF(
      String pdfUrl, String dateDoc, String document, String cardCode) async {
    final response = await http.get(Uri.parse(pdfUrl));

    if (response.statusCode == 200) {
      final Uint8List pdfBytes = response.bodyBytes;
      final directory = await Directory.systemTemp.createTemp();
      final pdfFile = File('/storage/emulated/0/Download/' +
          document +
          '-' +
          cardCode +
          '[' +
          dateDoc +
          '].pdf');
      await pdfFile.writeAsBytes(pdfBytes);
    } else {
      throw Exception('Error al descargar el documento');
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
            GetStorage().remove('nitFiltroCartera');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.download_outlined),
            onPressed: () async {
              DateTime now = DateTime.now();
              try {
                http.Response response = await _generateReport(
                    GetStorage().read('usuario'), "collection", "S");
                Map<String, dynamic> resultado = jsonDecode(response.body);

                if (response.statusCode == 200 && resultado['content'] != "") {
                  _downloadReportPDF(
                    'http://wali.igbcolombia.com:8080/shared/' +
                        GetStorage().read('empresa') +
                        '/collection/' +
                        GetStorage().read('usuario') +
                        '.pdf',
                    DateFormat("yyyyMMdd-hhmm").format(now),
                    "CarteraGeneral",
                    "",
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cartera general guardada en descargas'),
                      duration: Duration(seconds: 3),
                    ),
                  );
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
                      'Error al generar el reporte de cartera general',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
        title: ListTile(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegateCartera(),
            );
          },
          title: Text(
            'Buscar cartera',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              height: 80,
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: tituloCartera(context),
                  ),
                ],
              ),
            ),
            Container(
              child: Expanded(
                child: cartera(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget tituloCartera(BuildContext context) {
    int total = 0;
    detalleCartera.forEach((element) {
      total = element["total"];
    });

    String totalCartGen = numberFormat.format(total);
    if (totalCartGen.contains('.')) {
      int decimalIndex = totalCartGen.indexOf('.');
      totalCartGen = "\$" + totalCartGen.substring(0, decimalIndex);
    }

    return Card(
      child: Container(
        height: 50,
        color: Colors.white,
        child: ListTile(
          title: Center(
            child: Text(
              'Clientes: ' +
                  _cartera.length.toString() +
                  '  ' +
                  'Total: ' +
                  totalCartGen +
                  '\n',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget cartera(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        itemCount: _cartera.length,
        itemBuilder: (context, index) {
          Map<String, dynamic>? resultado = findElementByCardCode(
              detalleCartera, _cartera[index]["cardCode"].toString());
          String ageSinVencer = "0";
          String age0a30 = "0";
          String age30a60 = "0";
          String age61a90 = "0";
          String age91a120 = "0";
          String ageMas120 = "0";
          String totalCarteraS = "0";
          String cupo = "0";
          String phone = "0";
          String emailCL = "";

          if (resultado != null) {
            ageSinVencer = numberFormat.format(resultado["ageSinVencer"]);
            if (ageSinVencer.contains('.')) {
              int decimalIndex = ageSinVencer.indexOf('.');
              ageSinVencer = "\$" + ageSinVencer.substring(0, decimalIndex);
            }

            age0a30 = numberFormat.format(resultado["age0a30"]);
            if (age0a30.contains('.')) {
              int decimalIndex = age0a30.indexOf('.');
              age0a30 = "\$" + age0a30.substring(0, decimalIndex);
            }

            age30a60 = numberFormat.format(resultado["age30a60"]);
            if (age30a60.contains('.')) {
              int decimalIndex = age30a60.indexOf('.');
              age30a60 = "\$" + age30a60.substring(0, decimalIndex);
            }

            age61a90 = numberFormat.format(resultado["age61a90"]);
            if (age61a90.contains('.')) {
              int decimalIndex = age61a90.indexOf('.');
              age61a90 = "\$" + age61a90.substring(0, decimalIndex);
            }

            age91a120 = numberFormat.format(resultado["age91a120"]);
            if (age91a120.contains('.')) {
              int decimalIndex = age91a120.indexOf('.');
              age91a120 = "\$" + age91a120.substring(0, decimalIndex);
            }

            ageMas120 = numberFormat.format(resultado["ageMas120"]);
            if (ageMas120.contains('.')) {
              int decimalIndex = ageMas120.indexOf('.');
              ageMas120 = "\$" + ageMas120.substring(0, decimalIndex);
            }

            totalCarteraS = numberFormat.format(resultado["subTotal"]);
            if (totalCarteraS.contains('.')) {
              int decimalIndex = totalCarteraS.indexOf('.');
              totalCarteraS = "\$" + totalCarteraS.substring(0, decimalIndex);
            }

            cupo = numberFormat.format(_cartera[index]["cupo"]);
            if (cupo.contains('.')) {
              int decimalIndex = cupo.indexOf('.');
              cupo = "\$" + cupo.substring(0, decimalIndex);
            }

            phone = resultado["phone"].toString();
            emailCL = resultado["email"].toString();
          }

          return Card(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            height: 1.5,
                          ),
                          children: empresa == "REDPLAS"
                              ? [
                                  TextSpan(
                                    text:
                                        _cartera[index]["cardCode"].toString() +
                                            '\n',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        _cartera[index]["cardName"].toString() +
                                            '\n',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _cartera[index]["payCondition"]
                                            .toString() +
                                        '  -  Cupo Disponible: ' +
                                        cupo.toString() +
                                        '\n\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sin vencer    ' +
                                        ageSinVencer.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '1 - 30 días  ' +
                                        age0a30.toString() +
                                        '  \n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '31 - 45 días    ' +
                                        age30a60.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '46 - 60 días    ' +
                                        age61a90.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '61 - 90 días    ' +
                                        age91a120.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '+ 90 días    ' +
                                        ageMas120.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: 'Total: ' + totalCarteraS,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ]
                              : [
                                  TextSpan(
                                    text:
                                        _cartera[index]["cardCode"].toString() +
                                            '\n',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        _cartera[index]["cardName"].toString() +
                                            '\n',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _cartera[index]["payCondition"]
                                            .toString() +
                                        '  -  Cupo Disponible: ' +
                                        cupo.toString() +
                                        '\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Tel: ' + phone + '\n\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sin vencer    ' +
                                        ageSinVencer.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '1 - 30 días  ' +
                                        age0a30.toString() +
                                        '  \n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '31 - 60 días    ' +
                                        age30a60.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '61 - 90 días    ' +
                                        age61a90.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '91 - 120 días    ' +
                                        age91a120.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '+ 120 días    ' +
                                        ageMas120.toString() +
                                        '\n',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: 'Total: ' + totalCarteraS,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.phone_outlined),
                        onPressed: () {
                          _launchPhone(phone);
                        },
                      ),
                      Container(
                        child: Text(_cartera[index]["totalDoc"].toString()),
                      ),
                      IconButton(
                        icon: Icon(Icons.wallet_outlined),
                        onPressed: () {
                          //Vaciar valores del descuento ingresado
                          for (var detail in _cartera[index]
                              ["detailPortfolio"]) {
                            detail["discApplied"] = "0";
                          }

                          storage.write('clienteDetalle', _cartera[index]);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarteraDetalle(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.mail_outline),
                        onPressed: () async {
                          DateTime now = DateTime.now();
                          try {
                            http.Response response = await _generateReport(
                                _cartera[index]["cardCode"].toString(),
                                "accountSetting",
                                "S");
                            Map<String, dynamic> resultado =
                                jsonDecode(response.body);

                            if (response.statusCode == 200 &&
                                resultado['content'] != "") {
                              _downloadReportPDF(
                                'http://wali.igbcolombia.com:8080/shared/' +
                                    GetStorage().read('empresa') +
                                    '/accountSetting/' +
                                    _cartera[index]["cardCode"].toString() +
                                    '.pdf',
                                DateFormat("yyyyMMdd-hhmm").format(now),
                                "EstadoCuenta",
                                _cartera[index]["cardCode"].toString(),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Estado de cuenta guardada en descargas',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
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
                                  'Error al generar el reporte de estado de cuenta',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }

                          final Email email = Email(
                            subject: "Edad de Cartera Cliente: " +
                                _cartera[index]["cardCode"].toString(),
                            body: _cartera[index]["cardName"].toString() +
                                "\n\nSin Vencer: " +
                                ageSinVencer.toString() +
                                "\n1 a 3 0 días: " +
                                age0a30.toString() +
                                "\n30 a 60 días: " +
                                age30a60.toString() +
                                "\n61 a 90 días: " +
                                age61a90.toString() +
                                "\n91 a 120 días: " +
                                age91a120.toString() +
                                "\nMás 120 días: " +
                                ageMas120.toString() +
                                "\nTotal: " +
                                totalCarteraS.toString() +
                                "\nCupo Disponible: " +
                                cupo.toString(),
                            recipients: [emailCL],
                            attachmentPaths: [
                              '/storage/emulated/0/Download/EstadoCuenta-' +
                                  _cartera[index]["cardCode"].toString() +
                                  '[' +
                                  DateFormat("yyyyMMdd-hhmm").format(now) +
                                  '].pdf'
                            ],
                          );
                          try {
                            await FlutterEmailSender.send(email);
                          } catch (error) {
                            /*print('Error al enviar el correo: $error');*/
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  showAlertDialog(BuildContext context, String nit) {
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
          MaterialPageRoute(builder: (context) => const PedidosPage()),
        );
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text(
        "Tiene ítmes pendientes para otro cliente, si continúa se borrarán e inciará un pedido nuevo, desea continuar?",
      ),
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
}

Future<http.Response> _generateReportDiscount(
    List<Map<String, dynamic>> detailCartera,
    String cardCode,
    String cardName) {
  final String url =
      'http://wali.igbcolombia.com:8080/apiRest/wali/reports/financial-discounts?schema=' +
          GetStorage().read('empresa');

  List<Map<String, dynamic>> dataList = [];
  for (var data in detailCartera) {
    String valorDescTxt = NumberFormat('#,##0.00', 'en_Us')
        .format(data["totalBruto"] * int.parse(data["discApplied"]) / 100)
        .toString();
    if (valorDescTxt.contains('.')) {
      int decimalIndex = valorDescTxt.indexOf('.');
      valorDescTxt = "\$" + valorDescTxt.substring(0, decimalIndex);
    }

    String valorPagoTxt = NumberFormat('#,##0.00', 'en_Us')
        .format(data["docTotal"] -
            (data["totalBruto"] * int.parse(data["discApplied"]) / 100))
        .toString();
    if (valorPagoTxt.contains('.')) {
      int decimalIndex = valorPagoTxt.indexOf('.');
      valorPagoTxt = "\$" + valorPagoTxt.substring(0, decimalIndex);
    }

    String valorDocTxt =
        NumberFormat('#,##0.00', 'en_Us').format(data["docTotal"]).toString();
    if (valorDocTxt.contains('.')) {
      int decimalIndex = valorDocTxt.indexOf('.');
      valorDocTxt = "\$" + valorDocTxt.substring(0, decimalIndex);
    }

    Map<String, dynamic> detail = {
      "NombreCliente": cardName,
      "Nit": cardCode,
      "Telefono": "",
      "Direccion": "",
      "Tipo": "Factura",
      "NoDoc": data["docNum"].toString(),
      "FDoc": data["docDate"],
      "FVen": data["docDueDate"],
      "Dias": data["expiredDays"].toString(),
      "ValorDoc": valorDocTxt,
      "ValorPago": valorPagoTxt,
      "ValorDesc": valorDescTxt,
      "companyName": GetStorage().read('empresa') == "IGB"
          ? "1"
          : GetStorage().read('empresa') == "VARROC"
              ? "2"
              : "3",
      "Disc": data["discApplied"].toString()
    };
    dataList.add(detail);
  }

  return http.post(
    Uri.parse(url),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: jsonEncode(dataList),
  );
}

class CarteraDetalle extends StatefulWidget {
  const CarteraDetalle({Key? key}) : super(key: key);
  @override
  State<CarteraDetalle> createState() => CarteraDetalleState();
}

class CarteraDetalleState extends State<CarteraDetalle> {
  Map<String, dynamic> clienteDetalle = {};
  bool generateDiscountReport = false;

  @override
  Widget build(BuildContext context) {
    clienteDetalle = GetStorage().read('clienteDetalle');

    for (var detalle in clienteDetalle["detailPortfolio"]) {
      if (detalle["activeCalc"] == "Y") {
        generateDiscountReport = true;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        /*actions: [
          CarritoPedido(),
        ],*/
        actions: [
          if (generateDiscountReport)
            IconButton(
              color: Colors.white,
              icon: Icon(Icons.calculate_rounded),
              onPressed: () async {
                List<Map<String, dynamic>> detailCartera = [];
                for (var detail in clienteDetalle["detailPortfolio"]) {
                  detailCartera.add(detail);
                }

                try {
                  http.Response response = await _generateReportDiscount(
                    detailCartera,
                    clienteDetalle["cardCode"].toString(),
                    clienteDetalle["cardName"].toString(),
                  );

                  Map<String, dynamic> resultado = jsonDecode(response.body);

                  if (response.statusCode == 200 &&
                      resultado['content'] != "") {
                    //Vaciar valores del descuento ingresado
                    for (var detail in clienteDetalle["detailPortfolio"]) {
                      detail["discApplied"] = "0";
                    }
                    final Uri url = Uri.parse(resultado['content'].toString());
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      launchUrl(url);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No se pudo generar el reporte, error de red, verifique conectividad por favor',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al generar el reporte de cartera general',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
        ],
        title: Text(
          'Detalle de cartera',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              height: 80,
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: tituloDetalle(context),
                  ),
                ],
              ),
            ),
            Container(
              child: Expanded(
                child: carteraDetalle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tituloDetalle(BuildContext context) {
    Map<String, dynamic> clienteDetalle = GetStorage().read('clienteDetalle');
    return Card(
      child: Container(
        height: 100,
        color: Colors.white,
        child: ListTile(
          title: Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: clienteDetalle["cardName"].toString() + '\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: clienteDetalle["cardCode"].toString() + '\n',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget carteraDetalle(BuildContext context) {
    Map<String, dynamic> clienteDetalle = GetStorage().read('clienteDetalle');
    var numberFormat = new NumberFormat('#,##0.00', 'en_Us');
    List detallPortafolio = clienteDetalle["detailPortfolio"];

    return SafeArea(
      child: ListView.builder(
        itemCount: detallPortafolio.length,
        itemBuilder: (context, index) {
          bool showButtonCalculator =
              clienteDetalle["detailPortfolio"][index]["activeCalc"] == 'Y'
                  ? true
                  : false;
          String saldo = numberFormat
              .format(clienteDetalle["detailPortfolio"][index]["balance"]);
          if (saldo.contains('.')) {
            int decimalIndex = saldo.indexOf('.');
            saldo = "\$" + saldo.substring(0, decimalIndex);
          }
          String valor = numberFormat
              .format(clienteDetalle["detailPortfolio"][index]["docTotal"]);
          if (valor.contains('.')) {
            int decimalIndex = valor.indexOf('.');
            valor = "\$" + valor.substring(0, decimalIndex);
          }
          return Card(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Align(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: ListTile(
                        title: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '\nTipo de documento: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: clienteDetalle["detailPortfolio"][index]
                                            ["docType"]
                                        .toString() +
                                    '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Nro de documento: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: clienteDetalle["detailPortfolio"][index]
                                            ["docNum"]
                                        .toString() +
                                    '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Creado: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: clienteDetalle["detailPortfolio"][index]
                                            ["docDate"]
                                        .toString() +
                                    '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Vencimiento: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: clienteDetalle["detailPortfolio"][index]
                                            ["docDueDate"]
                                        .toString() +
                                    '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Saldo Pendiente: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: saldo + '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Valor Factura: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: valor + '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Días vencidos: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: clienteDetalle["detailPortfolio"][index]
                                            ["expiredDays"]
                                        .toString() +
                                    '\n',
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: 'Comentario: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              TextSpan(
                                text: clienteDetalle["detailPortfolio"][index]
                                        ["comment"]
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        showButtonCalculator
                            ? Container(
                                width: 245,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        keyboardType: TextInputType.number,
                                        maxLength: 3,
                                        decoration: InputDecoration(
                                          border: UnderlineInputBorder(),
                                          labelText: 'Ingrese % descuento',
                                          labelStyle: TextStyle(fontSize: 13),
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                        ),
                                        onChanged: (value) {
                                          clienteDetalle["detailPortfolio"]
                                              [index]["discApplied"] = value;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.calculate_rounded),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) {
                                            return CalculatorDialogWidget(
                                              totalBruto: clienteDetalle[
                                                          "detailPortfolio"]
                                                      [index]["totalBruto"]
                                                  .toDouble(),
                                              docTotal: clienteDetalle[
                                                          "detailPortfolio"]
                                                      [index]["docTotal"]
                                                  .toDouble(),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                        IconButton(
                          icon: Icon(Icons.picture_as_pdf_outlined),
                          onPressed: () {
                            final Uri url = Uri.parse(
                              clienteDetalle["detailPortfolio"][index]["urlFE"]
                                  .toString(),
                            );
                            launchUrl(url);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.mail_outline),
                          onPressed: () async {
                            final Email email = Email(
                              subject: "Detalle de cartera " +
                                  clienteDetalle["detailPortfolio"][index]
                                      ["docType"] +
                                  " #" +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["docNum"]
                                      .toString(),
                              body: "Tipo de documento: " +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["docType"]
                                      .toString() +
                                  '\nNro de documento: ' +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["docNum"]
                                      .toString() +
                                  '\nFecha de creación: ' +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["docDate"]
                                      .toString() +
                                  '\nFecha de vencimiento: ' +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["docDueDate"]
                                      .toString() +
                                  '\nSaldo pendiente: ' +
                                  saldo +
                                  '\nValor factura: ' +
                                  valor +
                                  '\nDías vencidos: ' +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["expiredDays"]
                                      .toString() +
                                  "\n\nFactura electrónica:\n\nPara visualizar el documento por favor copie la siguiente url en su navegador favorito:\n\n" +
                                  clienteDetalle["detailPortfolio"][index]
                                          ["urlFE"]
                                      .toString(),
                              recipients: [
                                clienteDetalle["emailFE"].toString()
                              ],
                            );
                            try {
                              await FlutterEmailSender.send(email);
                            } catch (error) {
                              /*print('Error al enviar el correo: $error');*/
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CalculatorDialogWidget extends StatefulWidget {
  final double totalBruto;
  final double docTotal;
  CalculatorDialogWidget({required this.totalBruto, required this.docTotal});
  @override
  CalculatorDialogState createState() => new CalculatorDialogState();
}

class CalculatorDialogState extends State<CalculatorDialogWidget> {
  String discount = "";
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    Widget buttons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          child: Icon(
            Icons.close_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          child: Icon(
            Icons.point_of_sale_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            setState(
              () {
                String totalBruto = NumberFormat('#,##0.00', 'en_Us').format(
                    widget.docTotal -
                        (widget.totalBruto * (double.parse(discount) / 100)));

                if (totalBruto.contains('.')) {
                  int decimalIndex = totalBruto.indexOf('.');
                  totalBruto = "\$" + totalBruto.substring(0, decimalIndex);
                }
                discount = totalBruto;
              },
            );
          },
        ),
      ],
    );

    return AlertDialog(
      title: Text(
        "Calcular descuento financiero",
        style: TextStyle(fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            keyboardType: TextInputType.number,
            maxLength: 3,
            decoration: InputDecoration(
              labelText: "Ingrese % descuento",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              discount = value;
            },
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
            decoration: InputDecoration(
              labelText: discount.toString(),
              border: OutlineInputBorder(),
            ),
            enabled: false,
          )
        ],
      ),
      actions: [
        buttons,
      ],
    );
  }
}
