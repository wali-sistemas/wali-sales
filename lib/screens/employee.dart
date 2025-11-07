import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/icomoon.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EmployeePage extends StatefulWidget {
  EmployeePage({Key? key}) : super(key: key);

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
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
        actions: [
          CarritoPedido(),
        ],
        title: Text(
          'Empleado',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 50),
                            Icon(
                              Icomoon.carta,
                              color: Colors.white,
                              size: 100,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Carta Laboral",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return JobCertifyEmployeeDataDialog();
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 50),
                            Icon(
                              Icomoon.custody,
                              color: Colors.white,
                              size: 100,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Colillas de Pago",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return PaystubEmployeeDataDialog();
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 50),
                            Icon(
                              Icomoon.fondo,
                              color: Colors.white,
                              size: 100,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Estado femprobien",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AccountStatementEmployeeDataDialog();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<http.Response> _generateReportPaystub(
    String id, String month, String day) {
  String companyName = '';
  String idLogo = '';

  switch (GetStorage().read('empresa')) {
    case "IGB":
      companyName = "IGB_NOVAWEB";
      idLogo = "7";
      break;
    case "VARROC":
      companyName = "MTZ_NOVAWEB";
      idLogo = "5";
      break;
    case "REDPLAS":
      companyName = 'VILNA_NOVAWEB';
      idLogo = "6";
      break;
  }

  final String url =
      'http://wali.igbcolombia.com:8080/apiRest/wali/reports/paystub?schema=' +
          companyName;

  Map<String, dynamic> data = {
    "id": int.parse(id),
    "year": DateTime.now().year,
    "month": int.parse(month),
    "day": int.parse(day),
    "logo": idLogo.toString(),
  };

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Warehouse-Code': '',
    'Authorization': '',
    'X-Employee': '',
    'X-Pruebas': '',
  };

  return http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(data),
  );
}

Future<http.Response> _generateReportJobCertify(String id, String sendto) {
  String companyName = '';

  switch (GetStorage().read('empresa')) {
    case "IGB":
      companyName = "IGB_NOVAWEB";
      break;
    case "VARROC":
      companyName = "MTZ_NOVAWEB";
      break;
    case "REDPLAS":
      companyName = 'VILNA_NOVAWEB';
      break;
  }

  final String url =
      'http://wali.igbcolombia.com:8080/apiRest/wali/reports/job-certify?schema=' +
          companyName;

  Map<String, dynamic> data = {
    "id": int.parse(id),
    "year": DateTime.now().year,
    "month": DateTime.now().month - 1,
    "day": 15,
    "sendto": sendto.isEmpty ? "A QUIEN PUEDA INTERESAR" : sendto
  };

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Warehouse-Code': '',
    'Authorization': '',
    'X-Employee': '',
    'X-Pruebas': '',
  };

  return http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(data),
  );
}

Future<http.Response> _generateReportAccountStatement(String id) {
  final String url =
      'http://wali.igbcolombia.com:8080/manager/res/report/generate-report';

  Map<String, dynamic> data = {
    "id": id,
    "copias": 1,
    "documento": "accountStatement",
    "companyName": "FEMPROBN_NOVAWEB",
    "origen": "N",
    "filtro": "",
    "filtroSec": "",
    "imprimir": false
  };

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Warehouse-Code': '',
    'Authorization': '',
    'X-Employee': '',
    'X-Pruebas': '',
  };

  return http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(data),
  );
}

class JobCertifyEmployeeDataDialog extends StatefulWidget {
  @override
  _JobCertifyEmployeeDataDialogState createState() =>
      new _JobCertifyEmployeeDataDialogState();
}

class _JobCertifyEmployeeDataDialogState
    extends State<JobCertifyEmployeeDataDialog> {
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController sendtoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'Datos del empleado',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: documentoController,
              decoration: InputDecoration(
                labelText: 'Ingrese documento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: sendtoController,
              decoration: InputDecoration(
                labelText: 'Dirigido a',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          ),
          onPressed: () async {
            if (documentoController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Por favor, asegúrese de llenar todos los campos.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            try {
              http.Response response = await _generateReportJobCertify(
                  documentoController.text, sendtoController.text);
              Map<String, dynamic> resultado = jsonDecode(response.body);

              if (response.statusCode == 200 && resultado['content'] != "") {
                String companyName = '';
                switch (GetStorage().read('empresa')) {
                  case "VARROC":
                    companyName = "MTZ";
                    break;
                  default:
                    companyName = GetStorage().read('empresa');
                }

                final Uri url = Uri.parse(
                  "https://drive.google.com/viewerng/viewer?embedded=true&url=http://wali.igbcolombia.com:8080/shared/" +
                      companyName +
                      "/employee/jobcertify/" +
                      documentoController.text +
                      ".pdf",
                );

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  launchUrl(url);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No se pudo generar la carta laboral, error de red, verifique conectividad por favor.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al generar la carta laboral.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: Icon(
            Icomoon.pdf,
            color: Colors.black,
            size: 40,
          ),
        ),
      ],
    );
  }
}

class PaystubEmployeeDataDialog extends StatefulWidget {
  @override
  _PaystubEmployeeDataDialogState createState() =>
      new _PaystubEmployeeDataDialogState();
}

class _PaystubEmployeeDataDialogState extends State<PaystubEmployeeDataDialog> {
  final TextEditingController documentoController = TextEditingController();
  String? periodoSeleccionado;
  String? mesSeleccionado;

  List<String> periodos = [];
  final List<String> meses = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'Datos del empleado',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: documentoController,
              decoration: InputDecoration(
                labelText: 'Ingrese documento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: mesSeleccionado,
              decoration: InputDecoration(labelText: 'Seleccionar mes'),
              items: meses
                  .map((mes) => DropdownMenuItem(value: mes, child: Text(mes)))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  mesSeleccionado = valor;
                  if (['2', '4', '6', '9', '11'].contains(mesSeleccionado)) {
                    periodos = ['15', '30'];
                  } else {
                    periodos = ['15', '31'];
                  }
                  periodoSeleccionado = null;
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: periodoSeleccionado,
              decoration: InputDecoration(labelText: 'Seleccionar periodo'),
              items: periodos
                  .map((dia) => DropdownMenuItem(value: dia, child: Text(dia)))
                  .toList(),
              onChanged: (valor) => periodoSeleccionado = valor,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          ),
          onPressed: () async {
            final String periodo = periodoSeleccionado ?? '';
            final String mes = mesSeleccionado ?? '';
            final String documento = documentoController.text;

            if (periodo.isEmpty || mes.isEmpty || documento.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Por favor, asegúrese de llenar todos los campos.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            try {
              http.Response response =
                  await _generateReportPaystub(documento, mes, periodo);
              Map<String, dynamic> resultado = jsonDecode(response.body);

              if (response.statusCode == 200 && resultado['content'] != "") {
                String companyName = '';
                switch (GetStorage().read('empresa')) {
                  case "VARROC":
                    companyName = "MTZ";
                    break;
                  default:
                    companyName = GetStorage().read('empresa');
                }

                final Uri url = Uri.parse(
                  "https://drive.google.com/viewerng/viewer?embedded=true&url=http://wali.igbcolombia.com:8080/shared/" +
                      companyName +
                      "/employee/paystub/" +
                      documento +
                      ".pdf",
                );

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  launchUrl(url);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No se pudo generar la collila, error de red, verifique conectividad por favor.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al generar la colilla de pago.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: Icon(
            Icomoon.pdf,
            color: Colors.black,
            size: 40,
          ),
        ),
      ],
    );
  }
}

class AccountStatementEmployeeDataDialog extends StatefulWidget {
  @override
  _AccountStatementEmployeeDataDialogState createState() =>
      new _AccountStatementEmployeeDataDialogState();
}

class _AccountStatementEmployeeDataDialogState
    extends State<AccountStatementEmployeeDataDialog> {
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController sendtoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'Datos del empleado',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: documentoController,
              decoration: InputDecoration(
                labelText: 'Ingrese documento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          ),
          onPressed: () async {
            if (documentoController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Por favor, asegúrese de llenar el campo.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            try {
              http.Response response = await _generateReportAccountStatement(
                  documentoController.text);
              Map<String, dynamic> resultado = jsonDecode(response.body);

              if (response.statusCode == 200 && resultado['content'] != "") {
                final Uri url = Uri.parse(
                  "https://drive.google.com/viewerng/viewer?embedded=true&url=http://wali.igbcolombia.com:8080/shared/FEMPROBN_NOVAWEB/accountStatement/" +
                      documentoController.text +
                      ".pdf",
                );

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  launchUrl(url);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No se pudo generar el estado de cuenta, error de red, verifique conectividad por favor.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al generar el estado de cuenta.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: Icon(
            Icomoon.pdf,
            color: Colors.black,
            size: 40,
          ),
        ),
      ],
    );
  }
}
