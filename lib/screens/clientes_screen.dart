import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'buscador_clientes.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({Key? key}) : super(key: key);

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List _clientes = [];
  final String codigo = GetStorage().read('slpCode');
  final GetStorage storage = GetStorage();
  final String empresa = GetStorage().read('empresa');
  final String usuario = GetStorage().read('usuario');
  final Connectivity _connectivity = Connectivity();

  List _stockFull = [];
  Map<String, dynamic> pedidoLocal = {};
  List<dynamic> itemsPedidoLocal = [];

  @override
  void initState() {
    super.initState();
    sincClientes();
    sincronizarStock();
    _fetchData();
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

  Future<void> _fetchData() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
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
      ),
    );
  }

  @override
  Widget clientes(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        itemCount: _clientes.length,
        itemBuilder: (context, index) {
          return Card(
            child: Container(
              color: const Color.fromRGBO(250, 251, 253, 1),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    _clientes[index]['cardCode'] +
                        ' - ' +
                        _clientes[index]['cardName'],
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () {
                      storage.remove('dirEnvio');

                      if (GetStorage().read('itemsPedido') != null) {
                        itemsPedidoLocal = GetStorage().read('itemsPedido');
                        pedidoLocal = GetStorage().read('pedido');
                      }

                      if (pedidoLocal['cardCode'] !=
                              _clientes[index]['cardCode'] &&
                          itemsPedidoLocal.isNotEmpty) {
                        showAlertDialogItemsInShoppingCart(
                          context,
                          _clientes[index]['cardCode'],
                        );
                      } else {
                        storage.write('estadoPedido', 'nuevo');
                        storage.write('nit', _clientes[index]['nit']);
                        storage.write('cardCode', _clientes[index]['cardCode']);
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

  @override
  Widget prospecto(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    final documentoCtrl = TextEditingController();
    final razonCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final ciudadCtrl = TextEditingController();
    final departamentoCtrl = TextEditingController();
    final correoCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(
                controller: documentoCtrl,
                label: 'Documento',
                type: TextInputType.number,
              ),
              _input(
                controller: razonCtrl,
                label: 'Razón social',
              ),
              _input(
                controller: telefonoCtrl,
                label: 'Teléfono',
                type: TextInputType.phone,
              ),
              _input(
                controller: direccionCtrl,
                label: 'Dirección',
              ),
              _input(
                controller: ciudadCtrl,
                label: 'Ciudad',
              ),
              _input(
                controller: departamentoCtrl,
                label: 'Departamento',
              ),
              _input(
                controller: correoCtrl,
                label: 'Correo',
                type: TextInputType.emailAddress,
                isEmail: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final cliente = {
                      "documento": documentoCtrl.text,
                      "razon": razonCtrl.text,
                      "telefono": telefonoCtrl.text,
                      "direccion": direccionCtrl.text,
                      "ciudad": ciudadCtrl.text,
                      "departamento": departamentoCtrl.text,
                      "correo": correoCtrl.text,
                    };

                    print(cliente); // aquí ya tienes todo validado
                  }
                },
                child: const Text('Guardar cliente'),
              )
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
      bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
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
          MaterialPageRoute(
            builder: (context) => const PedidosPage(),
          ),
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
