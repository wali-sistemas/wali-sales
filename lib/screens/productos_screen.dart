import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:productos_app/icomoon.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/buscador_productos.dart';
import 'package:productos_app/screens/screens.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({Key? key}) : super(key: key);

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final GetStorage storage = GetStorage();

  final String empresa = GetStorage().read('empresa');
  final String usuario = GetStorage().read('usuario');

  List _items = [];

  late final Future<void> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _listarItems();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(30, 129, 235, 1),
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onTap: () {
              storage.remove('observaciones');
              storage.remove('pedido');
              storage.remove('itemsPedido');
              storage.remove('dirEnvio');

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
              );
            },
          ),
          title: ListTile(
            onTap: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
            title: const Row(
              children: [
                Icon(Icons.search, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Buscar ítems',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                child: Text(
                  'Catálogo de productos',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _itemsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _itemsTab(BuildContext context) {
    return FutureBuilder<void>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SafeArea(
            child: Center(child: Text('Error cargando productos')),
          );
        }

        if (_items.isEmpty) {
          return const SafeArea(
            child: Center(child: Text('No hay productos disponibles')),
          );
        }

        return SafeArea(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    color: const Color.fromRGBO(250, 251, 253, 1),
                    child: ListTile(
                      title: Text(
                        item['itemName'],
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        'Sku: ${item['itemCode']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(item['pictureUrl']),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: item['pictureUrl'],
                          maxHeightDiskCache: 300,
                          maxWidthDiskCache: 300,
                          memCacheHeight: 300,
                          memCacheWidth: 300,
                          placeholder: (_, __) =>
                              const CircularProgressIndicator(),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          storage.write('index', index);

                          showDialog(
                            context: context,
                            builder: (_) => MyDialog(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _listarItems() async {
    final cached = GetStorage().read('items');
    if (cached != null) {
      _items = cached;
      return;
    }

    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/$empresa?slpcode=$usuario';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);
    final data = resp['content'];

    if (!mounted) return;

    setState(() {
      _items = data;
    });

    storage.write('items', data);
  }
}

class DetailScreen extends StatelessWidget {
  final String image;

  const DetailScreen(this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: 'imageHero',
            child: CachedNetworkImage(
              imageUrl: image,
              maxHeightDiskCache: 300,
              maxWidthDiskCache: 300,
              memCacheHeight: 300,
              memCacheWidth: 300,
              placeholder: (_, __) => const CircularProgressIndicator(),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.image_not_supported_outlined),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class MyDialog extends StatefulWidget {
  @override
  _MyDialogState createState() => new _MyDialogState();
}

class _MyDialogState extends State<MyDialog> {
  int index = 0;
  List _items = [];
  List _stock = [];
  List listaItems = [];
  List _inventario = [];

  final GetStorage storage = GetStorage();

  bool textoVisible = false;

  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> itemsPedido = [];

  String dropdownvalueBodega = 'Elija una bodega';
  final String empresa = GetStorage().read('empresa');
  String mensaje = "";

  bool btnSoldOutActivo = false;

  final NumberFormat numberFormat = NumberFormat.simpleCurrency();
  var whsCodeStockItem;

  String zona = "";
  final String usuario = GetStorage().read('usuario');

  List _stockFull = [];

  int idPedidoDb = 0;
  int idLocal = 0;
  int fullStock = 0;

  final Connectivity _connectivity = Connectivity();

  final Map<String, dynamic> itemTemp = {
    "quantity": "",
    "itemCode": "",
    "itemName": "",
    "group": "",
    "whsCode": "",
    "presentation": "",
    "price": "",
    "discountItem": "",
    "discountPorc": "",
    "iva": ""
  };

  final Map<String, dynamic> actualizarPedidoGuardado = {
    "id": "",
    "docNum": ""
  };

  late final Future<void> _itemsFuture;
  List _itemsGuardados = [];

  @override
  void initState() {
    super.initState();

    zona = (GetStorage().read('zona') ?? "01").toString();
    index = (GetStorage().read('index') ?? 0) as int;

    _itemsFuture = _ensureItemsLoaded();
  }

  @override
  void dispose() {
    cantidadController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  Future<void> _ensureItemsLoaded() async {
    final cached = GetStorage().read('items');
    if (cached == null) {
      await _listarItems();
    } else {
      _itemsGuardados = cached;
    }

    final sf = GetStorage().read('stockFull');
    if (sf != null) {
      _stockFull = sf;
    }

    _recalcularStock();
  }

  Future<void> _listarItems() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/$empresa';

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);
    final data = resp["content"];

    if (!mounted) return;

    setState(() {
      _items = data;
      _itemsGuardados = data;
    });

    storage.write('items', data);
  }

  void _recalcularStock() {
    if (_itemsGuardados.isEmpty || _stockFull.isEmpty) return;

    final List stockTemp = [];
    for (final j in _stockFull) {
      if (_itemsGuardados[index]["itemCode"] == j["itemCode"]) {
        stockTemp.add(j);
      }
    }

    _stock = stockTemp;

    if (_stock.isNotEmpty) {
      _inventario = _stock[0]['stockWarehouses'];
      fullStock = _stock[0]['stockFull'];
    }
  }

  Future<int> _getStockByItemAndWhsCode(String item, String whsCode) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
            empresa +
            '?itemcode=' +
            item +
            '&whscode=' +
            whsCode +
            '&slpcode=0';
    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);

    if (resp["code"] == 0) {
      final data = resp["content"];
      return data[0]['stockFull'];
    }
    return 0;
  }

  bool isDigit(String character) {
    return character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;
  }

  bool areAllCharactersNumbers(String text) {
    if (text.isEmpty) return false;
    for (int i = 0; i < text.length; i++) {
      if (!isDigit(text[i])) return false;
    }
    return true;
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<http.Response> _addItemSoldOut(String itemCode, String itemName,
      int quantity, String origen, String whsName) {
    const String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/add-item-sold-out';

    return http.post(
      Uri.parse(apiUrl),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          "itemCode": itemCode,
          "itemName": itemName,
          "quantity": quantity,
          "slpCode": usuario,
          "companyName": empresa,
          "origen": origen,
          "whsName": whsName,
        },
      ),
    );
  }

  void _setMensaje({
    required String msg,
    required bool visible,
    required bool soldOut,
  }) {
    setState(() {
      mensaje = msg;
      textoVisible = visible;
      btnSoldOutActivo = soldOut;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            backgroundColor: Colors.white,
            content: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (_itemsGuardados.isEmpty) {
          return const AlertDialog(
            backgroundColor: Colors.white,
            content: Text('No hay items cargados'),
          );
        }

        List<String> bodegas = const [''];
        bool isVisibleBod = false;

        final item = _itemsGuardados[index];

        if (item["grupo"] == 'LLANTAS' && item["marca"] == 'XCELINK') {
          bodegas = const ['Elija una bodega', 'CARTAGENA', 'CALI'];
          isVisibleBod = true;
        }

        if (item["subgrupo"] == 'LUBRICANTES' &&
            item["marca"] == 'REVO LUBRICANTES') {
          bodegas = const ['Elija una bodega', 'MEDELLÍN', 'BOGOTÁ'];
          isVisibleBod = true;
        }

        if (item["grupo"] == 'LLANTAS' && item["marca"] == 'TIMSUN') {
          bodegas = const [
            'Elija una bodega',
            'CARTAGENA',
            'CALI',
            'BOGOTÁ',
            'MEDELLÍN'
          ];
          isVisibleBod = true;
        }

        if (_inventario.isNotEmpty && !isVisibleBod) {
          num stockSuma = 0;
          for (final bodega in _inventario) {
            if (bodega['quantity'] > 0 && bodega['whsCode'] == zona) {
              whsCodeStockItem = bodega['whsCode'];
              fullStock = bodega['quantity'];
            } else {
              whsCodeStockItem = item["whsCode"];
              stockSuma = stockSuma + bodega['quantity'];
            }
          }
        }

        String precioTxt = numberFormat.format(
          item['price'] + (item['price'] * 0.19),
        );
        if (precioTxt.contains('.')) {
          precioTxt = precioTxt.substring(0, precioTxt.indexOf('.'));
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            item['itemName'],
            style: const TextStyle(fontSize: 14),
          ),
          actions: <Widget>[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Sku: ${item['itemCode']}'),
              ],
            ),
            Text('Stock: $fullStock'),
            Text('Precio Incl. IVA 19%: $precioTxt'),
            SizedBox(
              width: 250,
              child: isVisibleBod
                  ? DropdownButton<String>(
                      isExpanded: true,
                      value: dropdownvalueBodega.isNotEmpty
                          ? dropdownvalueBodega
                          : null,
                      onChanged: (String? newValue) async {
                        if (newValue == null) return;

                        dropdownvalueBodega = newValue;

                        var whsCode = '';
                        switch (dropdownvalueBodega) {
                          case 'CARTAGENA':
                            whsCode = (empresa == 'VARROC') ? '13' : '05';
                            break;
                          case 'CALI':
                            whsCode = '26';
                            break;
                          case 'MEDELLÍN':
                            if (item["grupo"] == 'LLANTAS' &&
                                item["marca"] == 'TIMSUN') {
                              whsCode = '60';
                            } else if (item["subgrupo"] == 'LUBRICANTES' &&
                                item["marca"] == 'REVO LUBRICANTES') {
                              whsCode = '01';
                            } else {
                              whsCode = '01';
                            }
                            break;
                          case 'BOGOTÁ':
                            whsCode = '35';
                            break;
                          default:
                            whsCode = '01';
                            break;
                        }

                        final int stock = await _getStockByItemAndWhsCode(
                          item['itemCode'],
                          whsCode,
                        );

                        if (!mounted) return;
                        setState(() {
                          mensaje = '';
                          textoVisible = false;
                          fullStock = stock;
                          whsCodeStockItem = whsCode;
                        });
                      },
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      items: bodegas.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              height: 35,
              child: TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                onChanged: (text) {
                  if (empresa == "REDPLAS") {
                    _setMensaje(msg: "", visible: false, soldOut: true);
                    return;
                  }

                  if (text.isEmpty) {
                    _setMensaje(msg: "", visible: false, soldOut: false);
                    return;
                  }

                  if (!areAllCharactersNumbers(text)) {
                    _setMensaje(
                        msg: "Cantidad debe ser numérica",
                        visible: true,
                        soldOut: false);
                    return;
                  }

                  final RegExp regex = RegExp(r'0+[1-9]');
                  if (regex.hasMatch(text)) {
                    _setMensaje(
                        msg: "Cantidad contiene 0 a la izq",
                        visible: true,
                        soldOut: false);
                    return;
                  }

                  final int cant = int.tryParse(text) ?? 0;
                  if (cant < 1) {
                    _setMensaje(
                        msg: "Cantidad debe ser mayor a 0",
                        visible: true,
                        soldOut: false);
                    return;
                  }

                  if (cant > fullStock) {
                    _setMensaje(msg: "", visible: false, soldOut: true);
                    return;
                  }

                  _setMensaje(msg: "", visible: false, soldOut: false);
                },
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Cant agotada',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  contentPadding: const EdgeInsets.all(5),
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Visibility(
              visible: textoVisible,
              child: Center(
                child: Material(
                  elevation: 5,
                  color: Colors.grey,
                  borderRadius: const BorderRadius.horizontal(),
                  child: SizedBox(
                    width: 300,
                    height: 30,
                    child: Center(
                      child: Text(
                        mensaje,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icomoon.soldOut),
                  color: Colors.black,
                  iconSize: 36,
                  onPressed: btnSoldOutActivo
                      ? () async {
                          final whsName =
                              dropdownvalueBodega == 'Elija una bodega'
                                  ? 'CEDI'
                                  : dropdownvalueBodega;

                          final http.Response response = await _addItemSoldOut(
                            item['itemCode'],
                            item['itemName'],
                            int.parse(cantidadController.text),
                            "CATALOGO",
                            whsName,
                          );

                          final bool res = jsonDecode(response.body);

                          if (!mounted) return;
                          setState(() {
                            mensaje = res
                                ? "Agotado reportado con éxito"
                                : "No se pudo reportar el agotado";
                            textoVisible = true;
                            btnSoldOutActivo = !res;
                            cantidadController.text = "";
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
