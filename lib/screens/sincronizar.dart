import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:productos_app/widgets/carrito.dart';

class SincronizarPage extends StatefulWidget {
  @override
  State<SincronizarPage> createState() => _SincronizarPageState();
}

class _SincronizarPageState extends State<SincronizarPage> {
  String codigo = GetStorage().read('slpCode');
  String usuario = GetStorage().read('usuario');
  List _clientes = [];
  GetStorage storage = GetStorage();
  String isSinc = "";
  String isSincItems = "";
  String isSincStock = "";
  String isSincVentas = "";
  String empresa = GetStorage().read('empresa');
  List _items = [];
  List _stockFull = [];
  List _ventas = [];
  Connectivity _connectivity = Connectivity();
  DateTime now = new DateTime.now();

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> sincronizarVentas() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-order/' +
            empresa +
            '?slpcode=' +
            usuario +
            '&year=' +
            now.year.toString() +
            '&month=' +
            now.month.toString() +
            '&day=' +
            now.day.toString();
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      isSincVentas = "Error de red";
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        isSincVentas = "Error";
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(() {
          _ventas = data;

          /// GUARDAR
          storage.write('ventas', _ventas);
        });
        isSincVentas = "Ok";
      }
    }
  }

  Future<void> sincronizarStock() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/IGB?itemcode=0&whscode=0&slpcode=' +
            usuario;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      isSincStock = "Error de red";
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        isSincStock = "Error";
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(() {
          _stockFull = data;

          /// GUARDAR
          storage.write('stockFull', _stockFull);
        });
        isSincStock = "Ok";
      }
    }
  }

  Future<void> sincronizarItems() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/' + empresa;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      isSincItems = "Error de red";
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        isSincItems = "Error";
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(() {
          _items = data;

          /// GUARDAR
          storage.write('items', _items);
        });
        isSincItems = "Ok";
      }
    }
  }

  Future<void> sincClientes() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/customers/' +
            codigo +
            '/' +
            empresa;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      isSinc = "Error de red";
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
        isSinc = "Error";
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(() {
          _clientes = data;

          /// GUARDAR EN LOCAL STORAGE
          storage.write('datosClientes', _clientes);
        });
        isSinc = "Ok";
      }
    }
  }

  void showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text('Muy bien'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showAlertError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text('Error!'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 129, 235, 1),
        actions: [
          CarritoPedido(),
        ],
        title: Text('Sincronizar', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
            ),
            SizedBox(
              width: 150, // <-- Your width
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(30, 129, 235, 1)),
                child: Text("Clientes", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  await sincClientes();
                  String errorREd = "";
                  if (isSinc == "Ok") {
                    showAlert(context, "Clientes sincronizados");
                  } else {
                    if (isSinc == "Error de red")
                      errorREd = ", error de red, verifique conectividad";
                    showAlertError(
                        context, "No se pudo sincronizar clientes" + errorREd);
                  }
                },
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 150, // <-- Your width
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(30, 129, 235, 1)),
                child: Text("Items", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  await sincronizarItems();
                  String errorREd = "";
                  if (isSincItems == "Ok") {
                    showAlert(context, "Items sincronizados");
                  } else {
                    if (isSincItems == "Error de red")
                      errorREd = ", error de red, verifique conectividad";
                    showAlertError(
                        context, "No se pudo sincronizar Items" + errorREd);
                  }
                },
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 150, // <-- Your width
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(30, 129, 235, 1)),
                child: Text("Stock", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  await sincronizarStock();
                  String errorREd = "";
                  if (isSincStock == "Ok") {
                    showAlert(context, "Stock sincronizado");
                  } else {
                    if (isSincStock == "Error de red")
                      errorREd = ", error de red, verifique conectividad";
                    showAlertError(
                        context, "No se pudo sincronizar Stock" + errorREd);
                  }
                },
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 150, // <-- Your width
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(30, 129, 235, 1)),
                child: Text("Ventas", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  await sincronizarVentas();
                  String errorREd = "";
                  if (isSincVentas == "Ok") {
                    showAlert(context, "Ventas sincronizadas");
                  } else {
                    if (isSincVentas == "Error de red")
                      errorREd = ", error de red, verifique conectividad";
                    showAlertError(
                        context, "No se pudo sincronizar Ventas" + errorREd);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
