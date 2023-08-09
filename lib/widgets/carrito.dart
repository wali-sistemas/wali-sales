import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/pedidos_screen.dart';

class CarritoPedido extends StatelessWidget {

  int itemCount = 0;
  List<dynamic> itemsPedidoLocal = [];
  String? usuario=GetStorage().read('usuario');
  Map<String, dynamic> pedidoLocal = {};

  void addItemToCart() {
    itemCount++;
  }

  void removeItemFromCart() {
    if (itemCount > 0) {
      itemCount--;
    }
  }

  @override
  Widget build(BuildContext context) {

    if(GetStorage().read('itemsPedido')!=null) {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
      pedidoLocal = GetStorage().read('pedido');

      if(pedidoLocal['slpCode']!=usuario)
        {
          itemsPedidoLocal=List.empty();
          pedidoLocal = {};
        }

    }
    else itemsPedidoLocal=List.empty();


    if(GetStorage().read('pedido')!=null) {
      Map<String, dynamic> pedidoLocal = GetStorage().read('pedido');
    }

    print ("items pendientes: ");print(itemsPedidoLocal.toString());
    print ("usuario en items: ");print(pedidoLocal.toString());

    if (itemsPedidoLocal.length >0 && pedidoLocal['slpCode']==usuario)
      { itemCount=itemsPedidoLocal.length;}
    return Container( child: Stack(
      children: [
        IconButton(
          icon: Icon(Icons.shopping_cart),
          onPressed:  () {print ("ok");
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
    ),);
  }

}
