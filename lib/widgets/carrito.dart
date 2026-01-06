import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/pedidos_screen.dart';

class CarritoPedido extends StatefulWidget {
  const CarritoPedido({super.key});

  @override
  State<CarritoPedido> createState() => _CarritoPedidoState();
}

class _CarritoPedidoState extends State<CarritoPedido> {
  final GetStorage storage = GetStorage();

  int itemCount = 0;

  @override
  void initState() {
    super.initState();
    _recalcularContador();
  }

  void _recalcularContador() {
    final items = storage.read('itemsPedido');
    final String estadoPedido =
        (storage.read('estadoPedido') ?? "desconocido").toString();

    final int newCount =
        (estadoPedido == "nuevo" && items is List) ? items.length : itemCount;

    if (newCount != itemCount) {
      setState(() => itemCount = newCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsPedido = storage.read('itemsPedido');
    final pedidoGuardado = storage.read('pedidoGuardado');
    final String estadoPedido =
        (storage.read('estadoPedido') ?? "desconocido").toString();

    final bool contar;
    if (itemsPedido != null) {
      if (pedidoGuardado == null) {
        storage.write("pedidoGuardado", <String, dynamic>{});
        contar = true;
      } else {
        contar = false;
      }
    } else {
      contar = false;
    }

    if (estadoPedido == "nuevo" && itemsPedido is List) {
      final int currentLen = itemsPedido.length;
      if (itemCount != currentLen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => itemCount = currentLen);
        });
      }
    }
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          color: Colors.white,
          onPressed: () {
            storage.remove("dirEnvio");

            final ep = storage.read('estadoPedido');
            if (ep != null && ep.toString() == "guardado") {
              storage.remove('itemsPedido');
            }

            final items = storage.read('itemsPedido');
            if (items != null) {
              storage.write('estadoPedido', 'nuevo');
              storage.remove('observaciones');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PedidosPage()),
              );
            }
          },
        ),
        if (itemCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                itemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
