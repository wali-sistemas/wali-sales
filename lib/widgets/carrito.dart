import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/pedidos_screen.dart';

class CarritoPedido extends StatefulWidget {
  @override
  State<CarritoPedido> createState() => _CarritoPedidoState();
}

class _CarritoPedidoState extends State<CarritoPedido> {
  int itemCount = 0;
  bool contar = true;
  List<dynamic> itemsPedidoLocal = [];
  String estadoPedido = "";
  String? usuario = GetStorage().read('usuario');
  Map<String, dynamic> pedidoLocal = {};
  GetStorage storage = GetStorage();

  void addItemToCart() {
    if (contar) itemCount++;
  }

  void removeItemFromCart() {
    if (itemCount > 0) {
      itemCount--;
    }
  }

  @override
  Widget build(BuildContext context) {
    contar = true;
    if (GetStorage().read('pedido') != null) {
      Map<String, dynamic> pedidoLocal = GetStorage().read('pedido');
    }
    if (GetStorage().read('itemsPedido') != null) {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
      if (GetStorage().read('pedidoGuardado') == null) {
        Map<String, dynamic> pedidoInicial = {};
        storage.write("pedidoGuardado", pedidoInicial);
        contar = true;
      } else {
        pedidoLocal = GetStorage().read('pedidoGuardado');
        contar = false;
      }
    } else {
      itemsPedidoLocal = List.empty();
    }

    if (GetStorage().read('estadoPedido') != null) {
      estadoPedido = GetStorage().read('estadoPedido');
    } else {
      estadoPedido = "desconocido";
    }

    if (estadoPedido == "nuevo") {
      setState(
        () {
          {
            itemCount = itemsPedidoLocal.length;
          }
        },
      );
    }
    return Container(
      child: Stack(
        children: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            color: Colors.white,
            onPressed: () {
              storage.remove("dirEnvio");
              if (GetStorage().read('estadoPedido') != null) {
                if (GetStorage().read('estadoPedido') == "guardado") {
                  storage.remove('itemsPedido');
                }
              }
              if (GetStorage().read('itemsPedido') != null) {
                storage.write('estadoPedido', 'nuevo');
                storage.remove('observaciones');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PedidosPage()),
                );
              }
            },
          ),
          itemCount > 0
              ? Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }
}
