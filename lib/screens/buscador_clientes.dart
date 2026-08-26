import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'package:productos_app/services/notifications_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

List clientesGuardados = [];
List<String> allNames = ['Cliente'];
List<String> allNames2 = ['Cliente'];
var mainColor = Color(0xff1B3954);
var textColor = Color(0xff727272);
var accentColor = Color(0xff16ADE1);
var whiteText = Color(0xffF5F5F5);

class CustomSearchDelegateClientes extends SearchDelegate {
  var suggestion = ['Cliente'];
  List<String> searchResult = [];
  List _clientesBusqueda = [];
  List _clientesBusqueda2 = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');
  Map<String, dynamic> pedidoLocal = {};
  List<dynamic> itemsPedidoLocal = [];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
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
          Icon(
            Icons.error,
            color: Colors.orange,
          ),
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
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void showConfirmVisitDialog(BuildContext context, dynamic cliente) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            final String cardCode = cliente['cardCode'].toString();
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
                          if (GetStorage().read('itemsPedido') == null) {
                            storage.remove('itemsPedido');
                            storage.remove('pedidoGuardado');

                            storage.write('estadoPedido', 'nuevo');
                            storage.write('nit', cliente['nit']);
                            storage.write('cardCode', cliente['cardCode']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PedidosPage(),
                              ),
                            );
                          } else {
                            pedidoLocal = GetStorage().read('pedido');
                            itemsPedidoLocal = GetStorage().read('itemsPedido');

                            if (GetStorage().read('estadoPedido') ==
                                'guardado') {
                              storage.write('nit', cliente['nit']);
                              storage.write('cardCode', cliente['cardCode']);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PedidosPage(),
                                ),
                              );
                            } else {
                              if (pedidoLocal['cardCode'] !=
                                      cliente['cardCode'] &&
                                  itemsPedidoLocal.length > 0) {
                                showAlertDialogItemsInShoppingCart(
                                  context,
                                  cliente['cardCode'],
                                );
                              } else {
                                storage.write('estadoPedido', 'nuevo');
                                storage.write('nit', cliente['nit']);
                                storage.write('cardCode', cliente['cardCode']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PedidosPage(),
                                  ),
                                );
                              }
                            }
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

                              try {
                                await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );
                              } catch (_) {}
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
                            if (res['code'] != 0) {
                              NotificationsService.showSnackbar(
                                res['content'] ??
                                    'No fue posible registrar la visita.',
                              );
                              if (context.mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                              return;
                            }

                            if (GetStorage().read('itemsPedido') == null) {
                              storage.remove('itemsPedido');
                              storage.remove('pedidoGuardado');

                              storage.write('estadoPedido', 'nuevo');
                              storage.write('nit', cliente['nit']);
                              storage.write('cardCode', cliente['cardCode']);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PedidosPage(),
                                ),
                              );
                            } else {
                              pedidoLocal = GetStorage().read('pedido');
                              itemsPedidoLocal =
                                  GetStorage().read('itemsPedido');

                              if (GetStorage().read('estadoPedido') ==
                                  'guardado') {
                                storage.write('nit', cliente['nit']);
                                storage.write('cardCode', cliente['cardCode']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PedidosPage(),
                                  ),
                                );
                              } else {
                                if (pedidoLocal['cardCode'] !=
                                        cliente['cardCode'] &&
                                    itemsPedidoLocal.length > 0) {
                                  showAlertDialogItemsInShoppingCart(
                                    context,
                                    cliente['cardCode'],
                                  );
                                } else {
                                  storage.write('estadoPedido', 'nuevo');
                                  storage.write('nit', cliente['nit']);
                                  storage.write(
                                      'cardCode', cliente['cardCode']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PedidosPage(),
                                    ),
                                  );
                                }
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

  @override
  Widget buildResults(BuildContext context) {
    if (GetStorage().read('datosClientes') == null) {
    } else {
      _clientesBusqueda.clear();
      clientesGuardados = GetStorage().read('datosClientes');
      clientesGuardados.forEach((k) {
        allNames.add(k['cardName'].toString().toLowerCase());
        if (k['cardName'].toLowerCase().contains(query.trim().toLowerCase()) ||
            k['cardCode'].toLowerCase().contains(query.trim().toLowerCase())) {
          _clientesBusqueda.add(k);
        }
      });
    }
    searchResult.clear();

    searchResult = allNames
        .where((element) =>
            element.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: _clientesBusqueda.length,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                _clientesBusqueda[index]['cardCode'] +
                    '\n' +
                    _clientesBusqueda[index]['cardName'],
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () {
                  showConfirmVisitDialog(context, _clientesBusqueda[index]);
                },
                label: const Text(''),
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    searchResult.clear();
    _clientesBusqueda2.clear();

    if (GetStorage().read('datosClientes') == null) {
    } else {
      clientesGuardados = GetStorage().read('datosClientes');
      clientesGuardados.forEach((k) {
        allNames2.add(k['cardName'].toString().toLowerCase());
        if (k['cardName'].toLowerCase().contains(query.trim().toLowerCase()) ||
            k['cardCode'].toLowerCase().contains(query.trim().toLowerCase())) {
          _clientesBusqueda2.add(k);
        }
      });
    }

    if (query == '') {
      _clientesBusqueda2 = [];
    }

    return ListView.builder(
      itemCount: _clientesBusqueda2.length,
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          if (query.isEmpty) {
            query = suggestion[index];
          }
        },
        leading: Icon(query.isEmpty ? Icons.history : Icons.search),
        trailing: TextButton.icon(
          onPressed: () {
            showConfirmVisitDialog(context, _clientesBusqueda2[index]);
          },
          label: const Text(''),
          icon: const Icon(Icons.add),
        ),
        title: RichText(
          text: TextSpan(
            text: _clientesBusqueda2[index]['cardName'],
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
