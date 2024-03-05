import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'buscador_clientes.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:connectivity/connectivity.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({Key? key}) : super(key: key);

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List _clientes = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');
  String usuario = GetStorage().read('usuario');
  Connectivity _connectivity = Connectivity();
  List _stockFull = [];
  Map<String, dynamic> pedidoLocal = {};
  List<dynamic> itemsPedidoLocal = [];

  @override
  void initState() {
    super.initState();
    sincClientes();
    sincronizarStock();
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> sincClientes() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/customers/' +
            codigo +
            '/' +
            empresa;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      //print("Error de red");
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      String texto = "No se encontraron clientes para usuario " +
          codigo +
          " y empresa " +
          empresa;

      final codigoError = resp["code"];
      if (codigoError == -1 ||
          response.statusCode != 200 ||
          isConnected == false) {
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(
          () {
            _clientes = data;

            /// GUARDAR EN LOCAL STORAGE
            storage.write('datosClientes', _clientes);
          },
        );
      }
    }
  }

  Future<void> sincronizarStock() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
            empresa +
            '?itemcode=0&whscode=0&slpcode=0';
    //usuario;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      //print("Error de red");
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        //print("codigoError: $codigoError");
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(
          () {
            _stockFull = data;

            /// GUARDAR
            storage.write('stockFull', _stockFull);
          },
        );
      }
    }
  }

  Future<void> _fetchData() async {
    if (GetStorage().read('datosClientes') == null) {
      final String apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/customers/' +
              codigo +
              '/' +
              empresa;

      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      String texto = "No se encontraron clientes para usuario " +
          codigo +
          " y empresa " +
          empresa;

      final codigoError = resp["code"];
      if (codigoError == -1) {
        var snackBar = SnackBar(
          content: Text(texto),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      final data = resp["content"];
      //print(data.toString());
      if (!mounted) return;
      setState(
        () {
          _clientes = data;

          /// GUARDAR EN LOCAL STORAGE
          _guardarDatos();
        },
      );
    } else {
      _clientes = GetStorage().read('datosClientes');
    }
  }

  Future<void> _guardarDatos() async {
    // SharedPreferences pref = await SharedPreferences.getInstance();
    // //Map json = jsonDecode(jsonString);
    // String user = jsonEncode(_clientes);
    // pref.setString('datosClientes', user);
    storage.write('datosClientes', _clientes);
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          CarritoPedido(),
        ],
        title: ListTile(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegateClientes(),
            );
          },
          title: Text(
            'Buscar cliente',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: clientes(context),
    );
  }

  Widget clientes(BuildContext context) {
    _fetchData();
    return SafeArea(
        child: ListView.builder(
      itemCount: _clientes.length,
      itemBuilder: (context, index) {
        return Card(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  _clientes[index]['cardCode'] +
                      ' - ' +
                      _clientes[index]['cardName'],
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: () {
                    storage.remove('dirEnvio');

                    if (GetStorage().read('itemsPedido') != null) {
                      itemsPedidoLocal = GetStorage().read('itemsPedido');
                      pedidoLocal = GetStorage().read('pedido');
                    }
                    if (pedidoLocal["cardCode"] !=
                            _clientes[index]['cardCode'] &&
                        itemsPedidoLocal.length > 0) {
                      showAlertDialogItemsInShoppingCart(
                          context, pedidoLocal["cardCode"]);
                    } else {
                      storage.write('estadoPedido', 'nuevo');
                      storage.write('nit', _clientes[index]["nit"]);
                      storage.write('cardCode', _clientes[index]["cardCode"]);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PedidosPage(),
                        ),
                      );
                    }
                  },
                  label: const Text(''),
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        );
      },
    ));
  }

  showAlertDialogItemsInShoppingCart(BuildContext context, String nit) {
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed: () {
        storage.write('nit', nit);
        Navigator.pop(context);
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed: () {
        storage.remove('observaciones');
        storage.remove('pedido');
        storage.remove('itemsPedido');
        storage.write('nit', nit);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PedidosPage(),
          ),
        );
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text(
          "Tiene ítmes pendientes para otro cliente, si continúa se borrarán e inciará un pedido nuevo, desea continuar?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
