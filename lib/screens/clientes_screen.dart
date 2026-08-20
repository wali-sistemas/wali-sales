import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'package:productos_app/services/services.dart';
import 'buscador_clientes.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:productos_app/screens/screens.dart';
import 'package:geolocator/geolocator.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({Key? key}) : super(key: key);

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List _clientes = [];
  List _municipios = [];
  List _historialVisitas = [];
  List _calles = [
    {"code": "CL", "name": "CALLE"},
    {"code": "CR", "name": "CARRERA"},
    {"code": "AV", "name": "AVENIDA"},
    {"code": "CIR", "name": "CIRCULAR"},
    {"code": "DG", "name": "DIAGONAL"},
    {"code": "TV", "name": "TRANSVERSAL"},
    {"code": "MZ", "name": "MANZANA"},
    {"code": "KM", "name": "KILOMETRO"},
    {"code": "LT", "name": "LOTE"},
    {"code": "VRD", "name": "VEREDA"},
    {"code": "AUT", "name": "AUTOPISTA"}
  ];
  List _letras = [
    {"code": "-", "name": "-"},
    {"code": "A", "name": "A"},
    {"code": "B", "name": "B"},
    {"code": "C", "name": "C"},
    {"code": "D", "name": "D"},
    {"code": "E", "name": "E"},
    {"code": "F", "name": "F"},
    {"code": "G", "name": "G"},
    {"code": "H", "name": "H"},
    {"code": "I", "name": "I"},
  ];
  List _ubicaciones = [
    {"code": "-", "name": "-"},
    {"code": "SUR", "name": "SUR"},
    {"code": "ESTE", "name": "ESTE"},
    {"code": "OESTE", "name": "OESTE"},
    {"code": "NORTE", "name": "NORTE"},
  ];
  List _viviendas = [
    {"code": "-", "name": "-"},
    {"code": "CONJ", "name": "CONJUNTO"},
    {"code": "ED", "name": "EDIFICIO"},
    {"code": "UR", "name": "UNIDAD RESIDENCIAL"},
    {"code": "CA", "name": "CASA"},
    {"code": "APTO", "name": "APARTAMENTO"},
  ];
  final String codigo = GetStorage().read('slpCode');
  final GetStorage storage = GetStorage();
  final String empresa = GetStorage().read('empresa');
  final String usuario = GetStorage().read('usuario');
  final Connectivity _connectivity = Connectivity();

  List _stockFull = [];
  Map<String, dynamic> pedidoLocal = {};
  List<dynamic> itemsPedidoLocal = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController documentoCtrl = TextEditingController();
  final TextEditingController razonCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController barrioCtrl = TextEditingController();
  final TextEditingController departamentoCtrl = TextEditingController();
  final TextEditingController correoCtrl = TextEditingController();
  final TextEditingController nro1Ctrl = TextEditingController();
  final TextEditingController nro2Ctrl = TextEditingController();
  final TextEditingController nro3Ctrl = TextEditingController();

  bool btnProspectoActivo = false;

  String? departamentoSeleccionado;
  String? municipioSeleccionado;
  String? calleSeleccionado;
  String? letraSeleccionado1;
  String? letraSeleccionado2;
  String? ubicacionSeleccionado1;
  String? ubicacionSeleccionado2;
  String? viviendaSeleccionado;

  @override
  void initState() {
    super.initState();
    sincClientes();
    sincronizarStock();
  }

  @override
  void dispose() {
    documentoCtrl.dispose();
    razonCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    barrioCtrl.dispose();
    departamentoCtrl.dispose();
    correoCtrl.dispose();
    super.dispose();
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> sincClientes() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/customers/$codigo/$empresa';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) return;

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    final codigoError = resp['code'];
    if (codigoError == -1 || response.statusCode != 200) return;

    final data = resp['content'];
    if (!mounted) return;

    setState(() {
      _clientes = data;
      storage.write('datosClientes', _clientes);
    });
  }

  Future<void> sincronizarStock() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/$empresa?itemcode=0&whscode=0&slpcode=0';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) return;

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    final codigoError = resp['code'];
    if (codigoError == -1) return;

    final data = resp['content'];
    if (!mounted) return;

    setState(() {
      _stockFull = data;
      storage.write('stockFull', _stockFull);
    });
  }

  Future<http.Response> _createCustomerLead(Map<String, String> cliente) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-customer-lead';

    return http.post(
      Uri.parse(apiUrl),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          "document": cliente["documento"],
          "cardName": cliente["razonSocial"].toString(),
          "cellular": cliente["telefono"],
          "mail": cliente["correo"].toString().toUpperCase(),
          "slpCode": usuario,
          "companyName": empresa,
          "address": cliente["direccion"].toString(),
          "departament": cliente["departamento"].toString(),
          "municipio": cliente["municipio"].toString(),
          "province": cliente["barrio"].toString()
        },
      ),
    );
  }

  Future<void> _listMunicipios(String? codeDepartment) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/pedbox/list-municipios/IGB?departamento=$codeDepartment';

    final response = await http.get(Uri.parse(apiUrl));

    List<dynamic> resp = jsonDecode(response.body);
    final data = resp;

    if (!mounted) return;
    setState(
      () {
        _municipios = data;
      },
    );
  }

  Future<void> _listHistoryVisitByCustomer(
      String? slpCode, String? cardCode) async {
    setState(() {
      _historialVisitas = [];
    });

    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-history-visit/IGB?slpcode=$slpCode&cardcode=$cardCode';

    final response = await http.get(Uri.parse(apiUrl));

    final List<dynamic> resp = jsonDecode(response.body);

    if (!mounted) return;

    setState(() {
      _historialVisitas = resp;
    });
  }

  Future<http.Response> _createRecordGeoLocation(
      String latitude,
      String longitude,
      String slpCode,
      String companyName,
      String docType,
      String cardCode) async {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-record-geo-location';

    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          "slpCode": slpCode,
          "latitude": latitude,
          "longitude": longitude,
          "companyName": companyName,
          "docType": docType,
          "cardCode": cardCode,
        },
      ),
    );
  }

  Future<Position> _activeteLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return new Position(
          longitude: 0.0,
          latitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return position;
      }
    } catch (e) {
      return new Position(
        longitude: 0.0,
        latitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                MaterialPageRoute(builder: (_) => HomePage()),
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
                delegate: CustomSearchDelegateClientes(),
              );
            },
            title: const Row(
              children: [
                Icon(Icons.search, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Buscar cliente',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          bottom: const TabBar(
            labelColor: const Color.fromRGBO(1, 39, 80, 1),
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(
                child: Text(
                  'Clientes',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Tab(
                child: Text(
                  'Prospecto',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            clientes(context),
            prospecto(context),
          ],
        ),
      ),
    );
  }

  Widget clientes(BuildContext context) {
    DateTime now = DateTime.now();
    String year = DateFormat('yyyy').format(now);
    String monthName = DateFormat('MMMM', 'es_ES').format(now);

    void showHistorialVisitasCliente(
        BuildContext context, String cardCode, String cardName) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.70,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    8,
                    8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.history,
                          color: Color.fromRGBO(
                            30,
                            129,
                            235,
                            1,
                          ),
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Historial de visitas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cardName + "\n" + cardCode,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.view_day_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        year + ' - ' + monthName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_historialVisitas.length} visitas',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_historialVisitas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 45,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No hay historial de visitas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        80,
                      ),
                      shrinkWrap: true,
                      itemCount: _historialVisitas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        final visita = _historialVisitas[index];
                        final String numero = visita[0].toString();
                        final String fecha = visita[1]?.toString() ?? '';
                        final String hora = visita[2]?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                              250,
                              251,
                              253,
                              1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black12,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(
                                    30,
                                    129,
                                    235,
                                    0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  numero,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(
                                      30,
                                      129,
                                      235,
                                      1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 17,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  fecha,
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.access_time_outlined,
                                size: 17,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hora,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    void showConfirmVisitDialog(BuildContext context, String cardCode) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          bool isLoading = false;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text(
                  '¿Confirmar visita?',
                  textAlign: TextAlign.center,
                ),
                content: isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Espere por favor...',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : null,
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isLoading = true;
                            });
                            storage.remove('dirEnvio');

                            if (GetStorage().read('itemsPedido') != null) {
                              itemsPedidoLocal =
                                  GetStorage().read('itemsPedido');
                              pedidoLocal = GetStorage().read('pedido');
                            }
                            if (pedidoLocal['cardCode'] != cardCode &&
                                itemsPedidoLocal.isNotEmpty) {
                              Navigator.pop(context);

                              showAlertDialogItemsInShoppingCart(
                                  context, cardCode);
                            } else {
                              storage.write('estadoPedido', 'nuevo');
                              storage.write('nit', cardCode);
                              storage.write('cardCode', cardCode);

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PedidosPage(),
                                ),
                              );
                            }
                          },
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              Position locationData = await _activeteLocation();
                              if (locationData.latitude == 0.0 ||
                                  locationData.longitude == 0.0) {
                                NotificationsService.showSnackbar(
                                  "Active la ubicación del móvil para poder continuar.",
                                );
                                await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                                return;
                              }

                              http.Response response =
                                  await _createRecordGeoLocation(
                                locationData.latitude.toString(),
                                locationData.longitude.toString(),
                                GetStorage().read('slpCode'),
                                GetStorage().read('empresa'),
                                'V',
                                cardCode,
                              );

                              Map<String, dynamic> res =
                                  jsonDecode(response.body);
                              if (res['code'] == 0) {
                                storage.remove('dirEnvio');
                                if (GetStorage().read('itemsPedido') != null) {
                                  itemsPedidoLocal =
                                      GetStorage().read('itemsPedido');
                                  pedidoLocal = GetStorage().read('pedido');
                                }
                                if (pedidoLocal['cardCode'] != cardCode &&
                                    itemsPedidoLocal.isNotEmpty) {
                                  if (context.mounted) {
                                    Navigator.pop(context);

                                    showAlertDialogItemsInShoppingCart(
                                      context,
                                      cardCode,
                                    );
                                  }
                                } else {
                                  storage.write(
                                    'estadoPedido',
                                    'nuevo',
                                  );
                                  storage.write('nit', cardCode);
                                  storage.write(
                                    'cardCode',
                                    cardCode,
                                  );

                                  if (context.mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PedidosPage(),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                NotificationsService.showSnackbar(
                                  res['content'],
                                );
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            } catch (e) {
                              NotificationsService.showSnackbar(
                                "Ups, algo falló. Inténtalo nuevamente.",
                              );
                              if (context.mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },
                    child: const Icon(
                      Icons.check,
                      size: 28,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return SafeArea(
      child: ListView.builder(
        itemCount: _clientes.length,
        itemBuilder: (context, index) {
          final String cardCode = _clientes[index]['cardCode'];
          final String cardName = _clientes[index]['cardName'] ?? '';
          final bool isLead = cardCode.startsWith('L');
          final String locationVisit = _clientes[index]['locationVisit'] ?? '';
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            child: Container(
              color: isLead
                  ? const Color.fromRGBO(230, 230, 230, 1)
                  : const Color.fromRGBO(250, 251, 253, 1),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 0,
                ),
                minLeadingWidth: 30,
                horizontalTitleGap: 5,
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: 0,
                  vertical: -2,
                ),
                leading: locationVisit == 'Y'
                    ? InkWell(
                        onTap: () async {
                          await _listHistoryVisitByCustomer(
                              GetStorage().read('slpCode'), cardCode);
                          if (!mounted) return;

                          showHistorialVisitasCliente(
                              context, cardCode, cardName);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.black54,
                            size: 22,
                          ),
                        ),
                      )
                    : null,
                title: Text(
                  '$cardCode' + '\n' + '${_clientes[index]['cardName']}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isLead ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () {
                    showConfirmVisitDialog(
                      context,
                      cardCode,
                    );
                  },
                  tooltip: 'Crear pedido',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.black54,
                    size: 25,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _actualizarDireccion() {
    direccionCtrl.text = [
      calleSeleccionado ?? '',
      nro1Ctrl.text,
      letraSeleccionado1 ?? '',
      ubicacionSeleccionado1 ?? '',
      nro2Ctrl.text,
      letraSeleccionado2 ?? '',
      nro3Ctrl.text,
      ubicacionSeleccionado2 ?? '',
      viviendaSeleccionado ?? '',
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
  }

  Widget prospecto(BuildContext context) {
    final List<Map<String, String>> departamentos = [
      {"code": "05", "name": "ANTIOQUIA"},
      {"code": "08", "name": "ATLANTICO"},
      {"code": "11", "name": "BOGOTÁ"},
      {"code": "13", "name": "BOLIVAR"},
      {"code": "15", "name": "BOYACÁ"},
      {"code": "17", "name": "CALDAS"},
      {"code": "18", "name": "CAQUETÁ"},
      {"code": "19", "name": "CAUCA"},
      {"code": "20", "name": "CESAR"},
      {"code": "23", "name": "CÓRDOBA"},
      {"code": "25", "name": "CUNDINAMARCA"},
      {"code": "27", "name": "CHOCÓ"},
      {"code": "41", "name": "HUILA"},
      {"code": "44", "name": "GUAJIRA"},
      {"code": "47", "name": "MAGDALENA"},
      {"code": "50", "name": "META"},
      {"code": "52", "name": "NARINO"},
      {"code": "54", "name": "NORT SANTANDER"},
      {"code": "63", "name": "QUINDÍO"},
      {"code": "66", "name": "RISARALDA"},
      {"code": "68", "name": "SANTANDER"},
      {"code": "70", "name": "SUCRE"},
      {"code": "73", "name": "TOLIMA"},
      {"code": "76", "name": "VLL DEL CAUCA"},
      {"code": "81", "name": "ARAUCA"},
      {"code": "85", "name": "CASANARE"},
      {"code": "86", "name": "PUTUMAYO"},
      {"code": "88", "name": "SAN ANDRÉS"},
      {"code": "91", "name": "AMAZONAS"},
      {"code": "94", "name": "GUAINÍA"},
      {"code": "95", "name": "GUAVIARE"},
      {"code": "97", "name": "VAUPÉS"},
      {"code": "99", "name": "VICHADA"},
    ];

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "*Aplica únicamente para clientes de contado.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              _input(
                controller: documentoCtrl,
                label: 'Documento',
                type: TextInputType.number,
                requiredField: true,
                onlyNumbers: true,
              ),
              _input(
                controller: razonCtrl,
                label: 'Nombre completo',
                requiredField: true,
              ),
              _input(
                controller: telefonoCtrl,
                label: 'Teléfono',
                type: TextInputType.phone,
                requiredField: true,
                onlyNumbers: true,
              ),
              _input(
                controller: correoCtrl,
                label: 'Correo',
                type: TextInputType.emailAddress,
                isEmail: true,
                requiredField: true,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: departamentoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Departamento',
                    border: OutlineInputBorder(),
                  ),
                  items: departamentos.map((dep) {
                    return DropdownMenuItem<String>(
                      value: dep["code"],
                      child: Text(dep["name"]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      departamentoSeleccionado = value;
                    });
                    _listMunicipios(departamentoSeleccionado);
                  },
                  validator: (value) =>
                      value == null ? 'Campo obligatorio' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: municipioSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                  ),
                  items: _municipios.map((mun) {
                    return DropdownMenuItem<String>(
                      value: mun["code"],
                      child: Text(mun["name"]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      municipioSeleccionado = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Campo obligatorio' : null,
                ),
              ),
              _input(
                controller: barrioCtrl,
                label: 'Barrio',
                requiredField: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: calleSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Calle',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _calles.map((calle) {
                          return DropdownMenuItem<String>(
                            value: calle["code"],
                            child: Text(
                              calle["name"]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            calleSeleccionado = value;
                          });
                          _actualizarDireccion();
                        },
                        validator: (value) =>
                            value == null ? 'Campo obligatorio' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: _input(
                        controller: nro1Ctrl,
                        label: '#',
                        requiredField: true,
                        type: TextInputType.number,
                        onChanged: (value) {
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: letraSeleccionado1,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Letra',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _letras.map((letra) {
                          return DropdownMenuItem<String>(
                            value: letra["code"],
                            child: Text(
                              letra["name"]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            letraSeleccionado1 = value;
                          });
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: ubicacionSeleccionado1,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ubic..',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _ubicaciones.map((ubicacion) {
                          return DropdownMenuItem<String>(
                            value: ubicacion["code"],
                            child: Text(
                              ubicacion["name"]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            ubicacionSeleccionado1 = value;
                          });
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: _input(
                        controller: nro2Ctrl,
                        label: '#',
                        type: TextInputType.number,
                        onChanged: (value) {
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: letraSeleccionado2,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Letra',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _letras.map((letra) {
                          return DropdownMenuItem<String>(
                            value: letra["code"],
                            child: Text(
                              letra["name"]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            letraSeleccionado2 = value;
                          });
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: _input(
                        controller: nro3Ctrl,
                        label: '#',
                        type: TextInputType.number,
                        onChanged: (value) {
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: ubicacionSeleccionado2,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ubic..',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _ubicaciones.map((ubicacion) {
                          return DropdownMenuItem<String>(
                            value: ubicacion["code"],
                            child: Text(
                              ubicacion["name"]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            ubicacionSeleccionado2 = value;
                          });
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: viviendaSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _viviendas.map((vivienda) {
                          return DropdownMenuItem<String>(
                            value: vivienda["code"],
                            child: Text(
                              vivienda["name"]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            viviendaSeleccionado = value;
                          });
                          _actualizarDireccion();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              _input(
                controller: direccionCtrl,
                label: 'Dirección',
                onChanged: (_) => _actualizarDireccion(),
                enabled: false,
                requiredField: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: btnProspectoActivo
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => btnProspectoActivo = true);

                          final cliente = <String, String>{
                            "documento": documentoCtrl.text,
                            "razonSocial": razonCtrl.text.toUpperCase(),
                            "telefono": telefonoCtrl.text,
                            "direccion": direccionCtrl.text,
                            "barrio": barrioCtrl.text.toUpperCase(),
                            "departamento": departamentoSeleccionado.toString(),
                            "municipio": municipioSeleccionado.toString(),
                            "correo": correoCtrl.text.toUpperCase(),
                          };

                          try {
                            final http.Response response =
                                await _createCustomerLead(cliente);
                            final Map<String, dynamic> resultado =
                                jsonDecode(response.body);
                            if (resultado["code"] >= 0) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClientesPage(),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '¡Listo! El prospecto se creó correctamente.',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ups, algo falló. Inténtalo nuevamente.',
                                  ),
                                ),
                              );
                              setState(() => btnProspectoActivo = false);
                            }
                          } catch (e) {
                            NotificationsService.showSnackbar(
                                "Ups, algo falló. Inténtalo nuevamente.");
                          }
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        btnProspectoActivo ? 'Espere' : 'Crear',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
      {required TextEditingController controller,
      required String label,
      TextInputType type = TextInputType.text,
      bool isEmail = false,
      bool enabled = true,
      Function(String)? onChanged,
      bool requiredField = false,
      bool onlyNumbers = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: enabled,
        onChanged: onChanged,
        inputFormatters:
            onlyNumbers ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
        ).copyWith(labelText: label),
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return 'Campo obligatorio';
          }
          if (value != null && value.isNotEmpty) {
            if (isEmail) {
              final emailReg = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailReg.hasMatch(value)) {
                return 'Correo inválido';
              }
            }
            if (onlyNumbers) {
              final numberReg = RegExp(r'^[0-9]+$');
              if (!numberReg.hasMatch(value)) {
                return 'Solo se permiten números';
              }
            }
          }
          return null;
        },
      ),
    );
  }

  void showAlertDialogItemsInShoppingCart(BuildContext context, String nit) {
    final Widget cancelButton = ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text('NO'),
    );

    final Widget continueButton = ElevatedButton(
      onPressed: () {
        storage.remove('observaciones');
        storage.remove('pedido');
        storage.remove('itemsPedido');
        storage.remove('dirEnvio');
        storage.remove('pedidoGuardado');
        storage.write('estadoPedido', 'nuevo');
        storage.write('cardCode', nit);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PedidosPage()),
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
      content: const Text(
        'Tiene ítems pendientes para otro cliente, si continúa se borrarán e iniciará un pedido nuevo.\n¿Desea continuar?',
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => alert,
    );
  }
}
