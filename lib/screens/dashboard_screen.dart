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
  Timer? _timer;

  final dataMap = <String, double>{
    'Ventas': 0,
    'Presupuesto': 0,
    'Pend. por facturar': 0,
  };

  final colorList = <Color>[
    Color.fromRGBO(242, 83, 75, 1),
    Color.fromRGBO(51, 51, 51, 1),
    Color.fromRGBO(201, 204, 209, 1),
    Color(0xffe17055),
    Color(0xff6c5ce7),
  ];

  final GetStorage storage = GetStorage();
  final String? usuario = GetStorage().read('usuario');
  final String? empresa = GetStorage().read('empresa');
  final DateTime now = DateTime.now();
  int presupuestoT = 0;
  double presupuestoP = 0;
  double ventasT = 0;
  int base = 0;
  int impacto = 0;
  double efectividad = 0;
  int nroOrderSaved = 0;
  double valorOrderSaved = 0;

  final NumberFormat numberFormat = NumberFormat('#,##0.00', 'en_Us');

  late final Future<Map<String, dynamic>> _dashboardFuture;
  late final Future<Map<String, dynamic>> _barrasFuture;
  late final Future<Map<String, dynamic>> _savedOrdersFuture;
  late final Future<dynamic> _budgetByBrandFuture;

  @override
  void initState() {
    super.initState();

    _dashboardFuture = _datosDashboard2();
    _barrasFuture = _datosBarras();
    _savedOrdersFuture = _getSavedOrdersReport();
    _budgetByBrandFuture = _findSalesBudgetByBrandAndSeller();

    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => sendNotification(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> sendNotification() async {
    final response = await _findOrderExtranetInprogress();

    if (!mounted) return;

    if (response != null) {
      showNotification(response);
      // actualiza el estado de la orden 'NOTIFICADO APP'
      await _updateStatusNotificationOrderExtranet(response['docNum']);
    }
  }

  Future<Map<String, dynamic>> _datosDashboard2() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/budget-sales/$empresa?slpcode=$usuario&year=${now.year}&month=${now.month}';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (!resp['content'].toString().contains('Ocurrio un error')) {
      return resp;
    }

    return {
      'code': 0,
      'content': [
        {
          'year': now.year,
          'slpCode': usuario,
          'companyName': empresa,
          'month': now.month.toString(),
          'ventas': 0.0,
          'presupuesto': 0,
          'pendiente': 0.0,
          'whsDefTire': '01'
        }
      ]
    };
  }

  Future<Map<String, dynamic>> _datosBarras() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/effectiveness-sales/$empresa?slpcode=$usuario&year=${now.year}&month=${now.month}';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp1 = jsonDecode(response.body);

    final String contentStr = resp1['content'].toString();
    final bool ok = !contentStr.contains('Ocurrio un error') &&
        !contentStr.contains('No se encontraron');

    if (ok) {
      return resp1;
    }

    return {
      'code': 0,
      'content': {
        'slpCode': usuario ?? '',
        'slpName': '',
        'year': now.year,
        'month': now.month,
        'base': 0,
        'impact': 0,
        'effectiveness': 0
      }
    };
  }

  Future<Map<String, dynamic>> _getSavedOrdersReport() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/report-saved-order/$empresa?slpcode=$usuario';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp['code'] == 0) {
      return {
        'code': 0,
        'content': [
          {
            'nroOrder': resp['content'][0],
            'valorOrder': resp['content'][1],
          }
        ]
      };
    }

    return resp;
  }

  Future<dynamic> _findOrderExtranetInprogress() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/find-order-extranet-inprogress/$empresa/$usuario';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp['code'] == 0) return resp['content'];
    return null;
  }

  Future<void> _updateStatusNotificationOrderExtranet(String docNum) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/update-status-order-extranet/$empresa/$docNum';

    final response = await http.put(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp['code'] == 0) {
      resp['content'];
    }
  }

  Future<dynamic> _findSalesBudgetByBrandAndSeller() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-budget-brand/$empresa?slpcode=$usuario';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp['code'] == 0) return resp['content'];
    return null;
  }

  void showAlertDialog(BuildContext context) {
    final Widget cancelButton = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('NO'),
    );

    final Widget continueButton = ElevatedButton(
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
      child: const Text('SI'),
    );

    final AlertDialog alert = AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.error, color: Colors.orange),
          SizedBox(width: 8),
          Text('Atención!'),
        ],
      ),
      content: const Text('¿Está seguro que desea salir de la aplicación?'),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
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
          rodStackItems: const [],
        ),
      ],
    ).copyWith(
      barRods: [
        BarChartRodData(
          toY: 100,
          width: 40,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, 0, Color.fromRGBO(15, 178, 242, 1))
                .copyWith(toY: x1),
            BarChartRodStackItem(
              x1,
              x1 + x2,
              const Color.fromRGBO(207, 240, 252, 1),
            ),
          ],
        ),
      ],
    );
  }

  String _monthName(int m) {
    switch (m) {
      case 1:
        return 'Enero';
      case 2:
        return 'Febrero';
      case 3:
        return 'Marzo';
      case 4:
        return 'Abril';
      case 5:
        return 'Mayo';
      case 6:
        return 'Junio';
      case 7:
        return 'Julio';
      case 8:
        return 'Agosto';
      case 9:
        return 'Septiembre';
      case 10:
        return 'Octubre';
      case 11:
        return 'Noviembre';
      case 12:
        return 'Diciembre';
      default:
        return 'Sin Definir';
    }
  }

  String _convertMoney(dynamic v) {
    String t = numberFormat.format(v);
    final p = t.indexOf('.');
    if (p != -1) t = t.substring(0, p);
    return '\$$t';
  }

  @override
  Widget build(BuildContext context) {
    final String monthName = _monthName(now.month);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onTap: () => showAlertDialog(context),
        ),
        actions: const [
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    double ventasPendientes = 0.0;
                    double presupuestoPendiente = 0.0;

                    ventasT = snapshot.data!['content'][0]['ventas'];
                    presupuestoT = snapshot.data!['content'][0]['presupuesto'];
                    presupuestoP = snapshot.data!['content'][0]['pendiente'];

                    storage.write('nombreAsesor',
                        snapshot.data!['content'][0]['slpName']);
                    storage.write(
                        'emailAsesor', snapshot.data!['content'][0]['mail']);
                    storage.write(
                        'zona', snapshot.data!['content'][0]['whsDefTire']);
                    storage.write('urlFoto',
                        snapshot.data!['content'][0]['urlSlpPicture']);

                    if (presupuestoT == 0 || presupuestoT.isNaN) {
                      dataMap['Ventas'] = 0;
                      dataMap['Presupuesto'] = 0;
                      dataMap['Pend. por facturar'] = 0;
                    } else {
                      ventasPendientes = (ventasT / presupuestoT) * 100;
                      ventasPendientes =
                          double.parse(ventasPendientes.toStringAsFixed(2));

                      presupuestoPendiente =
                          (presupuestoP / presupuestoT) * 100;
                      presupuestoPendiente =
                          double.parse(presupuestoPendiente.toStringAsFixed(2));

                      dataMap['Ventas'] = ventasT;
                      dataMap['Presupuesto'] =
                          presupuestoT.toDouble() - ventasT;
                      dataMap['Pend. por facturar'] = presupuestoP.toDouble();
                    }

                    final String presupuestoTstr = _convertMoney(presupuestoT);
                    final String ventastStr = _convertMoney(ventasT);
                    final String presupuestoPstr = _convertMoney(presupuestoP);

                    return Column(
                      children: [
                        const SizedBox(height: 5),
                        const Text(
                          'Presupuesto de ventas',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          monthName + ' - ' + now.year.toString(),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          presupuestoTstr,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        '%$ventasPendientes',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Ventas',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        '%$presupuestoPendiente',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Pendiente por facturar',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        pc.PieChart(
                          dataMap: dataMap,
                          chartType: pc.ChartType.ring,
                          baseChartColor: Colors.grey[50]!.withOpacity(0.15),
                          colorList: colorList,
                          chartValuesOptions: const pc.ChartValuesOptions(
                            showChartValues: false,
                            showChartValuesInPercentage: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        ventastStr,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Ventas',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        presupuestoPstr,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Pendiente por facturar',
                                        style: TextStyle(fontSize: 12),
                                      ),
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
                    return const Text(
                      'Error al tratar de realizar la consulta',
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            const Divider(),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Efectividad de clientes',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    '%$efectividad',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _barrasFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!["content"]
                            .toString()
                            .contains("Ocurrio un error") ||
                        snapshot.data!["content"] ==
                            "No se encontraron datos para graficar la efectividad.") {
                    } else {
                      base = (snapshot.data!["content"]["base"] as num).toInt();
                      impacto =
                          (snapshot.data!["content"]["impact"] as num).toInt();
                      efectividad =
                          (snapshot.data!["content"]["effectiveness"] as num)
                              .toDouble();
                      if (base <= 0 || impacto <= 0 || efectividad <= 0) {
                        return const Text(
                          'En el momento no tiene asignación de efectividad',
                          textAlign: TextAlign.center,
                        );
                      }
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  BarraGrafica(
                                    color: const Color.fromRGBO(0, 55, 114, 1),
                                    valor: base.toDouble(),
                                    etiqueta: base.toString(),
                                  ),
                                  const SizedBox(width: 10),
                                  BarraGrafica(
                                    color: const Color.fromRGBO(51, 51, 51, 1),
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
                          children: const [
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
                    return const Text(
                      'En el momento no tiene asignación de efectividad',
                      textAlign: TextAlign.center,
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 5),
            const Center(
              child: Text(
                'Ordenes guardadas',
                style: TextStyle(fontSize: 20),
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _savedOrdersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  String valorOrderSavedStr = '\$0';
                  if (snapshot.data!['code'] == 0) {
                    nroOrderSaved = snapshot.data!['content'][0]['nroOrder'];
                    valorOrderSaved =
                        snapshot.data!['content'][0]['valorOrder'];
                    valorOrderSavedStr = _convertMoney(valorOrderSaved);
                  }
                  return Center(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$nroOrderSaved',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const Text('#', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                valorOrderSavedStr,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Text('Error al tratar de realizar la consulta');
                }
                return const CircularProgressIndicator();
              },
            ),
            const Divider(),
            const SizedBox(height: 5),
            const Center(
              child: Text(
                'Presupuesto por marcas',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                EtiquetaBullet(
                  color: Color.fromRGBO(15, 178, 242, 1),
                  texto: 'Facturado',
                ),
                SizedBox(width: 20),
                EtiquetaBullet(
                  color: Color.fromRGBO(207, 240, 252, 1),
                  texto: 'Presupuesto',
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (empresa == 'IGB' || empresa == 'VARROC')
              FutureBuilder<dynamic>(
                future: _budgetByBrandFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data;
                    if (data == null) {
                      return const Text(
                        'En el momento no tiene presupuesto de marca asignado',
                        textAlign: TextAlign.center,
                      );
                    }

                    final int count = (empresa == 'IGB') ? 8 : 7;

                    return Container(
                      height: 500,
                      padding: const EdgeInsets.all(15),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barGroups: List.generate(
                              count,
                              (i) => makeGroupData(
                                i,
                                (data[i]['percent'] as num).toDouble(),
                                100,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 150,
                                  getTitlesWidget: (value, meta) {
                                    final int i = value.toInt();
                                    if (i < 0 || i >= count) {
                                      return const SizedBox.shrink();
                                    }
                                    return RotatedBox(
                                      quarterTurns: -1,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            data[i]['result'].toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.blueGrey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            data[i]['brand'].toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            data[i]['percent'].toString() + '%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
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
                  } else if (!snapshot.hasData) {
                    return const Text(
                      'En el momento no tiene presupuesto de marca asignado',
                      textAlign: TextAlign.center,
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            const SizedBox(height: 30),
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

  const BarraGrafica({
    super.key,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

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
        const SizedBox(height: 8),
      ],
    );
  }
}

class EtiquetaBullet extends StatelessWidget {
  final Color color;
  final String texto;

  const EtiquetaBullet({
    super.key,
    required this.color,
    required this.texto,
  });

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
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
