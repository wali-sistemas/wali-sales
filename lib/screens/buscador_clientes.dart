import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/pedidos_screen.dart';

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

  showAlertDialogItemsInShoppingCart(BuildContext context, String nit) {
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
                  if (GetStorage().read('itemsPedido') == null) {
                    storage.remove('itemsPedido');
                    storage.remove('pedidoGuardado');

                    storage.write('estadoPedido', 'nuevo');
                    storage.write('nit', _clientesBusqueda[index]['nit']);
                    storage.write(
                        'cardCode', _clientesBusqueda[index]['cardCode']);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PedidosPage(),
                      ),
                    );
                  } else {
                    pedidoLocal = GetStorage().read('pedido');
                    itemsPedidoLocal = GetStorage().read('itemsPedido');

                    if (pedidoLocal['cardCode'] !=
                            _clientesBusqueda[index]['cardCode'] &&
                        itemsPedidoLocal.length > 0) {
                      showAlertDialogItemsInShoppingCart(
                        context,
                        _clientesBusqueda[index]['cardCode'],
                      );
                    } else {
                      storage.write('estadoPedido', 'nuevo');
                      storage.write('nit', _clientesBusqueda[index]['nit']);
                      storage.write(
                          'cardCode', _clientesBusqueda[index]['cardCode']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PedidosPage(),
                        ),
                      );
                    }
                  }
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
            if (GetStorage().read('itemsPedido') == null) {
              storage.remove('itemsPedido');
              storage.remove('pedidoGuardado');

              storage.write('estadoPedido', 'nuevo');
              storage.write('nit', _clientesBusqueda2[index]['nit']);
              storage.write('cardCode', _clientesBusqueda2[index]['cardCode']);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PedidosPage(),
                ),
              );
            } else {
              pedidoLocal = GetStorage().read('pedido');
              itemsPedidoLocal = GetStorage().read('itemsPedido');

              if (GetStorage().read('estadoPedido') == 'guardado') {
                storage.write('nit', _clientesBusqueda2[index]['nit']);
                storage.write(
                    'cardCode', _clientesBusqueda2[index]['cardCode']);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PedidosPage(),
                  ),
                );
              } else {
                if (pedidoLocal['cardCode'] !=
                        _clientesBusqueda2[index]['cardCode'] &&
                    itemsPedidoLocal.length > 0) {
                  showAlertDialogItemsInShoppingCart(
                    context,
                    _clientesBusqueda2[index]['cardCode'],
                  );
                } else {
                  storage.write('estadoPedido', 'nuevo');
                  storage.write('nit', _clientesBusqueda2[index]['nit']);
                  storage.write(
                      'cardCode', _clientesBusqueda2[index]['cardCode']);
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
