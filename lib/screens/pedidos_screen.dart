import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:productos_app/icomoon.dart';
import 'package:productos_app/screens/buscador_clientes.dart';
import 'package:productos_app/screens/screens.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'buscador_items.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:productos_app/models/DatabaseHelper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<dynamic> datosClientesArr = [];
  List _items = [];
  List listaItems = [];
  String empresa = GetStorage().read('empresa');
  String usuario = GetStorage().read('usuario');
  TextEditingController cantidadController = TextEditingController();
  GetStorage storage = GetStorage();
  List clientesGuardados = [];
  String dropdownvalue2 = 'Elija un destino';
  String nit = "";
  String urlImagenItem = "";

  late final Future<void> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _listarItems();
  }

  final pedidoJson = {
    "cardCode": "C890911260",
    "cardName": "TRANSALGAR SA",
    "nit": "890911260-7",
    "comments": "Prueba Sistemas",
    "companyName": "IGB",
    "numAtCard": "20230307C8909112602322276",
    "shipToCode": "CR 52 A 39 57",
    "payToCode": "CR 52 A 39 57",
    "slpCode": 22,
    "discountPercent": 0.0,
    "detailSalesOrder": [
      {
        "quantity": 2,
        "itemCode": "TY1003",
        "itemName": "(**)LLANTA 90-90-17 TL SPORT TOURING.TS692/TIMSUN_CONV",
        "whsCode": "01"
      },
      {
        "quantity": 3,
        "itemCode": "ED0023",
        "itemName": "AMORTIGUADOR TRAS NITROX NEGRO.DISCOVER 135 SUPREM",
        "whsCode": "05"
      }
    ]
  };

  final pedidoTemp = {
    "cardCode": "",
    "cardName": "",
    "nit": "",
    "comments": "",
    "companyName": "IGB",
    "numAtCard": "",
    "shipToCode": "",
    "payToCode": "",
    "slpCode": 0,
    "discountPercent": 0.0,
    "docTotal": ""
  };

  Future<void> _leerDatos() async {
    List clientesGuardados = [];
    clientesGuardados = GetStorage().read('datosClientes');
    datosClientesArr = clientesGuardados;
  }

  Future<void> _launchPhone(String phone) async {
    final Uri telefonoUrl = Uri.parse('tel:$phone');

    if (await canLaunchUrl(telefonoUrl)) {
      await launchUrl(telefonoUrl);
    } else {
      throw Exception('No se pudo abrir la aplicación de teléfono.');
    }
  }

  void _launchWhatsApp(String cellular) async {
    try {
      final Uri whatsappUri = Uri.parse(
          'https://wa.me/+57$cellular?text=${Uri.encodeComponent("Hola, Sr(Sra) soy su asesor de venta.")}');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        throw Exception('No se pudo abrir WhatsApp');
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 4,
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
                if (GetStorage().read('estadoPedido') == "nuevo") {
                  Navigator.pushReplacementNamed(context, 'home');
                } else {
                  showExitEditOrderConfirmation(
                    context,
                    "Estás editando un pedido. Si sales, perderás los cambios.\n\n¿Deseas salir definitivamente?",
                  );
                }
              },
            ),
            title: ListTile(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
              },
              title: const Text(
                'Buscar ítems',
                style: TextStyle(color: Colors.white),
              ),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(
                  child: Text(
                    'Cliente',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Tab(
                  child: Text(
                    'Items',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Tab(
                  child: Text(
                    'Detalle',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Tab(
                  child: Text(
                    'Total',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              formulario(context),
              items(context),
              detalle(context),
              total(context),
            ],
          ),
        ),
      ),
    );
  }

  void showExitEditOrderConfirmation(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
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
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                storage.remove('itemsPedido');

                Navigator.of(context, rootNavigator: true).pop();
                Navigator.pushReplacementNamed(context, 'home');
              },
              child: const Text('Si'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _listarItems() async {
    final cachedItems = GetStorage().read('items');

    if (cachedItems != null) {
      _items = cachedItems;
      return;
    }

    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/' +
            empresa +
            '?slpcode=' +
            usuario;

    final response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> resp = jsonDecode(response.body);
    final data = resp["content"];

    if (!mounted) return;

    setState(() {
      _items = data;
    });

    storage.write('items', data);
  }

  int findItemIndex(List<dynamic> list, dynamic item) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == item) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget formulario(BuildContext context) {
    var direccionesEnvio = ['Elija un destino'];
    var direccionesEnvioAsesor = ['Elija un destino'];

    _leerDatos();
    List _direcciones = [];
    var indice = 0;
    var i = 0;
    storage.remove('pedido');

    List direccionesTemp = [];
    final numberFormat = new NumberFormat.simpleCurrency();

    // DIRECCIONES DE ENVIO
    if (GetStorage().read('datosClientes') == null) {
    } else {
      clientesGuardados = GetStorage().read('datosClientes');
      if (GetStorage().read('cardCode') != null) {
        nit = GetStorage().read('cardCode');
      } else {
        nit = "El cliente no se encuentra registrado";
      }

      clientesGuardados.forEach((k) {
        if (nit == k['cardCode']) {
          direccionesTemp = k['addresses'];
        }
      });
    }

    for (var dir in direccionesTemp) {
      direccionesEnvio.add(dir['lineNum']);
      direccionesEnvioAsesor.add(dir['address']);
    }

    //BUSCAR CLIENTE CON EL NIT QUE TRAE DE PESTAÑA DE CLIENTES
    for (var cliente in datosClientesArr) {
      if (cliente['cardCode'] == GetStorage().read('cardCode')) {
        indice = i;
      }
      i++;
    }
    _direcciones = datosClientesArr[indice]['addresses'];
    String dirs = "";
    _direcciones.forEach(
      (element) {
        dirs = dirs + element['lineNum'] + '\n';
      },
    );

    pedidoTemp['cardCode'] = datosClientesArr[indice]['cardCode'].toString();
    pedidoTemp['cardName'] = datosClientesArr[indice]['cardName'].toString();
    pedidoTemp['nit'] = datosClientesArr[indice]['nit'].toString();
    pedidoTemp['companyName'] = "IGB";
    pedidoTemp['lineNum'] = _direcciones[0]['lineNum'].toString();
    pedidoTemp['shipToCode'] =
        datosClientesArr[indice]['addressToDef'].toString();
    pedidoTemp['payToCode'] =
        datosClientesArr[indice]['addressToDef'].toString();
    pedidoTemp['slpCode'] = GetStorage().read('usuario');
    pedidoTemp['discountPercent'] =
        datosClientesArr[indice]['discountCommercial'].toString();
    storage.write('pedido', pedidoTemp);

    String saldoTxt = numberFormat.format(datosClientesArr[indice]['balance']);
    if (saldoTxt.contains('.')) {
      int decimalIndex = saldoTxt.indexOf('.');
      saldoTxt = saldoTxt.substring(0, decimalIndex);
    }

    String cupoTxt = numberFormat.format(datosClientesArr[indice]['cupo']);
    if (cupoTxt.contains('.')) {
      int decimalIndex = cupoTxt.indexOf('.');
      cupoTxt = cupoTxt.substring(0, decimalIndex);
    }

    String pointsTxt = numberFormat.format(datosClientesArr[indice]['points']);
    if (pointsTxt.contains('.')) {
      int decimalIndex = pointsTxt.indexOf('.');
      pointsTxt = pointsTxt.substring(0, decimalIndex);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            elevation: 10,
            child: Container(
              color: Colors.white,
              child: SizedBox(
                width: 500,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          showSearch(
                            context: context,
                            delegate: CustomSearchDelegateClientes(),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.align_horizontal_left_rounded),
                                SizedBox(width: 5),
                                Text(
                                  datosClientesArr[indice]['nit'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              datosClientesArr[indice]['cardName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            Text('Cliente', textAlign: TextAlign.left),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        datosClientesArr[indice]['cellular'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Teléfono', textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        datosClientesArr[indice]['addressToDef'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Dirección', textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        datosClientesArr[indice]['location'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Ciudad', textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        datosClientesArr[indice]['wayToPay'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Forma de pago', textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        cupoTxt,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Cupo', textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        saldoTxt,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Saldo', textAlign: TextAlign.left),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        pointsTxt,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (empresa == "IGB")
                        Text('Puntos los Calidosos', textAlign: TextAlign.left),
                      if (empresa == "VARROC")
                        Text('Puntos en CLUB VIP', textAlign: TextAlign.left),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              _launchWhatsApp(
                                datosClientesArr[indice]['cellular'].toString(),
                              );
                            },
                            child: Row(
                              children: [
                                FaIcon(FontAwesomeIcons.whatsapp),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          IconButton(
                            icon: Icon(Icons.phone_outlined),
                            onPressed: () {
                              _launchPhone(
                                datosClientesArr[indice]['cellular'].toString(),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.mail_outline),
                            onPressed: () async {
                              final Email email = Email(
                                subject: "Asesor de ventas",
                                body: "Cordial saludo señor(ar), " +
                                    datosClientesArr[indice]['cardName'],
                                recipients: [datosClientesArr[indice]['email']],
                              );
                              try {
                                await FlutterEmailSender.send(email);
                              } catch (e) {}
                            },
                          ),
                        ],
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value:
                            dropdownvalue2.isNotEmpty ? dropdownvalue2 : null,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: direccionesEnvioAsesor.map(
                          (String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: Text(items),
                            );
                          },
                        ).toList(),
                        onChanged: (String? newValue) {
                          if (!mounted) return;
                          setState(
                            () {
                              int indice = findItemIndex(
                                  direccionesEnvioAsesor, newValue);
                              storage.write(
                                "dirEnvio",
                                direccionesEnvio[indice],
                              );
                              dropdownvalue2 = newValue!;
                            },
                          );
                        },
                      ),
                      Text(
                        'Dirección de destino',
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget items(BuildContext context) {
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
            child: Center(child: Text('Error cargando ítems')),
          );
        }

        if (_items.isEmpty) {
          return const SafeArea(
            child: Center(child: Text('No hay ítems para mostrar')),
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
                          urlImagenItem = item['pictureUrl'];
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
                          storage.write("index", index);

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

  @override
  Widget detalle(BuildContext context) {
    return DetallePedido();
  }

  @override
  Widget total(BuildContext context) {
    return TotalPedido();
  }
}

class MyDialog extends StatefulWidget {
  @override
  _MyDialogState createState() => new _MyDialogState();
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

class _MyDialogState extends State<MyDialog> {
  int index = 0;
  List _items = [];
  List _stock = [];
  List listaItems = [];
  List _inventario = [];

  final GetStorage storage = GetStorage();
  bool textoVisible = false;

  final TextEditingController cantidadController = TextEditingController();

  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> itemsPedido = [];

  String dropdownvalueBodega = 'Elija una bodega';
  final String empresa = GetStorage().read('empresa');
  String mensaje = "";

  bool btnAgregarActivo = false;
  bool btnSoldOutActivo = false;

  final NumberFormat numberFormat = NumberFormat.simpleCurrency();
  var whsCodeStockItem;

  String zona = "";
  final String usuario = GetStorage().read('usuario');

  List _stockFull = [];
  int idPedidoDb = 0;
  int idLocal = 0;
  int fullStock = 0;

  final FocusNode _focusNode = FocusNode();
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

  List _itemsGuardados = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    _initData();
  }

  Future<void> _initData() async {
    // zona
    zona = GetStorage().read('zona') ?? "01";
    // index
    index = GetStorage().read('index') ?? 0;
    // items
    await _listarItems();
    // itemsGuardados cache
    _itemsGuardados = (GetStorage().read('items') ?? []) as List;
    // stock
    _cargarStockDeItemActual();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cantidadController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cargarStockDeItemActual() {
    if (_itemsGuardados.isEmpty) return;

    final stockFullStorage = GetStorage().read('stockFull');
    if (stockFullStorage == null) return;

    _stockFull = stockFullStorage;

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

  Future<void> _listarItems() async {
    if (GetStorage().read('items') == null) {
      final String apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/items/' +
              empresa +
              '?slpcode=' +
              usuario;

      final response = await http.get(Uri.parse(apiUrl));
      final Map<String, dynamic> resp = jsonDecode(response.body);
      final data = resp["content"];

      if (!mounted) return;
      setState(() {
        _items = data;
      });

      storage.write('items', _items);
    } else {
      _items = GetStorage().read('items');
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

  Future<void> insertItemDb(Item newItem) async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final int insertedItemId = await dbHelper.insertItem(newItem);
    idLocal = insertedItemId;
  }

  Future<void> listarItemDb() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.getItems();
  }

  Future<void> listarPedidos() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.getPedidos();
  }

  Future<void> insertPedidoDb() async {
    final Pedido newPedido = Pedido(
      cardCode: "C12345",
      cardName: "Cliente Ejemplo",
      comments: "Pedido de prueba",
      companyName: "Empresa Ejemplo",
      numAtCard: "123456",
      shipToCode: "S123",
      payToCode: "P123",
      slpCode: 5,
      discountPercent: 0.1,
      docTotal: 100.0,
      lineNum: "L001",
      detailSalesOrder: "Detalle del pedido",
    );

    final DatabaseHelper dbHelper = DatabaseHelper();
    final int insertedPedidoId = await dbHelper.insertPedido(newPedido);
    idPedidoDb = insertedPedidoId;
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

  void _setMensajeEstado({
    required String msg,
    required bool visible,
    required bool agregar,
    required bool soldOut,
    String? limpiarCantidad,
  }) {
    setState(() {
      mensaje = msg;
      textoVisible = visible;
      btnAgregarActivo = agregar;
      btnSoldOutActivo = soldOut;
      if (limpiarCantidad != null) {
        cantidadController.text = limpiarCantidad;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_itemsGuardados.isEmpty) {
      return const AlertDialog(
        backgroundColor: Colors.white,
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    var bodegas = [''];
    bool isVisibleBod = false;
    bool alertItemAdd = false;
    int cantItemAdd = 0;

    // Activar seleccion de bodega para las llantas
    if (_itemsGuardados[index]["grupo"] == 'LLANTAS' &&
        _itemsGuardados[index]["marca"] == 'XCELINK') {
      bodegas = ['Elija una bodega', 'CARTAGENA', 'CALI'];
      isVisibleBod = true;
    }

    // Activar seleccion de bodega para los lubricantes REVO
    if (_itemsGuardados[index]["subgrupo"] == 'LUBRICANTES' &&
        _itemsGuardados[index]["marca"] == 'REVO LUBRICANTES') {
      bodegas = ['Elija una bodega', 'MEDELLÍN', 'BOGOTÁ', 'COTA'];
      isVisibleBod = true;
    }

    // Activar seleccion de bodega para las llantas TIMSUN
    if (_itemsGuardados[index]["grupo"] == 'LLANTAS' &&
        _itemsGuardados[index]["marca"] == 'TIMSUN') {
      bodegas = ['Elija una bodega', 'CARTAGENA', 'CALI', 'BOGOTÁ', 'MEDELLÍN'];
      isVisibleBod = true;
    }

    // Validar si ya existe el item en itemsPedido (solo para mostrar icono)
    final itemsPedidoSaved = GetStorage().read('itemsPedido');
    if (itemsPedidoSaved != null) {
      final List<dynamic> itemsAddDetail = itemsPedidoSaved;
      for (final j in itemsAddDetail) {
        if (_itemsGuardados[index]["itemCode"] == j["itemCode"]) {
          cantItemAdd = int.parse(j["quantity"]);
          alertItemAdd = true;
          break;
        }
      }
    }

    // Calcular stock si no requiere bodega seleccionable
    if (_stock.isNotEmpty && !isVisibleBod) {
      _inventario = _stock[0]['stockWarehouses'];
      fullStock = _stock[0]['stockFull'];
    }

    num stockSuma = 0;
    for (final bodega in _inventario) {
      if (bodega['quantity'] > 0 && bodega['whsCode'] == zona) {
        whsCodeStockItem = bodega['whsCode'];
        fullStock = bodega['quantity'];
      } else {
        whsCodeStockItem = _itemsGuardados[index]["whsCode"];
        stockSuma = stockSuma + bodega['quantity'];
      }
    }

    String precioTxt = numberFormat.format(_itemsGuardados[index]['price']);
    if (precioTxt.contains('.')) {
      precioTxt = precioTxt.substring(0, precioTxt.indexOf('.'));
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        _itemsGuardados[index]['itemName'],
        style: const TextStyle(fontSize: 14),
      ),
      actions: <Widget>[
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (alertItemAdd) Text('$cantItemAdd '),
            if (alertItemAdd) const Icon(Icons.verified_outlined),
            Text('          Sku: ' + _itemsGuardados[index]['itemCode']),
          ],
        ),
        Text('Stock: $fullStock'),
        Text('Precio: $precioTxt'),
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
                        if (_itemsGuardados[index]["grupo"] == 'LLANTAS' &&
                            _itemsGuardados[index]["marca"] == 'TIMSUN') {
                          whsCode = '45';
                        } else if (_itemsGuardados[index]["subgrupo"] ==
                                'LUBRICANTES' &&
                            _itemsGuardados[index]["marca"] ==
                                'REVO LUBRICANTES') {
                          whsCode = '01';
                        } else {
                          whsCode = '01';
                        }
                        break;
                      case 'BOGOTÁ':
                        whsCode = '35';
                        break;
                      case 'COTA':
                        whsCode = '55';
                        break;
                      default:
                        whsCode = '01';
                        break;
                    }

                    final int stock = await _getStockByItemAndWhsCode(
                      _itemsGuardados[index]['itemCode'],
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
                  items: bodegas.map((String value) {
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
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            onChanged: (text) {
              if (empresa == "REDPLAS") {
                _setMensajeEstado(
                  msg: "",
                  visible: false,
                  agregar: true,
                  soldOut: false,
                );
                return;
              }

              if (text.isEmpty) {
                _setMensajeEstado(
                  msg: "",
                  visible: false,
                  agregar: false,
                  soldOut: false,
                );
                return;
              }

              if (!areAllCharactersNumbers(text)) {
                _setMensajeEstado(
                  msg: "Cantidad debe ser numérica",
                  visible: true,
                  agregar: false,
                  soldOut: false,
                );
                return;
              }

              final regex = RegExp(r'^(0|[1-9][0-9]*)$');
              if (!regex.hasMatch(text)) {
                _setMensajeEstado(
                  msg: "Cantidad contiene 0 a la izq",
                  visible: true,
                  agregar: false,
                  soldOut: false,
                );
                return;
              }

              final int cant = int.tryParse(text) ?? 0;

              if (cant < 1) {
                _setMensajeEstado(
                  msg: "Cantidad debe ser mayor a 0",
                  visible: true,
                  agregar: false,
                  soldOut: false,
                );
                return;
              }

              if (cant > fullStock) {
                _setMensajeEstado(
                  msg: "Cantidad es mayor al stock",
                  visible: true,
                  agregar: false,
                  soldOut: true,
                );
                return;
              }

              _setMensajeEstado(
                msg: "",
                visible: false,
                agregar: true,
                soldOut: false,
              );
            },
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              contentPadding: const EdgeInsets.all(5),
              hintStyle: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
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
                      final whsName = dropdownvalueBodega == 'Elija una bodega'
                          ? 'CEDI'
                          : dropdownvalueBodega;

                      try {
                        final http.Response response = await _addItemSoldOut(
                          _itemsGuardados[index]['itemCode'],
                          _itemsGuardados[index]['itemName'],
                          int.parse(cantidadController.text),
                          "PEDIDO",
                          whsName,
                        );
                        final bool res = jsonDecode(response.body);

                        if (res) {
                          _setMensajeEstado(
                            msg: "Agotado reportado con éxito",
                            visible: true,
                            agregar: false,
                            soldOut: false,
                            limpiarCantidad: "",
                          );
                        } else {
                          _setMensajeEstado(
                            msg: "No se pudo reportar el agotado",
                            visible: true,
                            agregar: false,
                            soldOut: true,
                            limpiarCantidad: "",
                          );
                        }
                      } catch (_) {
                        _setMensajeEstado(
                          msg: "No se pudo reportar el agotado",
                          visible: true,
                          agregar: false,
                          soldOut: true,
                          limpiarCantidad: "",
                        );
                      }
                    }
                  : null,
            ),
            const SizedBox(width: 100),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.basketShopping),
              color: Colors.black,
              iconSize: 33,
              onPressed: btnAgregarActivo
                  ? () {
                      if (isVisibleBod &&
                          (dropdownvalueBodega.isEmpty ||
                              dropdownvalueBodega == 'Elija una bodega')) {
                        _setMensajeEstado(
                          msg: "Elija una bodega",
                          visible: true,
                          agregar: true,
                          soldOut: false,
                        );
                        return;
                      }

                      itemTemp["quantity"] = cantidadController.text;
                      itemTemp["itemCode"] = _itemsGuardados[index]["itemCode"];
                      itemTemp["itemName"] = _itemsGuardados[index]["itemName"];
                      itemTemp["group"] = _itemsGuardados[index]["grupo"];
                      itemTemp["presentation"] =
                          _itemsGuardados[index]["presentation"] ?? "";
                      itemTemp["price"] =
                          _itemsGuardados[index]["price"].toString();
                      itemTemp["discountItem"] =
                          _itemsGuardados[index]["discountItem"].toString();
                      itemTemp["discountPorc"] =
                          _itemsGuardados[index]["discountPorc"].toString();
                      itemTemp["whsCode"] = whsCodeStockItem == null
                          ? "01"
                          : whsCodeStockItem.toString();
                      itemTemp["iva"] =
                          _itemsGuardados[index]["iva"].toString();

                      itemsPedido.add(Map<String, dynamic>.from(itemTemp));

                      final int precioI = _itemsGuardados[index]["price"];
                      final double precioD = precioI.toDouble();
                      final int discountI =
                          _itemsGuardados[index]["discountPorc"];
                      final double discountD = discountI.toDouble();
                      final int discountItemI =
                          _itemsGuardados[index]["discountItem"];
                      final double discountItemD = discountItemI.toDouble();
                      final int ivaI = _itemsGuardados[index]["iva"];
                      final double ivaD = ivaI.toDouble();

                      final Item newItem = Item(
                        idPedido: idPedidoDb,
                        quantity: int.parse(cantidadController.text),
                        itemCode: _itemsGuardados[index]["itemCode"],
                        itemName: _itemsGuardados[index]["itemName"],
                        grupo: _itemsGuardados[index]["grupo"],
                        whsCode: whsCodeStockItem,
                        presentation: _itemsGuardados[index]["presentation"],
                        price: precioD,
                        discountItem: discountItemD,
                        discountPorc: discountD,
                        iva: ivaD,
                      );

                      insertItemDb(newItem);
                      listarItemDb();

                      final saved = GetStorage().read('itemsPedido');
                      if (saved == null) {
                        storage.write('itemsPedido', itemsPedido);
                      } else {
                        itemsPedidoLocal = saved;

                        int repetido = 0;
                        for (final j in itemsPedidoLocal) {
                          if (itemTemp["itemCode"] == j["itemCode"] &&
                              itemTemp["whsCode"] == j["whsCode"]) {
                            final int cant = int.parse(j["quantity"]!) +
                                int.parse(itemTemp["quantity"]!);
                            j["quantity"] = cant.toString();
                            repetido = 1;
                            break;
                          }
                        }

                        if (repetido == 0) {
                          itemsPedidoLocal
                              .add(Map<String, dynamic>.from(itemTemp));
                        }

                        storage.write('itemsPedido', itemsPedidoLocal);
                      }

                      storage.write('index', index);
                      Navigator.pop(context);
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class DetallePedido extends StatefulWidget {
  @override
  _DetallePedidoState createState() => new _DetallePedidoState();
}

class _DetallePedidoState extends State<DetallePedido> {
  List<dynamic> itemsPedidoLocal = [];
  List listaItems = [];
  num subtotalDetalle = 0;
  num iva = 0;
  num totalDetalle = 0;

  final NumberFormat numberFormat = NumberFormat.simpleCurrency();
  final GetStorage storage = GetStorage();

  List _stockFull2 = [];
  int fullStock = 0;
  dynamic stockItem;

  void borrarItemDetalle(String itemCode) {
    final items = GetStorage().read('itemsPedido');
    if (items == null) return;

    final List<dynamic> temp = List<dynamic>.from(items);

    temp.removeWhere((e) => e['itemCode'] == itemCode);

    storage.write('itemsPedido', temp);

    setState(() {
      itemsPedidoLocal = temp;
      listaItems = List.from(temp);
    });
  }

  void showAlertDetailItems(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Text("Atención!"),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NO"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  itemsPedidoLocal.clear();
                  listaItems.clear();
                });
                storage.remove('itemsPedido');

                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("SI"),
            ),
          ],
        );
      },
    );
  }

  void showAlertDetailSingleItem(
      BuildContext context, String itemCode, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Text("Atención!"),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NO"),
            ),
            ElevatedButton(
              onPressed: () {
                borrarItemDetalle(itemCode);
                Navigator.pop(context);
              },
              child: const Text("SI"),
            ),
          ],
        );
      },
    );
  }

  String _zonaActual() {
    final zona = GetStorage().read('zona');
    return (zona == null) ? "01" : zona.toString();
  }

  int _stockDisponibleParaItem(
      String itemCode, String zona, String whsFallback) {
    final stockFull = GetStorage().read('stockFull');
    if (stockFull == null) return 0;

    _stockFull2 = stockFull;

    // Busca el item
    final List matches =
        _stockFull2.where((j) => j["itemCode"] == itemCode).toList();

    if (matches.isEmpty) return 0;

    final List inventario = matches[0]['stockWarehouses'];
    int stockZona = 0;

    for (final bodega in inventario) {
      if (bodega['whsCode'] == zona && (bodega['quantity'] as num) > 0) {
        stockItem = bodega['whsCode'];
        stockZona = (bodega['quantity'] as num).toInt();
        break;
      }
    }

    if (stockZona == 0) {
      stockItem = whsFallback;
    }

    return stockZona;
  }

  void _incrementarCantidad(int index) {
    final String itemCode = listaItems[index]["itemCode"].toString();
    final String whsCode = listaItems[index]["whsCode"].toString();
    final String zona = _zonaActual();

    final int stockZona = _stockDisponibleParaItem(itemCode, zona, whsCode);

    final double actual =
        double.parse(listaItems[index]['quantity'].toString());

    if (stockZona > 0 && stockZona > actual) {
      final int nueva = actual.toInt() + 1;

      setState(() {
        listaItems[index]['quantity'] = nueva.toString();
      });

      storage.write('itemsPedido', listaItems);
      storage.write("cantidadItem", 0);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("No hay stock disponible"),
          actions: [
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );

    storage.write("cantidadItem", 0);
  }

  void _decrementarCantidad(int index) {
    final double actual =
        double.parse(listaItems[index]['quantity'].toString());

    if (actual > 1) {
      final int nueva = actual.toInt() - 1;

      setState(() {
        listaItems[index]['quantity'] = nueva.toString();
      });

      storage.write('itemsPedido', listaItems);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("La cantidad de ítems es menor a 1"),
          actions: [
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = GetStorage().read('itemsPedido');
    if (saved != null) {
      itemsPedidoLocal = List<dynamic>.from(saved);
      listaItems = List.from(itemsPedidoLocal);
    } else {
      itemsPedidoLocal = [];
      listaItems = [];
    }

    return SafeArea(
      child: listaItems.isEmpty
          ? const Text(
              "No se encontraron ítems agregados para mostar",
              textAlign: TextAlign.center,
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showAlertDetailItems(
                          context,
                          "¿Está seguro de borrar todos los ítems?",
                        );
                      },
                    ),
                    const Text(
                      'Borrar todo',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: listaItems.length,
                    itemBuilder: (context, index) {
                      final double price =
                          double.parse(listaItems[index]['price'].toString());
                      final double qty = double.parse(
                          listaItems[index]['quantity'].toString());
                      final double ivaPct =
                          double.parse(listaItems[index]['iva'].toString());

                      subtotalDetalle = price * qty;
                      iva = (ivaPct * subtotalDetalle) / 100;
                      totalDetalle = subtotalDetalle + iva;

                      String ivaTxt = numberFormat.format(iva);
                      ivaTxt = ivaTxt.substring(0, ivaTxt.length - 3);

                      String subtotalDetalleTxt =
                          numberFormat.format(subtotalDetalle);
                      subtotalDetalleTxt = subtotalDetalleTxt.substring(
                          0, subtotalDetalleTxt.length - 3);

                      String totalDetalleTxt =
                          numberFormat.format(totalDetalle);
                      totalDetalleTxt = totalDetalleTxt.substring(
                          0, totalDetalleTxt.length - 3);

                      final int precioInt = price.toInt();
                      String precioTxt = numberFormat.format(precioInt);
                      precioTxt = precioTxt.substring(0, precioTxt.length - 3);

                      return Card(
                        child: Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        showAlertDetailSingleItem(
                                          context,
                                          listaItems[index]['itemCode']
                                              .toString(),
                                          "¿Está seguro de borrar el ítem " +
                                              listaItems[index]['itemCode']
                                                  .toString() +
                                              "?",
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () =>
                                          _incrementarCantidad(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          _decrementarCantidad(index),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Text(
                                    listaItems[index]['itemName'].toString() +
                                        '\n' +
                                        'Sku: ' +
                                        listaItems[index]['itemCode']
                                            .toString() +
                                        '\n' +
                                        'Precio: ' +
                                        precioTxt +
                                        '\n' +
                                        'Cant: ' +
                                        listaItems[index]['quantity']
                                            .toString() +
                                        '\n' +
                                        'Bodega: ' +
                                        listaItems[index]['whsCode']
                                            .toString() +
                                        '\n' +
                                        'Subtotal: ' +
                                        subtotalDetalleTxt +
                                        '\n' +
                                        'Iva: ' +
                                        ivaTxt +
                                        '\n' +
                                        'Total: ' +
                                        totalDetalleTxt,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class TotalPedido extends StatefulWidget {
  @override
  _TotalPedidoState createState() => new _TotalPedidoState();
}

class _TotalPedidoState extends State<TotalPedido> {
  final TextEditingController observacionesController = TextEditingController();
  final GetStorage storage = GetStorage();
  final String empresa = GetStorage().read('empresa');
  final Connectivity _connectivity = Connectivity();

  bool cargando = false;
  bool btnPedidoActivo = false;
  bool btnGuardarActivo = false;

  @override
  void dispose() {
    observacionesController.dispose();
    super.dispose();
  }

  Future<http.Response> _enviarPedido(
      BuildContext context, Map<String, dynamic> pedidoFinal) {
    const String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-order';
    final dirEnvio = GetStorage().read('dirEnvio');

    final DateTime now = DateTime.now();
    String formatter = DateFormat('hhmm').format(now).replaceAll(":", "");
    final String fecha = DateFormat("yyyyMMdd").format(now);

    String numAtCard;
    final pedidoGuardado = GetStorage().read('pedidoGuardado');

    if (pedidoGuardado == null ||
        (pedidoGuardado is Map && pedidoGuardado.isEmpty)) {
      numAtCard = fecha + pedidoFinal['cardCode'].toString() + formatter;
    } else {
      numAtCard = fecha +
          pedidoFinal['cardCode'].toString() +
          pedidoGuardado['id'].toString();
    }

    final DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.deleteAllItemsP();
    dbHelper.deleteAllItems();

    return http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          'cardCode': pedidoFinal['cardCode'],
          "comments": observacionesController.text,
          "companyName": empresa,
          "numAtCard": numAtCard,
          "shipToCode": dirEnvio,
          "payToCode": pedidoFinal['payToCode'],
          "slpCode": pedidoFinal['slpCode'],
          "discountPercent": pedidoFinal['discountPercent'].toString(),
          "docTotal": pedidoFinal['docTotal'],
          "lineNum": pedidoFinal['lineNum'],
          "detailSalesOrder": GetStorage().read('itemsPedido'),
        },
      ),
    );
  }

  Future<http.Response> _guardarPedido(
    BuildContext context,
    Map<String, dynamic> pedidoFinal,
  ) {
    const String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/save-order';
    final dirEnvio = GetStorage().read('dirEnvio');

    final DateTime now = DateTime.now();
    String formatter = DateFormat('hhmm').format(now).replaceAll(":", "");
    final String fecha = DateFormat("yyyyMMdd").format(now);
    final String numAtCard =
        fecha + pedidoFinal['cardCode'].toString() + formatter;

    return http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          "cardCode": pedidoFinal['cardCode'],
          "comments": observacionesController.text,
          "companyName": empresa,
          "numAtCard": numAtCard,
          "status": "G",
          "shipToCode": dirEnvio,
          "payToCode": pedidoFinal['payToCode'],
          "slpCode": pedidoFinal['slpCode'],
          "discountPercent": pedidoFinal['discountPercent'].toString(),
          "docTotal": pedidoFinal['docTotal'],
          "assignedShipToCode": null,
          "lineNum": pedidoFinal['lineNum'],
          "cardName": pedidoFinal['cardName'],
          "detailSalesOrderSave": GetStorage().read('itemsPedido'),
        },
      ),
    );
  }

  int restarStock(String item, String bodegaB, int cantidad) {
    final stockFull = GetStorage().read('stockFull');
    if (stockFull == null) return 0;

    final List _stockFull = List.from(stockFull);

    for (final stock in _stockFull) {
      if (stock['itemCode'] == item) {
        for (final bodega in stock['stockWarehouses']) {
          if (bodega['whsCode'] == bodegaB) {
            bodega['quantity'] = bodega['quantity'] - cantidad;
          }
        }
      }
    }

    storage.write("stockFull", _stockFull);
    return 1;
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void showAlertError(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error!'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showAlertErrorDir(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Text('Atención!'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() {
        btnPedidoActivo = false;
        btnGuardarActivo = false;
      });
    });
  }

  void showAlertPedidoEnviado(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Muy bien'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                storage.remove('observaciones');
                storage.remove("pedido");
                storage.remove("itemsPedido");
                storage.remove("dirEnvio");
                storage.remove("pedidoGuardado");
                storage.write('estadoPedido', 'nuevo');

                final DatabaseHelper dbHelper = DatabaseHelper();
                dbHelper.deleteAllItemsP();
                dbHelper.deleteAllItems();

                requestStoragePermission();
                deleteAppData();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showAlertConfirmOrderForSave(
      BuildContext context,
      Map<String, dynamic> pedidoFinal,
      bool btnConfirmarEnvio,
      String message,
      Position locationData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            bool isProcessing = false;

            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.error, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("Atención!"),
                ],
              ),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: btnConfirmarEnvio
                      ? () {
                          setStateDialog(() => btnConfirmarEnvio = false);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  onPressed: btnConfirmarEnvio && !isProcessing
                      ? () async {
                          setStateDialog(() {
                            isProcessing = true;
                            btnConfirmarEnvio = false;
                            message = 'Guardando pedido. Por favor espere...';
                          });

                          final String codigo = pedidoFinal["slpCode"];
                          final int slpInt = int.parse(codigo);
                          final String descS = pedidoFinal["discountPercent"];
                          final double descD = double.parse(descS);
                          final String totS = pedidoFinal["docTotal"];
                          final double totD = double.parse(totS);

                          final Pedido pedidoF = Pedido(
                            cardCode: pedidoFinal["cardCode"],
                            cardName: pedidoFinal["cardName"],
                            comments: pedidoFinal["comments"],
                            companyName: pedidoFinal["companyName"],
                            numAtCard: pedidoFinal["numAtCard"],
                            shipToCode: pedidoFinal["shipToCode"],
                            payToCode: pedidoFinal["payToCode"],
                            slpCode: slpInt,
                            discountPercent: descD,
                            docTotal: totD,
                            lineNum: pedidoFinal["lineNum"],
                            detailSalesOrder: "Detalle del pedido",
                          );

                          insertPedidoDb(pedidoF);
                          listarPedidos();

                          if (mounted) {
                            setState(() => cargando = true);
                          }

                          try {
                            final http.Response response =
                                await _guardarPedido(context, pedidoFinal);
                            final Map<String, dynamic> resultado =
                                jsonDecode(response.body);

                            if (response.statusCode == 200 &&
                                resultado['content'] != "") {
                              final http.Response responseGeo =
                                  await createRecordGeoLocation(
                                locationData.latitude.toString(),
                                locationData.longitude.toString(),
                                GetStorage().read('usuario'),
                                empresa,
                                'G',
                              );

                              final Map<String, dynamic> res =
                                  jsonDecode(responseGeo.body);

                              if (res['code'] == 0) {
                                Navigator.pop(context);

                                showAlertPedidoEnviado(
                                  context,
                                  "Pedido Guardado: ${resultado['content']}",
                                );

                                final pg = GetStorage().read('pedidoGuardado');
                                if (pg != null) {
                                  try {
                                    actualizarEstadoPed(
                                        int.parse(pg['id']), 0, 'C');
                                  } catch (e) {}
                                }
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'El servicio no responde, contacte al administrador',
                                  colorText: Colors.red,
                                  backgroundColor: Colors.white,
                                );
                              }
                            } else {
                              Get.snackbar(
                                'Error',
                                'No se pudo guardar el pedido',
                                colorText: Colors.red,
                                backgroundColor: Colors.white,
                              );
                            }
                          } catch (_) {
                            Get.snackbar(
                              'Error',
                              'El servicio no responde, contacte al administrador',
                              colorText: Colors.red,
                              backgroundColor: Colors.white,
                            );
                          } finally {
                            setStateDialog(() => isProcessing = false);
                          }
                        }
                      : null,
                  child: const Text("SI"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() => btnGuardarActivo = false);
    });
  }

  void showAlertConfirmOrder(
      BuildContext context,
      Map<String, dynamic> pedidoFinal,
      bool btnConfirmarEnvio,
      String message,
      Position locationData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            bool isProcessing = false;

            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.error, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("Atención!"),
                ],
              ),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: btnConfirmarEnvio
                      ? () {
                          setStateDialog(() => btnConfirmarEnvio = false);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  onPressed: btnConfirmarEnvio && !isProcessing
                      ? () async {
                          setStateDialog(() {
                            isProcessing = true;
                            btnConfirmarEnvio = false;
                            message = 'Procesando pedido. Por favor espere...';
                          });

                          if (mounted) {
                            setState(() => cargando = true);
                          }

                          try {
                            final http.Response response =
                                await _enviarPedido(context, pedidoFinal);
                            final Map<String, dynamic> resultado =
                                jsonDecode(response.body);

                            if (response.statusCode == 200 &&
                                resultado['content'] != "") {
                              final http.Response responseGeo =
                                  await createRecordGeoLocation(
                                locationData.latitude.toString(),
                                locationData.longitude.toString(),
                                GetStorage().read('usuario'),
                                empresa,
                                'G',
                              );

                              final Map<String, dynamic> res =
                                  jsonDecode(responseGeo.body);

                              if (res['code'] == 0) {
                                Navigator.pop(context);

                                showAlertPedidoEnviado(
                                  context,
                                  "Pedido: ${resultado['content']}",
                                );

                                final pg = GetStorage()
                                    .read('actualizarPedidoGuardado');

                                if (pg != null) {
                                  try {
                                    await actualizarEstadoPed(
                                        int.parse(pg['id']),
                                        resultado['content'],
                                        'F');
                                  } catch (e) {}
                                }
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'El servicio no responde, contacte al administrador',
                                  colorText: Colors.red,
                                  backgroundColor: Colors.white,
                                );
                              }
                            } else {
                              Get.snackbar(
                                'Error',
                                'No se pudo crear el pedido',
                                colorText: Colors.red,
                                backgroundColor: Colors.white,
                              );
                            }
                          } catch (_) {
                            Get.snackbar(
                              'Error',
                              'El servicio no responde, contacte al administrador',
                              colorText: Colors.red,
                              backgroundColor: Colors.white,
                            );
                          } finally {
                            setStateDialog(() => isProcessing = false);
                          }
                        }
                      : null,
                  child: const Text("SI"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() => btnPedidoActivo = false);
    });
  }

  Future<void> listarPedidos() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.getPedidos();
  }

  Future<bool> buscarClientePedido(String cardCode) async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final List<Pedido> pedidos = await dbHelper.getPedidos();

    for (final Pedido pedido in pedidos) {
      if (pedido.cardCode == cardCode) return true;
    }
    return false;
  }

  Future<void> insertPedidoDb(Pedido pedidoFinal) async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.insertPedido(pedidoFinal);
  }

  Future<void> actualizarEstadoPed(int idP, int docNum, String status) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/process-saved-order/' +
            empresa +
            '?id=' +
            idP.toString() +
            '&docNum=' +
            docNum.toString() +
            '&status=' +
            status;

    await http.get(Uri.parse(apiUrl));
  }

  Future<void> requestStoragePermission() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
  }

  Future<void> deleteAppData() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final dir = Directory(directory.path);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
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

      return await Geolocator.getCurrentPosition(
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

  Future<http.Response> createRecordGeoLocation(
    String latitude,
    String longitude,
    String slpCode,
    String companyName,
    String docType,
  ) {
    const String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-record-geo-location';

    return http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
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

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat.simpleCurrency();

    if (GetStorage().read('pedido') == null) {
      return const Text("Sin ítems para pedido");
    }

    Map<String, dynamic> pedidoFinal = GetStorage().read('pedido');

    final pedidoGuardado = GetStorage().read('pedidoGuardado');
    if (pedidoGuardado != null) {
      final Map<String, dynamic> pedidoFinalG = pedidoGuardado;
      pedidoFinal['comments'] = pedidoFinalG['comments'] ?? '';
    }

    List<dynamic> itemsPedidoLocal = [];
    List itemsGuardados = [];
    int cantidadItems = 0;
    num subtotal = 0;

    if (GetStorage().read('observaciones') != null) {
      final String obs = GetStorage().read('observaciones');
      observacionesController.text = obs;
    }

    if (GetStorage().read('itemsPedido') != null) {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
      cantidadItems = itemsPedidoLocal.length;
    }

    if (GetStorage().read('items') != null && itemsPedidoLocal.isNotEmpty) {
      itemsGuardados = GetStorage().read('items');

      for (final j in itemsPedidoLocal) {
        for (final k in itemsGuardados) {
          final double cantidadQ = double.parse(j['quantity']);
          if (k['itemCode'] == j['itemCode']) {
            subtotal = subtotal + k['price'] * cantidadQ;
          }
        }
      }
    }

    double iva = 0.0;
    for (final element in itemsPedidoLocal) {
      final subt =
          double.parse(element["price"]) * double.parse(element["quantity"]);
      final ivaTemp = (double.parse(element["iva"].toString()) * subt) / 100;
      iva += ivaTemp;
    }

    String ivaTxt = numberFormat.format(iva);
    String subtotalTxt = numberFormat.format(subtotal);

    String descuento = pedidoFinal['discountPercent'];
    String estadoPedido = "";

    final double total = subtotal -
        (subtotal * (double.parse(descuento).toInt() / 100)) +
        (iva - (iva * (double.parse(descuento).toInt() / 100)));

    if (subtotalTxt.contains('.')) {
      subtotalTxt = subtotalTxt.substring(0, subtotalTxt.indexOf('.'));
    }
    if (descuento.contains('.')) {
      descuento = descuento.substring(0, descuento.indexOf('.'));
    }

    ivaTxt = numberFormat.format(iva - (iva * (int.parse(descuento) / 100)));
    if (ivaTxt.contains('.')) {
      ivaTxt = ivaTxt.substring(0, ivaTxt.indexOf('.'));
    }

    String totalDocTxt = numberFormat.format(
      subtotal -
          (subtotal * (double.parse(descuento).toInt() / 100)) +
          (iva - (iva * (double.parse(descuento).toInt() / 100))),
    );
    if (totalDocTxt.contains('.')) {
      totalDocTxt = totalDocTxt.substring(0, totalDocTxt.indexOf('.'));
    }

    if (pedidoFinal['comments'] != null) {
      if (GetStorage().read('estadoPedido') != null) {
        estadoPedido = GetStorage().read('estadoPedido');
      } else {
        estadoPedido = "desconocido";
      }

      if (estadoPedido == "nuevo") {
        storage.remove('observaciones');
      }

      if (estadoPedido == "guardado") {
        observacionesController.text = pedidoFinal['comments'].toString();
      }
    }

    pedidoFinal['docTotal'] = total.toString();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            elevation: 10,
            child: Container(
              color: Colors.white,
              child: SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${pedidoFinal['nit']} - ${pedidoFinal['cardName']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Cant de ítems: $cantidadItems",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Subtotal: $subtotalTxt",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Descuento: %$descuento",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Iva: $ivaTxt",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Total: $totalDocTxt",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Observaciones:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          maxLines: 7,
                          controller: observacionesController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onChanged: (_) {
                            pedidoFinal['comments'] =
                                observacionesController.text;
                            storage.write(
                                "observaciones", observacionesController.text);
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.all(15),
                            hintStyle: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledColor: Colors.grey,
                    elevation: 0,
                    color: const Color.fromRGBO(30, 129, 235, 1),
                    onPressed: btnPedidoActivo
                        ? null
                        : () async {
                            // Quita el foco y cierra el teclado
                            FocusScope.of(context).unfocus();

                            storage.write('estadoPedido', 'editado');
                            setState(() => btnPedidoActivo = true);

                            final dir = GetStorage().read('dirEnvio');
                            final items = GetStorage().read('itemsPedido');

                            if (dir == null ||
                                dir == "" ||
                                dir == "Elija un destino") {
                              showAlertErrorDir(
                                context,
                                "Obligatorio seleccionar la dirección de destino.",
                              );
                              return;
                            }

                            if (items == null || items == "") {
                              showAlertErrorDir(
                                context,
                                "Obligatorio agregar ítems en detalle.",
                              );
                              return;
                            }

                            final Position locationData =
                                await activeteLocation();
                            if (locationData.latitude == 0.0 ||
                                locationData.longitude == 0.0) {
                              showAlertErrorDir(
                                context,
                                "Active la ubicación del móvil, y presione de nuevo guardar pedido.",
                              );
                              Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );
                              return;
                            }

                            showAlertConfirmOrder(
                              context,
                              pedidoFinal,
                              true,
                              "¿Está seguro que deseea enviar el pedido?",
                              locationData,
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        btnPedidoActivo ? 'Espere' : 'Enviar Pedido',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledColor: Colors.grey,
                    elevation: 0,
                    color: const Color.fromRGBO(30, 129, 235, 1),
                    onPressed: btnGuardarActivo
                        ? null
                        : () async {
                            // Quita el foco y cierra el teclado
                            FocusScope.of(context).unfocus();

                            storage.write('estadoPedido', 'editado');
                            setState(() => btnGuardarActivo = true);

                            final dir = GetStorage().read('dirEnvio');
                            final items = GetStorage().read('itemsPedido');

                            if (dir == null ||
                                dir == "" ||
                                dir == "Elija un destino") {
                              showAlertErrorDir(
                                context,
                                "Obligatorio seleccionar la dirección de destino.",
                              );
                              return;
                            }

                            if (items == null || items == "") {
                              showAlertErrorDir(
                                context,
                                "Obligatorio agregar ítems en detalle.",
                              );
                              return;
                            }

                            final Position locationData =
                                await activeteLocation();
                            if (locationData.latitude == 0.0 ||
                                locationData.longitude == 0.0) {
                              showAlertErrorDir(
                                context,
                                "Active la ubicación del móvil, y presione de nuevo enviar pedido.",
                              );
                              Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );
                              return;
                            }

                            showAlertConfirmOrderForSave(
                              context,
                              pedidoFinal,
                              true,
                              "¿Está seguro que deseea guardar el pedido?",
                              locationData,
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        btnGuardarActivo ? 'Espere' : 'Guardar Pedido',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
