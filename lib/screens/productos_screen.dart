import 'package:flutter/material.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({Key? key}) : super(key: key);

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRODUCTOS'),
      ),
      body: Text(''),
    );
  }
}
