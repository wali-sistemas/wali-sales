import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/icomoon.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({Key? key}) : super(key: key);

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
                onPressed: () {},
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
                      return EmployeeDataDialog();
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
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<http.Response> _generateReportPaystub() {
  final String url =
      'http://wali.igbcolombia.com:8080/apiRest/wali/reports/paystub?schema=WALI_NOVAWEB';
  /* + GetStorage().read('empresa');*/

  Map<String, dynamic> data = {
    "id": 1035866418,
    "year": 2024,
    "month": 8,
    "day": 15,
    "logo": GetStorage().read('empresa') == "IGB"
        ? "7"
        : GetStorage().read('empresa') == "VARROC"
            ? "5"
            : "6",
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

class EmployeeDataDialog extends StatefulWidget {
  @override
  _EmployeeDataDialogState createState() => new _EmployeeDataDialogState();
}

class _EmployeeDataDialogState extends State<EmployeeDataDialog> {
  final TextEditingController documentoController = TextEditingController();
  String? periodoSeleccionado;
  String? mesSeleccionado;

  final List<String> periodos = ['15', '30'];
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
      title: const Text(
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
            DropdownButtonFormField<String>(
              value: periodoSeleccionado,
              decoration:
                  const InputDecoration(labelText: 'Seleccionar periodo'),
              items: periodos.map(
                (dia) {
                  return DropdownMenuItem(
                    value: dia,
                    child: Text(dia),
                  );
                },
              ).toList(),
              onChanged: (valor) {
                periodoSeleccionado = valor;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: mesSeleccionado,
              decoration: const InputDecoration(labelText: 'Seleccionar mes'),
              items: meses.map(
                (mes) {
                  return DropdownMenuItem(value: mes, child: Text(mes));
                },
              ).toList(),
              onChanged: (valor) {
                mesSeleccionado = valor;
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: documentoController,
              decoration: const InputDecoration(
                labelText: 'Ingrese documento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      /*actions: [
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
                const SnackBar(
                  content: Text('Por favor, asegúrese de llenar todos los campos.'),
                ),
              );
              return;
            }

            print("**********************");
            print(periodo);
            print(mes);
            print(documento);
            print("**********************");



            /*try {
              http.Response response = await _generateReportPaystub();
              Map<String, dynamic> resultado = jsonDecode(response.body);

              if (response.statusCode == 200 && resultado['content'] != "") {
                final Uri url = Uri.parse(
                  "http://wali.igbcolombia.com:8080/shared/WALI/employee/paystub/1035866418.pdf",
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
            }*/
          },
          child: Icon(
            Icomoon.pdf,
            color: Colors.black,
            size: 30,
          ),
        ),
      ],*/
    );
  }
}
