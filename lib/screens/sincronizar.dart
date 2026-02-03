import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:productos_app/widgets/carrito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SincronizarPage extends StatefulWidget {
  @override
  State<SincronizarPage> createState() => _SincronizarPageState();
}

class _SincronizarPageState extends State<SincronizarPage> {
  final String codigo = GetStorage().read('slpCode');
  final String usuario = GetStorage().read('usuario');
  final String empresa = GetStorage().read('empresa');

  final GetStorage storage = GetStorage();
  final Connectivity _connectivity = Connectivity();

  final DateTime now = DateTime.now();

  List _clientes = [];
  List _items = [];
  List _stockFull = [];
  List _ventas = [];

  String isSincCustomer = "";
  String isSincItems = "";
  String isSincStock = "";
  String isSincVentas = "";
  String isSincGps = "";

  bool btnClientEnable = true;
  bool btnItemEnable = true;
  bool btnStockEnable = true;
  bool btnVentaEnable = true;
  bool btnGpsEnable = true;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> sincronizarVentas() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/list-order/$empresa?slpcode=$usuario&year=${now.year}&month=${now.month}&day=${now.day}';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) {
      isSincVentas = "Error de red";
      return;
    }

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp["code"] == -1) {
      isSincVentas = "Error";
      return;
    }

    final data = resp["content"];
    if (!mounted) return;

    setState(() {
      _ventas = data;
    });

    storage.write('ventas', data);
    isSincVentas = "Ok";
  }

  Future<Position> activeteLocation() async {
    try {
      final LocationPermission permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Position(
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

      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return Position(
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

  Future<http.Response?> createRecordGeoLocation(
    String latitude,
    String longitude,
    String slpCode,
    String companyName,
    String docType,
  ) async {
    const String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-record-geo-location';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) {
      isSincGps = "Error de red";
      return null;
    }

    return http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          "slpCode": slpCode,
          "latitude": latitude,
          "longitude": longitude,
          "companyName": companyName,
          "docType": docType,
        },
      ),
    );
  }

  Future<void> sincronizarStock() async {
    const String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/IGB?itemcode=0&whscode=0&slpcode=0';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) {
      isSincStock = "Error de red";
      return;
    }

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp["code"] == -1) {
      isSincStock = "Error";
      return;
    }

    final data = resp["content"];
    if (!mounted) return;

    setState(() {
      _stockFull = data;
    });
    storage.write('stockFull', data);
    isSincStock = "Ok";
  }

  Future<void> sincronizarItems() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/$empresa?slpcode=$usuario';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) {
      isSincItems = "Error de red";
      return;
    }

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp["code"] == -1) {
      isSincItems = "Error";
      return;
    }

    final data = resp["content"];
    if (!mounted) return;

    setState(() {
      _items = data;
    });
    storage.write('items', data);
    isSincItems = "Ok";
  }

  Future<void> sincClientes() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/customers/$codigo/$empresa';

    final bool isConnected = await checkConnectivity();
    if (!isConnected) {
      isSincCustomer = "Error de red";
      return;
    }

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp["code"] == -1 || response.statusCode != 200) {
      isSincCustomer = "Error";
      return;
    }

    final data = resp["content"];
    if (!mounted) return;

    setState(() {
      _clientes = data;
    });
    storage.write('datosClientes', data);
    isSincCustomer = "Ok";
  }

  void _setButtonEnabled(String typeBtn, bool value) {
    setState(() {
      switch (typeBtn) {
        case "Clientes":
          btnClientEnable = value;
          break;
        case "Items":
          btnItemEnable = value;
          break;
        case "Stock":
          btnStockEnable = value;
          break;
        case "Ventas":
          btnVentaEnable = value;
          break;
        case "GPS":
          btnGpsEnable = value;
          break;
      }
    });
  }

  void _showAlert({
    required BuildContext context,
    required String message,
    required String typeBtn,
    required bool isError,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                color: isError ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(isError ? 'Error!' : 'Muy bien'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                _setButtonEnabled(typeBtn, true);

                if (typeBtn == "GPS" && isError) {
                  Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );
                }

                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearAppData(BuildContext context) async {
    try {
      await DefaultCacheManager().emptyCache();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al limpiar datos y caché'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
        leading: const SizedBox.shrink(),
        actions: const [
          CarritoPedido(),
        ],
        title: const Text(
          'Sincronizar',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: btnClientEnable
                    ? () async {
                        _setButtonEnabled("Clientes", false);
                        await clearAppData(context);
                        await sincClientes();

                        if (isSincCustomer == "Ok") {
                          _showAlert(
                            context: context,
                            message: "Clientes sincronizados",
                            typeBtn: "Clientes",
                            isError: false,
                          );
                        } else {
                          _showAlert(
                            context: context,
                            message:
                                "No se pudo sincronizar clientes, error de red, verifique conectividad",
                            typeBtn: "Clientes",
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.supervisor_account_outlined,
                        color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Clientes",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: btnItemEnable
                    ? () async {
                        _setButtonEnabled("Items", false);
                        await sincronizarItems();

                        if (isSincItems == "Ok") {
                          _showAlert(
                            context: context,
                            message: "Items sincronizados",
                            typeBtn: "Items",
                            isError: false,
                          );
                        } else {
                          _showAlert(
                            context: context,
                            message:
                                "No se pudo sincronizar Items, error de red, verifique conectividad",
                            typeBtn: "Items",
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.manage_search_outlined, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Items",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: btnStockEnable
                    ? () async {
                        _setButtonEnabled("Stock", false);
                        await sincronizarStock();

                        if (isSincStock == "Ok") {
                          _showAlert(
                            context: context,
                            message: "Stock sincronizado",
                            typeBtn: "Stock",
                            isError: false,
                          );
                        } else {
                          _showAlert(
                            context: context,
                            message:
                                "No se pudo sincronizar Stock, error de red, verifique conectividad",
                            typeBtn: "Stock",
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.art_track_sharp, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Stock",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: btnVentaEnable
                    ? () async {
                        _setButtonEnabled("Ventas", false);
                        await sincronizarVentas();

                        if (isSincVentas == "Ok") {
                          _showAlert(
                            context: context,
                            message: "Ventas sincronizadas",
                            typeBtn: "Ventas",
                            isError: false,
                          );
                        } else {
                          _showAlert(
                            context: context,
                            message:
                                "No se pudo sincronizar Ventas, error de red, verifique conectividad",
                            typeBtn: "Ventas",
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shopping_cart_checkout, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Ventas",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: btnGpsEnable
                    ? () async {
                        _setButtonEnabled("GPS", false);

                        final Position locationData = await activeteLocation();
                        String extra = "";

                        if (locationData.latitude == 0.0 ||
                            locationData.longitude == 0.0) {
                          isSincGps = "Error";
                          extra = ", active la ubicación y vuelva a lanzar.";
                        } else {
                          try {
                            final http.Response? response =
                                await createRecordGeoLocation(
                              locationData.latitude.toString(),
                              locationData.longitude.toString(),
                              codigo,
                              empresa,
                              "S",
                            );

                            if (response == null) {
                              isSincGps = "Error de red";
                              extra = ", error de red, verifique conectividad.";
                            } else {
                              final Map<String, dynamic> res =
                                  jsonDecode(response.body);
                              if (res['code'] < 0) {
                                isSincGps = "Error de red";
                                extra =
                                    ", error de red, verifique conectividad.";
                              } else {
                                isSincGps = "Ok";
                              }
                            }
                          } catch (_) {
                            isSincGps = "Error de red";
                            extra = ", error de red, verifique conectividad.";
                          }
                        }

                        if (isSincGps == "Ok") {
                          _showAlert(
                            context: context,
                            message: "GPS sincronizado",
                            typeBtn: "GPS",
                            isError: false,
                          );
                        } else {
                          _showAlert(
                            context: context,
                            message: "No se pudo sincronizar GPS$extra",
                            typeBtn: "GPS",
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.location_on, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "GPS",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
