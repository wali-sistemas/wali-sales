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
      // print ("itemsPedidoLocal: "); print (itemsPedidoLocal);
      if (GetStorage().read('pedidoGuardado') == null) {
        Map<String, dynamic> pedidoInicial = {};
        storage.write("pedidoGuardado", pedidoInicial);
        contar = true;
      } else {
        pedidoLocal = GetStorage().read('pedidoGuardado');
        contar = false;
      }

      // if(pedidoLocal['slpCode']!=usuario)
      // {
      //   print ("borrando itemsPedidoLocal");
      //   itemsPedidoLocal=List.empty();
      //   pedidoLocal = {};
      // }
    } else
      itemsPedidoLocal = List.empty();

    //print ("itemsPedidoLocal1: "); print (itemsPedidoLocal);

    // print ("items pendientes: ");print(itemsPedidoLocal.toString());
    // print ("usuario en items: ");print(pedidoLocal.toString());

    //if (itemsPedidoLocal.length >0 && pedidoLocal['slpCode']==usuario)

    //  if (itemsPedidoLocal.length >0 )
    // {
    if (GetStorage().read('estadoPedido') != null) {
      estadoPedido = GetStorage().read('estadoPedido');
    } else {
      estadoPedido = "desconocido";
    }

    if (estadoPedido == "nuevo") {
      setState(() {
        {
          itemCount = itemsPedidoLocal.length;
        }
      });
    }
    // }
    return Container(
      child: Stack(
        children: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              if (GetStorage().read('estadoPedido') != null) {
                if (GetStorage().read('estadoPedido') == "guardado") {
                  //print("estadoPedido:");
                  //print(estadoPedido);
                  storage.remove('itemsPedido');
                }
              }

              //storage.write('estadoPedido', 'nuevo');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PedidosPage()),
              );
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
