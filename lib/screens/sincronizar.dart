import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:productos_app/services/notifications_extranet_service.dart';
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
  String isSincCustomer = "";
  String isSincItems = "";
  String isSincStock = "";
  String isSincVentas = "";
  String isSincGps = "";
  String empresa = GetStorage().read('empresa');
  List _items = [];
  List _stockFull = [];
  List _ventas = [];
  Connectivity _connectivity = Connectivity();
  DateTime now = new DateTime.now();
  bool btnClientEnable = true;
  bool btnItemEnable = true;
  bool btnStockEnable = true;
  bool btnVentaEnable = true;
  bool btnGpsEnable = true;

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
        setState(
          () {
            _ventas = data;
            storage.write('ventas', _ventas);
          },
        );
        isSincVentas = "Ok";
      }
    }
  }

  Future<Position> activeteLocation() async {
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
            speedAccuracy: 0.0);
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
          speedAccuracy: 0.0);
    }
  }

  Future<http.Response?> createRecordGeoLocation(
      String latitude,
      String longitude,
      String slpCode,
      String companyName,
      String docType) async {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-record-geo-location';
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      isSincGps = "Error de red";
      return null;
    } else {
      return http.post(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(
          <String, dynamic>{
            "slpCode": slpCode,
            "latitude": latitude,
            "longitude": longitude,
            "companyName": companyName,
            "docType": docType
          },
        ),
      );
    }
  }

  Future<void> sincronizarStock() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/IGB?itemcode=0&whscode=0&slpcode=0';
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
        setState(
          () {
            _stockFull = data;
            storage.write('stockFull', _stockFull);
          },
        );
        isSincStock = "Ok";
      }
    }
  }

  Future<void> sincronizarItems() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/' +
            empresa +
            "?slpcode=" +
            usuario;
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
        setState(
          () {
            _items = data;
            storage.write('items', _items);
          },
        );
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
      isSincCustomer = "Error de red";
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1 ||
          response.statusCode != 200 ||
          isConnected == false) {
        isSincCustomer = "Error";
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(
          () {
            _clientes = data;
            storage.write('datosClientes', _clientes);
          },
        );
        isSincCustomer = "Ok";
      }
    }
  }

  void showAlert(BuildContext context, String message, String typeBtn) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                if (typeBtn == "Clientes") {
                  setState(
                    () {
                      btnClientEnable = true;
                    },
                  );
                } else if (typeBtn == "Items") {
                  setState(
                    () {
                      btnItemEnable = true;
                    },
                  );
                } else if (typeBtn == "Stock") {
                  setState(
                    () {
                      btnStockEnable = true;
                    },
                  );
                } else if (typeBtn == "Ventas") {
                  setState(
                    () {
                      btnVentaEnable = true;
                    },
                  );
                } else if (typeBtn == "GPS") {
                  setState(
                    () {
                      btnGpsEnable = true;
                    },
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showAlertError(BuildContext context, String message, String typeBtn) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                if (typeBtn == "Clientes") {
                  setState(
                    () {
                      btnClientEnable = true;
                    },
                  );
                } else if (typeBtn == "Items") {
                  setState(
                    () {
                      btnItemEnable = true;
                    },
                  );
                } else if (typeBtn == "Stock") {
                  setState(
                    () {
                      btnStockEnable = true;
                    },
                  );
                } else if (typeBtn == "Ventas") {
                  setState(
                    () {
                      btnVentaEnable = true;
                    },
                  );
                } else if (typeBtn == "GPS") {
                  setState(
                    () {
                      btnGpsEnable = true;
                    },
                  );
                  Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );
                }
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
        leading: GestureDetector(
          /*child: Icon(
            Icons.arrow_back_ios,
            color: Color.fromRGBO(30, 129, 235, 1),
          ),*/
          onTap: () {
            /*Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );*/
          },
        ),
        actions: [
          CarritoPedido(),
        ],
        title: Text(
          'Sincronizar',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
            ),
            SizedBox(
              width: 300,
              height: 50,
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
                    Icon(
                      Icons.supervisor_account_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Clientes",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                onPressed: btnClientEnable
                    ? () async {
                        setState(
                          () {
                            btnClientEnable = false;
                          },
                        );
                        await sincClientes();
                        String errorREd = "";
                        if (isSincCustomer == "Ok") {
                          showAlert(
                              context, "Clientes sincronizados", "Clientes");
                        } else {
                          if (isSincCustomer == "Error de red") {
                            errorREd = ", error de red, verifique conectividad";
                            showAlertError(
                                context,
                                "No se pudo sincronizar clientes" + errorREd,
                                "Clientes");
                          }
                        }
                      }
                    : null,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 300,
              height: 50,
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
                    Icon(
                      Icons.manage_search_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Items",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                onPressed: btnItemEnable
                    ? () async {
                        setState(
                          () {
                            btnItemEnable = false;
                          },
                        );
                        await sincronizarItems();
                        String errorREd = "";
                        if (isSincItems == "Ok") {
                          showAlert(context, "Items sincronizados", "Items");
                        } else {
                          if (isSincItems == "Error de red") {
                            errorREd = ", error de red, verifique conectividad";
                            showAlertError(
                              context,
                              "No se pudo sincronizar Items" + errorREd,
                              "Items",
                            );
                          }
                        }
                      }
                    : null,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 300,
              height: 50,
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
                    Icon(
                      Icons.art_track_sharp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Stock",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                onPressed: btnStockEnable
                    ? () async {
                        setState(
                          () {
                            btnStockEnable = false;
                          },
                        );
                        await sincronizarStock();
                        String errorREd = "";
                        if (isSincStock == "Ok") {
                          showAlert(context, "Stock sincronizado", "Stock");
                        } else {
                          if (isSincStock == "Error de red") {
                            errorREd = ", error de red, verifique conectividad";
                            showAlertError(
                              context,
                              "No se pudo sincronizar Stock" + errorREd,
                              "Stock",
                            );
                          }
                        }
                      }
                    : null,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 300,
              height: 50,
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
                    Icon(
                      Icons.shopping_cart_checkout,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Ventas",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                onPressed: btnVentaEnable
                    ? () async {
                        setState(
                          () {
                            btnVentaEnable = false;
                          },
                        );
                        await sincronizarVentas();
                        String errorREd = "";
                        if (isSincVentas == "Ok") {
                          showAlert(context, "Ventas sincronizadas", "Ventas");
                        } else {
                          if (isSincVentas == "Error de red") {
                            errorREd = ", error de red, verifique conectividad";
                            showAlertError(
                              context,
                              "No se pudo sincronizar Ventas" + errorREd,
                              "Ventas",
                            );
                          }
                        }
                      }
                    : null,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 300,
              height: 50,
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
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "GPS",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                onPressed: btnGpsEnable
                    ? () async {
                        setState(
                          () {
                            btnGpsEnable = false;
                          },
                        );
                        Position locationData = await activeteLocation();
                        String errorREd = "";
                        if (locationData.latitude == 0.0 ||
                            locationData.longitude == 0.0) {
                          isSincGps = "Error";
                        } else {
                          try {
                            http.Response? response =
                                await createRecordGeoLocation(
                                    locationData.latitude.toString(),
                                    locationData.longitude.toString(),
                                    codigo,
                                    empresa,
                                    "S");
                            Map<String, dynamic> res =
                                jsonDecode(response!.body);
                            if (res['code'] < 0) {
                              errorREd =
                                  ", error de red, verifique conectividad.";
                            } else {
                              isSincGps = "Ok";
                            }
                          } catch (e) {
                            errorREd =
                                ", error de red, verifique conectividad.";
                          }
                        }
                        if (isSincGps == "Ok") {
                          showAlert(context, "GPS sincronizado", "GPS");
                        } else {
                          if (isSincGps == "Error de red") {
                            errorREd =
                                ", error de red, verifique conectividad.";
                            showAlertError(context,
                                "No se pudo sincronizar GPS" + errorREd, "GPS");
                          } else {
                            errorREd =
                                ", active la ubicación y vuelva a lanzar.";
                            showAlertError(context,
                                "No se pudo sincronizar GPS" + errorREd, "GPS");
                          }
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
