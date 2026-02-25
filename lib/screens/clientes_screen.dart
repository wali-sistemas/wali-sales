import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'buscador_clientes.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:productos_app/screens/screens.dart';

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
  final TextEditingController ciudadCtrl = TextEditingController();
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
    //_fetchData();
  }

  @override
  void dispose() {
    documentoCtrl.dispose();
    razonCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    ciudadCtrl.dispose();
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

  /*Future<void> _fetchData() async {
    final cached = GetStorage().read('datosClientes');
    if (cached != null) {
      _clientes = cached;
      if (mounted) setState(() {});
      return;
    }

    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/customers/$codigo/$empresa';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    final codigoError = resp['code'];
    if (codigoError == -1) {
      final String texto = 'No se encontraron clientes para el asesor ' +
          codigo +
          ' en la empresa ' +
          empresa;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texto)),
        );
      }
    }

    final data = resp['content'];
    if (!mounted) return;

    setState(() {
      _clientes = data;
      storage.write('datosClientes', _clientes);
    });
  }*/

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
          "city": cliente["ciudad"].toString()
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
            tabs: [
              Tab(
                child: Text(
                  'Clientes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Tab(
                child: Text(
                  'Prospecto',
                  style: TextStyle(color: Colors.white),
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
    return SafeArea(
      child: ListView.builder(
        itemCount: _clientes.length,
        itemBuilder: (context, index) {
          final String cardCode = _clientes[index]['cardCode'];
          final bool isLead = cardCode.startsWith('L');
          return Card(
            child: Container(
              color: isLead
                  ? const Color.fromRGBO(230, 230, 230, 1)
                  : const Color.fromRGBO(250, 251, 253, 1),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    '$cardCode - ${_clientes[index]['cardName']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isLead ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () {
                      storage.remove('dirEnvio');

                      if (GetStorage().read('itemsPedido') != null) {
                        itemsPedidoLocal = GetStorage().read('itemsPedido');
                        pedidoLocal = GetStorage().read('pedido');
                      }

                      if (pedidoLocal['cardCode'] != cardCode &&
                          itemsPedidoLocal.isNotEmpty) {
                        showAlertDialogItemsInShoppingCart(
                          context,
                          cardCode,
                        );
                      } else {
                        storage.write('estadoPedido', 'nuevo');
                        storage.write('nit', _clientes[index]['nit']);
                        storage.write('cardCode', cardCode);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PedidosPage(),
                          ),
                        );
                      }
                    },
                    label: const Text(''),
                    icon: const Icon(
                      Icons.add,
                      color: Colors.black54,
                    ),
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
                controller: ciudadCtrl,
                label: 'Ciudad',
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
                            "ciudad": ciudadCtrl.text.toUpperCase(),
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
                          } catch (e) {}
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
    bool isEmail = false,
    bool enabled = true,
    Function(String)? onChanged,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: enabled,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
        ).copyWith(labelText: label),
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obligatorio';
                }

                if (isEmail) {
                  final emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailReg.hasMatch(value)) {
                    return 'Correo inválido';
                  }
                }

                return null;
              }
            : null,
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
