import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:productos_app/screens/screens.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'buscador_items.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:productos_app/models/DatabaseHelper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

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
    final telefonoUrl = 'tel:$phone';
    if (await canLaunch(telefonoUrl)) {
      await launch(telefonoUrl);
    } else {
      throw 'No se pudo abrir la aplicación de teléfono.';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Color.fromRGBO(30, 129, 235, 1),
            leading: GestureDetector(
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
              onTap: () {
                if (GetStorage().read('estadoPedido') == "guardado") {
                  storage.remove('itemsPedido');
                }
                Navigator.pushReplacementNamed(context, 'home');
              },
            ),
            title: ListTile(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
              },
              title: Text(
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
              total(context)
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _listarItems() async {
    if (GetStorage().read('items') == null) {
      final String apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/items/' +
              empresa +
              '?slpcode=' +
              usuario;
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final data = resp["content"];
      if (!mounted) return;
      setState(() {
        _items = data;

        /// GUARDAR EN SHAREDPREFERENCES MIENTRAS SE HACE CON SQL
        //String itemsG = jsonEncode(_items);
        storage.write('items', _items);
        //_guardarItems();
      });
    } else {
      _items = GetStorage().read('items');
    }
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

    /// DIRECCIONES DE ENVIO
    if (GetStorage().read('datosClientes') == null) {
    } else {
      /////BUSCAR nit en lista de clientes para hallar direcciones de envio
      // clientesGuardados=GetStorage().read('datosClientes');
      // if (GetStorage().read('nit')!=null)
      //   nit=GetStorage().read('nit');
      // else nit="no exite nit";
      //
      // clientesGuardados.forEach((k) {
      //   print ("NIT2: "); print (k['nit']);
      //   if(nit==k['nit'])
      //   { print ("Nitencontrado: ");
      //     direccionesTemp=k['addresses'];}
      // });

      clientesGuardados = GetStorage().read('datosClientes');
      if (GetStorage().read('cardCode') != null) {
        nit = GetStorage().read('cardCode');
      } else {
        nit = "no exite nit";
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

    ///
    /// SI EL PEDIDO ES GUARDADO, MOSTRAR LINENUM
    // if (GetStorage().read('pedidoGuardado') != null)
    // {
    //   Map<String, dynamic> pedidoFinalG = GetStorage().read('pedidoGuardado');
    //    direccionesEnvioAsesor.clear();
    //    direccionesEnvioAsesor.add('Elija un destino');
    //   direccionesEnvioAsesor.add(pedidoFinalG['lineNum'] ?? 'Sin dirección');
    //
    // }

    //BUSCAR CLIENTE CON EL NIT QUE TRAE DE PESTAÑA DE CLIENTES
    for (var cliente in datosClientesArr) {
      if (cliente['cardCode'] == GetStorage().read('cardCode')) {
        indice = i;
      }
      i++;
    }
    _direcciones = datosClientesArr[indice]['addresses'];
    String dirs = "";
    _direcciones.forEach((element) {
      dirs = dirs + element['lineNum'] + '\n';
    });

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
                      Text(
                        datosClientesArr[indice]['nit'].toString() +
                            ' - ' +
                            datosClientesArr[indice]['cardName'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Cliente', textAlign: TextAlign.left),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.phone_outlined),
                            onPressed: () {
                              _launchPhone(datosClientesArr[indice]['cellular']
                                  .toString());
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
                              } catch (error) {
                                print('Error al abrir el correo: $error');
                              }
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
                                  "dirEnvio", direccionesEnvio[indice]);
                              //pedidoFinal['shipToCode']=newValue;
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
    _listarItems();
    return SafeArea(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(1),
              child: Container(
                color: Color.fromRGBO(250, 251, 253, 1),
                child: ListTile(
                  title: Text(
                    _items[index]['itemName'],
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    "Sku: " + _items[index]['itemCode'],
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  leading: GestureDetector(
                    onTap: () {
                      urlImagenItem = _items[index]['pictureUrl'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            return DetailScreen(_items[index]['pictureUrl']);
                          },
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: _items[index]['pictureUrl'],
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.wallpaper),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) {
                          storage.write("index", index);
                          return MyDialog();
                        },
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
  const DetailScreen(this.image, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: 'imageHero',
            child: Image.network(
              image,
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
  GetStorage storage = GetStorage();
  bool textoVisible = false;
  TextEditingController cantidadController = TextEditingController();
  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> itemsPedido = [];
  String dropdownvalueBodega = 'Elija una bodega';
  String empresa = GetStorage().read('empresa');
  String mensaje = "";
  bool btnAgregarActivo = false;
  final numberFormat = new NumberFormat.simpleCurrency();
  var whsCodeStockItem;
  String zona = "";
  String usuario = GetStorage().read('usuario');
  List _stockFull = [];
  int idPedidoDb = 0;
  int idLocal = 0;
  int fullStock = 0;
  FocusNode _focusNode = FocusNode();

  Connectivity _connectivity = Connectivity();
  final itemTemp = {
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
  final actualizarPedidoGuardado = {"id": "", "docNum": ""};

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  Future<void> _listarItems() async {
    if (GetStorage().read('items') == null) {
      final String apiUrl =
          'http://wali.igbcolombia.com:8080/manager/res/app/items/' +
              empresa +
              '?slpcode=' +
              usuario;
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final data = resp["content"];
      if (!mounted) return;
      setState(
        () {
          _items = data;

          /// GUARDAR EN SHAREDPREFERENCES MIENTRAS SE HACE CON SQL
          //String itemsG = jsonEncode(_items);
          storage.write('items', _items);
          //_guardarItems();
        },
      );
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
    Map<String, dynamic> resp = jsonDecode(response.body);
    final codigoError = resp["code"];
    if (codigoError == 0) {
      final data = resp["content"];
      return data[0]['stockFull'];
    } else {
      return 0;
    }
  }

  bool isDigit(String character) {
    return character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;
  }

  bool areAllCharactersNumbers(String text) {
    if (text == null || text.isEmpty) {
      return false;
    }

    for (int i = 0; i < text.length; i++) {
      if (!isDigit(text[i])) {
        return false;
      }
    }
    return true;
  }

  Future<void> insertItemDb(Item newItem) async {
    // Supongamos que tienes un objeto de tipo Item que quieres insertar en la base de datos
    // Insertar el nuevo item en la base de datos
    DatabaseHelper dbHelper = DatabaseHelper();
    int insertedItemId = await dbHelper.insertItem(newItem);
    idLocal = insertedItemId;
    if (insertedItemId != null && insertedItemId > 0) {
      //print("El item ha sido insertado con éxito con el ID: $insertedItemId");
    }
  }

  Future<void> listarItemDb() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Item> items = await dbHelper.getItems();

    if (items.isNotEmpty) {
      for (Item item in items) {
        // print("ID: ${item.id}");
        // print("ID Pedido: ${item.idPedido}");
        // print("Quantity: ${item.quantity}");
        // print("--------------------------");
      }
    }
  }

  Future<void> listarPedidos() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Pedido> pedidos = await dbHelper.getPedidos();

    if (pedidos.isNotEmpty) {
      for (Pedido pedido in pedidos) {
        //print("ID: ${pedido.id}");
        //print("Cardcode: ${pedido.cardCode}");
        //print("Nombre: ${pedido.cardName}");
        // ... Mostrar los demás atributos del item ...
        //print("--------------------------");
      }
    }
  }

  Future<void> insertPedidoDb() async {
    Pedido newPedido = Pedido(
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

    // Insertar el nuevo pedido en la base de datos y obtener el ID asignado
    DatabaseHelper dbHelper = DatabaseHelper();
    int insertedPedidoId = await dbHelper.insertPedido(newPedido);

    if (insertedPedidoId != null && insertedPedidoId > 0) {
      //print("El pedido ha sido insertado con éxito con el ID: $insertedPedidoId");
    } else {
      //print("Error al insertar el pedido en la base de datos");
    }
    idPedidoDb = insertedPedidoId;
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    var bodegas = ['Elija una bodega', 'CARTAGENA', 'CALI'];
    bool isVisibleBod = false;
    bool alertItemAdd = false;
    int cantItemAdd = 0;

    if (GetStorage().read('items') == null) {
      _listarItems();
    } else {
      itemsGuardados = GetStorage().read('items');
    }

    if (GetStorage().read('zona') == null) {
      zona = "01";
    } else {
      zona = GetStorage().read('zona');
    }

    if (GetStorage().read('index') == null) {
      index = 0;
    } else {
      index = GetStorage().read('index');
    }

    if (GetStorage().read('empresa') == 'IGB' &&
        itemsGuardados[index]["grupo"] == 'LLANTAS' &&
        itemsGuardados[index]["marca"] == 'TIMSUN') {
      isVisibleBod = true;
    }

    if (itemsGuardados.length > 0) {
      List _stockTemp = [];
      if (GetStorage().read('stockFull') != null) {
        _stockFull = GetStorage().read('stockFull');
        _stockFull.forEach(
          (j) {
            if (itemsGuardados[index]["itemCode"] == j["itemCode"]) {
              _stockTemp.add(j);
            }
          },
        );
        setState(
          () {
            _stock = _stockTemp;
          },
        );
      }
    }

    if (GetStorage().read('itemsPedido') != null) {
      List<dynamic> itemsAddDetail = GetStorage().read('itemsPedido');
      itemsAddDetail.forEach(
        (j) {
          if (itemsGuardados[index]["itemCode"] == j["itemCode"]) {
            cantItemAdd = int.parse(j["quantity"]);
            alertItemAdd = true;
          }
        },
      );
    }

    if (_stock.length > 0) {
      if (!isVisibleBod) {
        _inventario = _stock[0]['stockWarehouses'];
        fullStock = _stock[0]['stockFull'];
      }
    }

    num stockSuma = 0;
    for (var bodega in _inventario) {
      if (bodega['quantity'] > 0 && bodega['whsCode'] == zona) {
        whsCodeStockItem = bodega['whsCode'];
        fullStock = bodega['quantity'];
      } else {
        whsCodeStockItem = itemsGuardados[index]["whsCode"];
        stockSuma = stockSuma + bodega['quantity'];
      }
    }

    String precioTxt = numberFormat.format(itemsGuardados[index]['price']);
    if (precioTxt.contains('.')) {
      int decimalIndex = precioTxt.indexOf('.');
      precioTxt = precioTxt.substring(0, decimalIndex);
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        itemsGuardados[index]['itemName'],
        style: TextStyle(fontSize: 14),
      ),
      actions: <Widget>[
        Divider(),
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (alertItemAdd)
                //mostar cantidad agregada al detalle
                Text(cantItemAdd.toString() + ' '),
              if (alertItemAdd)
                //mostar si esta agregado al detalle
                Icon(Icons.verified_outlined),
              Text('          Sku: ' + itemsGuardados[index]['itemCode']),
            ],
          ),
        ),
        SizedBox(
          child: Text('Stock: ' + fullStock.toString()),
        ),
        SizedBox(
          child: Text('Precio: ' + precioTxt),
        ),
        SizedBox(
          width: 250,
          child: isVisibleBod
              ? DropdownButton<String>(
                  isExpanded: true,
                  value: dropdownvalueBodega.isNotEmpty
                      ? dropdownvalueBodega
                      : null,
                  onChanged: (String? newValue) async {
                    dropdownvalueBodega = newValue.toString();
                    if (dropdownvalueBodega.length > 0) {
                      var whsCode = '';
                      switch (dropdownvalueBodega) {
                        case 'CARTAGENA':
                          whsCode = '05';
                          break;
                        case 'CALI':
                          whsCode = '26';
                          break;
                        default:
                          whsCode = '01';
                          break;
                      }
                      int stock = await _getStockByItemAndWhsCode(
                          itemsGuardados[index]['itemCode'], whsCode);
                      setState(
                        () {
                          mensaje = '';
                          textoVisible = false;
                          fullStock = stock;
                          whsCodeStockItem = whsCode;
                        },
                      );
                    }
                    setState(
                      () {
                        dropdownvalueBodega = newValue!;
                      },
                    );
                  },
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  items: bodegas.map(
                    (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(value),
                        ),
                      );
                    },
                  ).toList(),
                )
              : Container(),
        ),
        SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 250,
          height: 35,
          child: TextField(
            onChanged: (text) {
              if (empresa != "REDPLAS") {
                RegExp regex = RegExp(r'0+[1-9]');
                if (text.length == 0) {
                  setState(
                    () {
                      btnAgregarActivo = false;
                    },
                  );
                }
                if (text.isEmpty) {
                  btnAgregarActivo = false;
                } else {
                  if (!areAllCharactersNumbers(text)) {
                    setState(
                      () {
                        mensaje = "Cantidad debe ser numérica";
                        textoVisible = true;
                        btnAgregarActivo = false;
                      },
                    );
                  } else {
                    if (int.parse(text) > fullStock) {
                      setState(
                        () {
                          mensaje = "Cantidad es mayor al stock";
                          textoVisible = true;
                          btnAgregarActivo = false;
                        },
                      );
                    } else {
                      if (int.parse(text) < 1) {
                        setState(
                          () {
                            mensaje = "Cantidad debe ser mayor a 0";
                            textoVisible = true;
                            btnAgregarActivo = false;
                          },
                        );
                      } else {
                        if (regex.hasMatch(text)) {
                          setState(
                            () {
                              mensaje = "Cantidad contiene 0 a la izq";
                              textoVisible = true;
                              btnAgregarActivo = false;
                            },
                          );
                        } else {
                          setState(
                            () {
                              mensaje = "";
                              textoVisible = false;
                              btnAgregarActivo = true;
                            },
                          );
                        }
                      }
                    }
                  }
                }
              } else {
                setState(
                  () {
                    mensaje = "";
                    textoVisible = false;
                    btnAgregarActivo = true;
                  },
                );
              }
            },
            style: const TextStyle(color: Colors.black),
            controller: cantidadController,
            keyboardType: TextInputType.text,
            focusNode: _focusNode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              //hintText: 'Por favor ingrese cantidad',
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
        SizedBox(
          height: 5,
        ),
        Visibility(
          visible: textoVisible,
          child: Center(
            child: Material(
              elevation: 5,
              color: Colors.grey,
              borderRadius: BorderRadius.horizontal(),
              child: Container(
                width: 300,
                height: 30,
                child: Center(
                  child: Text(
                    mensaje,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ),
        Divider(),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // IconButton(
            //   icon: const Icon(Icons.search_sharp),
            //   onPressed: (){setState(() {
            //     isDropDownVisible= !isDropDownVisible;
            //
            //   });},
            //   //child: const Text('Consultar Bodega'),
            // ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart_rounded),
              //child: Text("Agregar al pedido"),
              onPressed: btnAgregarActivo
                  ? () {
                      if (isVisibleBod) {
                        if (dropdownvalueBodega == '' ||
                            dropdownvalueBodega == 'Elija una bodega') {
                          setState(
                            () {
                              mensaje = "Elija una bodega";
                              textoVisible = true;
                              btnAgregarActivo = true;
                            },
                          );
                        } else {
                          setState(
                            () {
                              //// AGREGAR ITEM AL PEDIDO
                              itemTemp["quantity"] = cantidadController.text;
                              itemTemp["itemCode"] =
                                  itemsGuardados[index]["itemCode"];
                              itemTemp["itemName"] =
                                  itemsGuardados[index]["itemName"];
                              itemTemp["group"] =
                                  itemsGuardados[index]["grupo"];
                              if (itemsGuardados[index]["presentation"] !=
                                  null) {
                                itemTemp["presentation"] =
                                    itemsGuardados[index]["presentation"];
                              } else {
                                itemTemp["presentation"] = "";
                              }
                              itemTemp["price"] =
                                  itemsGuardados[index]["price"].toString();
                              itemTemp["discountItem"] = itemsGuardados[index]
                                      ["discountItem"]
                                  .toString();
                              itemTemp["discountPorc"] = itemsGuardados[index]
                                      ["discountPorc"]
                                  .toString();
                              itemTemp["whsCode"] = whsCodeStockItem == null
                                  ? "01"
                                  : whsCodeStockItem.toString();
                              itemTemp["iva"] =
                                  itemsGuardados[index]["iva"].toString();
                              itemsPedido.add(itemTemp);

                              int precioI = itemsGuardados[index]["price"];
                              double precioD = precioI.toDouble();
                              int discountI =
                                  itemsGuardados[index]["discountPorc"];
                              double discountD = discountI.toDouble();
                              int discountItemI =
                                  itemsGuardados[index]["discountItem"];
                              double discountItemD = discountItemI.toDouble();
                              int ivaI = itemsGuardados[index]["iva"];
                              double ivaD = ivaI.toDouble();
                              Item newItem = Item(
                                idPedido: idPedidoDb,
                                quantity: int.parse(cantidadController.text),
                                itemCode: itemsGuardados[index]["itemCode"],
                                itemName: itemsGuardados[index]["itemName"],
                                grupo: itemsGuardados[index]["grupo"],
                                whsCode: whsCodeStockItem,
                                presentation: itemsGuardados[index]
                                    ["presentation"],
                                price: precioD,
                                discountItem: discountItemD,
                                discountPorc: discountD,
                                iva: ivaD,
                              );
                              // Insertar el nuevo item en la base de datos
                              insertItemDb(newItem);

                              ///guardar id en map
                              // actualizarPedidoGuardado["docNum"]=idLocal.toString();
                              // storage.write('actualizarPedidoGuardado', actualizarPedidoGuardado);
                              listarItemDb();
                              if (GetStorage().read('itemsPedido') == null) {
                                storage.write('itemsPedido', itemsPedido);
                              } else {
                                itemsPedidoLocal =
                                    GetStorage().read('itemsPedido');
                                //// VALIDAR SI EL ITME SELECCIONADO YA ESTÁ,ENTONCES SE SUMA LA CANTIDAD
                                int repetido = 0;
                                itemsPedidoLocal.forEach(
                                  (j) {
                                    if (itemTemp["itemCode"] == j["itemCode"] &&
                                        itemTemp["whsCode"] == j["whsCode"]) {
                                      int cant = 0;
                                      cant = int.parse(j["quantity"]!) +
                                          int.parse(itemTemp["quantity"]!);
                                      j["quantity"] = cant.toString();
                                      repetido = 1;
                                    }
                                  },
                                );
                                if (repetido == 0) {
                                  itemsPedidoLocal.add(itemTemp);
                                }
                                storage.write('itemsPedido', itemsPedidoLocal);
                              }
                              storage.write('index', index);
                            },
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        setState(
                          () {
                            //// AGREGAR ITEM AL PEDIDO
                            itemTemp["quantity"] = cantidadController.text;
                            itemTemp["itemCode"] =
                                itemsGuardados[index]["itemCode"];
                            itemTemp["itemName"] =
                                itemsGuardados[index]["itemName"];
                            itemTemp["group"] = itemsGuardados[index]["grupo"];
                            if (itemsGuardados[index]["presentation"] != null) {
                              itemTemp["presentation"] =
                                  itemsGuardados[index]["presentation"];
                            } else {
                              itemTemp["presentation"] = "";
                            }
                            itemTemp["price"] =
                                itemsGuardados[index]["price"].toString();
                            itemTemp["discountItem"] = itemsGuardados[index]
                                    ["discountItem"]
                                .toString();
                            itemTemp["discountPorc"] = itemsGuardados[index]
                                    ["discountPorc"]
                                .toString();
                            itemTemp["whsCode"] = whsCodeStockItem == null
                                ? "01"
                                : whsCodeStockItem.toString();
                            itemTemp["iva"] =
                                itemsGuardados[index]["iva"].toString();
                            itemsPedido.add(itemTemp);

                            int precioI = itemsGuardados[index]["price"];
                            double precioD = precioI.toDouble();
                            int discountI =
                                itemsGuardados[index]["discountPorc"];
                            double discountD = discountI.toDouble();
                            int discountItemI =
                                itemsGuardados[index]["discountItem"];
                            double discountItemD = discountItemI.toDouble();
                            int ivaI = itemsGuardados[index]["iva"];
                            double ivaD = ivaI.toDouble();
                            Item newItem = Item(
                              idPedido: idPedidoDb,
                              quantity: int.parse(cantidadController.text),
                              itemCode: itemsGuardados[index]["itemCode"],
                              itemName: itemsGuardados[index]["itemName"],
                              grupo: itemsGuardados[index]["grupo"],
                              whsCode: whsCodeStockItem,
                              presentation: itemsGuardados[index]
                                  ["presentation"],
                              price: precioD,
                              discountItem: discountItemD,
                              discountPorc: discountD,
                              iva: ivaD,
                            );
                            // Insertar el nuevo item en la base de datos
                            insertItemDb(newItem);

                            ///guardar id en map
                            // actualizarPedidoGuardado["docNum"]=idLocal.toString();
                            // storage.write('actualizarPedidoGuardado', actualizarPedidoGuardado);
                            listarItemDb();
                            if (GetStorage().read('itemsPedido') == null) {
                              storage.write('itemsPedido', itemsPedido);
                            } else {
                              itemsPedidoLocal =
                                  GetStorage().read('itemsPedido');
                              //// VALIDAR SI EL ITME SELECCIONADO YA ESTÁ,ENTONCES SE SUMA LA CANTIDAD
                              int repetido = 0;
                              itemsPedidoLocal.forEach(
                                (j) {
                                  if (itemTemp["itemCode"] == j["itemCode"] &&
                                      itemTemp["whsCode"] == j["whsCode"]) {
                                    int cant = 0;
                                    cant = int.parse(j["quantity"]!) +
                                        int.parse(itemTemp["quantity"]!);
                                    j["quantity"] = cant.toString();
                                    repetido = 1;
                                  }
                                },
                              );
                              if (repetido == 0) {
                                itemsPedidoLocal.add(itemTemp);
                              }
                              storage.write('itemsPedido', itemsPedidoLocal);
                            }
                            storage.write('index', index);
                          },
                        );
                        Navigator.pop(context);
                      }
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
  int borrar = 0;
  final numberFormat = new NumberFormat.simpleCurrency();
  int cantidadAdicionalItem = 0;
  GetStorage storage = GetStorage();
  List _stock2 = [];
  List _stockFull2 = [];
  var fullStock = 0;
  var stockItem;

  void borrarItemDetalle(String item) {
    itemsPedidoLocal = GetStorage().read('itemsPedido');
    itemsPedidoLocal.forEach(
      (j) {
        if (j['itemCode'] == item) {
          itemsPedidoLocal.remove(j);
        }
      },
    );
  }

  void showAlertDetailItems(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Atención"),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () {
                    itemsPedidoLocal.clear();
                    storage.remove('itemsPedido');
                  },
                );
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("Si"),
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
          title: Text("Atención"),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () {
                    itemsPedidoLocal.forEach(
                      (j) {
                        if (j['itemCode'] == itemCode) {
                          itemsPedidoLocal.remove(j);
                        }
                      },
                    );
                  },
                );
                Navigator.pop(context);
              },
              child: Text("Si"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (GetStorage().read('itemsPedido') == null) {
      //print("No hay items ");
    } else {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
      listaItems = [];
      itemsPedidoLocal.forEach(
        (j) {
          listaItems.add(j);
        },
      );
    }
    return SafeArea(
      child: listaItems.isEmpty
          ? Text(
              "No se encontraron ítems agregados para mostar",
              textAlign: TextAlign.center,
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        showAlertDetailItems(
                          context,
                          "¿Está seguro de borrar todos los ítems?",
                        );
                      },
                    ),
                    Text(
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
                      subtotalDetalle =
                          double.parse(listaItems[index]['price']) *
                              double.parse(listaItems[index]['quantity']);
                      iva = (double.parse(listaItems[index]['iva']) *
                              subtotalDetalle) /
                          100;
                      String ivaTxt = numberFormat.format(iva);
                      ivaTxt = ivaTxt.substring(0, ivaTxt.length - 3);
                      String subtotalDetalleTxt =
                          numberFormat.format(subtotalDetalle);
                      subtotalDetalleTxt = subtotalDetalleTxt.substring(
                          0, subtotalDetalleTxt.length - 3);
                      totalDetalle = subtotalDetalle + iva;
                      String totalDetalleTxt =
                          numberFormat.format(totalDetalle);
                      totalDetalleTxt = totalDetalleTxt.substring(
                          0, totalDetalleTxt.length - 3);
                      int precio = int.parse(listaItems[index]['price']);
                      String precioTxt = numberFormat.format(precio);
                      precioTxt = precioTxt.substring(0, precioTxt.length - 3);
                      return Card(
                        child: Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        showAlertDetailSingleItem(
                                          context,
                                          listaItems[index]['itemCode'],
                                          "¿Está seguro de borrar el ítem " +
                                              listaItems[index]['itemCode'] +
                                              "?",
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        //////VERIFICAR STOCK
                                        List _stockTemp = [];
                                        List _inventario = [];
                                        var zona = "";
                                        if (GetStorage().read('zona') == null) {
                                          zona = "01";
                                        } else {
                                          zona = GetStorage().read('zona');
                                        }
                                        if (GetStorage().read('stockFull') !=
                                            null) {
                                          _stockFull2 =
                                              GetStorage().read('stockFull');
                                          _stockFull2.forEach(
                                            (j) {
                                              if (listaItems[index]
                                                      ["itemCode"] ==
                                                  j["itemCode"]) {
                                                _stockTemp.add(j);
                                              }
                                            },
                                          );
                                          setState(
                                            () {
                                              _stock2 = _stockTemp;
                                            },
                                          );
                                        }
                                        if (_stock2.length > 0) {
                                          _inventario =
                                              _stock2[0]['stockWarehouses'];
                                          fullStock = _stock2[0]['stockFull'];
                                        }

                                        num stockSuma = 0;
                                        for (var bodega in _inventario) {
                                          if (bodega['quantity'] > 0 &&
                                              bodega['whsCode'] == zona) {
                                            stockItem = bodega['whsCode'];
                                            fullStock = bodega['quantity'];
                                          } else
                                            stockItem =
                                                listaItems[index]["whsCode"];
                                          stockSuma =
                                              stockSuma + bodega['quantity'];
                                        }

                                        ////FIN VERIFICAR STOCK
                                        //int nuevaCantidad = int.tryParse(cantAdicional.text) ?? 0;
                                        double cant1 = 0.0;
                                        if (fullStock > 0 &&
                                            fullStock >
                                                double.parse(listaItems[index]
                                                    ['quantity'])) {
                                          cant1 = double.parse(listaItems[index]
                                                  ['quantity']) +
                                              1;
                                          listaItems[index]['quantity'] =
                                              cant1.toInt().toString();
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "No hay stock disponible"),
                                                actions: [
                                                  TextButton(
                                                    child: Text("Aceptar"),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                        storage.write("cantidadItem", 0);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        List _stockTemp = [];
                                        List _inventario = [];
                                        var zona = "";
                                        if (GetStorage().read('zona') == null) {
                                          zona = "01";
                                        } else {
                                          zona = GetStorage().read('zona');
                                        }
                                        if (GetStorage().read('stockFull') !=
                                            null) {
                                          _stockFull2 =
                                              GetStorage().read('stockFull');
                                          _stockFull2.forEach(
                                            (j) {
                                              if (listaItems[index]
                                                      ["itemCode"] ==
                                                  j["itemCode"]) {
                                                _stockTemp.add(j);
                                              }
                                            },
                                          );
                                          setState(
                                            () {
                                              _stock2 = _stockTemp;
                                            },
                                          );
                                        }
                                        if (_stock2.length > 0) {
                                          _inventario =
                                              _stock2[0]['stockWarehouses'];
                                          fullStock = _stock2[0]['stockFull'];
                                        }

                                        num stockSuma = 0;
                                        for (var bodega in _inventario) {
                                          if (bodega['quantity'] > 0 &&
                                              bodega['whsCode'] == zona) {
                                            stockItem = bodega['whsCode'];
                                            fullStock = bodega['quantity'];
                                          } else {
                                            stockItem =
                                                listaItems[index]["whsCode"];
                                            stockSuma =
                                                stockSuma + bodega['quantity'];
                                          }
                                        }
                                        ////FIN VERIFICAR STOCK
                                        double cant1 = 0.0;
                                        cant1 = double.parse(
                                            listaItems[index]['quantity']);
                                        if (cant1 > 1) {
                                          cant1 = cant1 - 1;
                                          listaItems[index]['quantity'] =
                                              cant1.toInt().toString();
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                  "La cantidad de ítems es menor a 1",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text("Aceptar"),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16.0),
                                Expanded(
                                  child: Text(
                                    listaItems[index]['itemName'] +
                                        '\n' +
                                        'Sku: ' +
                                        listaItems[index]['itemCode'] +
                                        '\n' +
                                        'Precio: ' +
                                        precioTxt +
                                        '\n' +
                                        'Cant: ' +
                                        listaItems[index]['quantity'] +
                                        '\n' +
                                        'Bodega: ' +
                                        listaItems[index]['whsCode'] +
                                        '\n' +
                                        'Subtotal: ' +
                                        subtotalDetalleTxt +
                                        '\n' +
                                        'Iva: ' +
                                        ivaTxt +
                                        '\n' +
                                        'Total: ' +
                                        totalDetalleTxt,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
  TextEditingController observacionesController = TextEditingController();
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');
  Connectivity _connectivity = Connectivity();
  bool cargando = false;
  bool btnPedidoActivo = false;
  bool btnGuardarActivo = false;

  //
  // @override
  // void dispose() {
  //   Map<String, dynamic> pedidoFinal = GetStorage().read('pedido');
  //   var obs = GetStorage().read('observaciones');
  //   pedidoFinal['comments'] = obs;
  //   super.dispose();
  // }

  Future<http.Response> _enviarPedido(
      BuildContext context, Map<String, dynamic> pedidoFinal) {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/create-order';
    var dirEnvio = GetStorage().read('dirEnvio');

    DateTime now = DateTime.now();
    String formatter = DateFormat('hhmm').format(now);
    formatter = formatter.replaceAll(":", "");
    String fecha = DateFormat("yyyyMMdd").format(now);
    String numAtCard;

    if (GetStorage().read('pedidoGuardado') == null ||
        GetStorage().read('pedidoGuardado').isEmpty) {
      numAtCard = fecha.toString() +
          pedidoFinal['cardCode'].toString() +
          formatter.toString();
    } else {
      numAtCard = fecha.toString() +
          pedidoFinal['cardCode'].toString() +
          GetStorage().read('pedidoGuardado')['id'].toString();
    }

    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.deleteAllItemsP();
    dbHelper.deleteAllItems();

    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
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
      BuildContext context, Map<String, dynamic> pedidoFinal) {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/save-order';
    var dirEnvio = GetStorage().read('dirEnvio');

    DateTime now = DateTime.now();
    String formatter = DateFormat('hhmm').format(now);
    formatter = formatter.replaceAll(":", "");
    String fecha = DateFormat("yyyyMMdd").format(now);
    String numAtCard = fecha.toString() +
        pedidoFinal['cardCode'].toString() +
        formatter.toString();
    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
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
    if (GetStorage().read('stockFull') != null) {
      List _stockFull = GetStorage().read('stockFull');
      for (var stock in _stockFull) {
        if (stock['itemCode'] == item) {
          for (var bodega in stock['stockWarehouses']) {
            if (bodega['whsCode'] == bodegaB) {
              bodega['quantity'] = bodega['quantity'] - cantidad;
            }
          }
        }
      }
      setState(
        () {
          storage.write("stockFull", _stockFull);
        },
      );
      return 1;
    } else {
      return 0;
    }
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void showAlertError(BuildContext context, String message) {
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
                Navigator.of(context).pop();
              },
              child: Text('OK'),
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
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text('Atención!'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    ).then(
      (value) {
        setState(
          () {
            btnPedidoActivo = false;
            btnGuardarActivo = false;
          },
        );
      },
    );
  }

  void showAlertPedidoEnviado(BuildContext context, String message) {
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
                storage.remove('observaciones');
                storage.remove("pedido");
                storage.remove("itemsPedido");
                storage.remove("dirEnvio");
                storage.remove("pedidoGuardado");
                storage.write('estadoPedido', 'nuevo');

                DatabaseHelper dbHelper = DatabaseHelper();
                dbHelper.deleteAllItemsP();
                dbHelper.deleteAllItems();
                requestStoragePermission();
                deleteAppData();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
              },
              child: Text('OK'),
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
      String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Atención"),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: btnConfirmarEnvio
                      ? () async {
                          setState(
                            () {
                              btnConfirmarEnvio = false;
                            },
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text("No"),
                ),
                ElevatedButton(
                  onPressed: btnConfirmarEnvio
                      ? () async {
                          setState(
                            () {
                              btnConfirmarEnvio = false;
                              message = 'Guardando pedido. Por favor espere...';
                            },
                          );

                          String codigo = pedidoFinal["slpCode"];
                          int slpInt = int.parse(codigo);
                          String descS = pedidoFinal["discountPercent"];
                          double descD = double.parse(descS);
                          String totS = pedidoFinal["docTotal"];
                          double totD = double.parse(totS);
                          /////// guardar
                          Pedido pedidoF = Pedido(
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
                          //observacionesController.text='';
                          // if (buscarClientePedido(pedidoFinal["cardName"])==false)
                          // {print ("No esta el pedido, insertando...");insertPedidoDb(pedidoF);}
                          // else {print ("Ya está el pedido, actualizando ...");}
                          insertPedidoDb(pedidoF);
                          listarPedidos();
                          setState(
                            () {
                              cargando = true;
                            },
                          );
                          try {
                            http.Response response =
                                await _guardarPedido(context, pedidoFinal);
                            Map<String, dynamic> resultado =
                                jsonDecode(response.body);
                            if (response.statusCode == 200 &&
                                resultado['content'] != "") {
                              Navigator.pop(context);
                              setState(
                                () {
                                  showAlertPedidoEnviado(
                                    context,
                                    "Pedido Guardado: " +
                                        resultado['content'].toString(),
                                  );
                                },
                              );
                              setState(
                                () {
                                  actualizarEstadoPed(
                                    GetStorage().read('pedidoGuardado')['id'],
                                    0,
                                    'C',
                                  );
                                },
                              );
                            } else {
                              showAlertError(
                                context,
                                "No se pudo guardar el pedido, error de red, verifique conectividad por favor",
                              );
                            }
                          } catch (e) {
                            setState(
                              () {
                                Get.snackbar(
                                  'Error',
                                  'El servicio no responde, contacte al administrador',
                                  colorText: Colors.red,
                                  backgroundColor: Colors.white,
                                );
                              },
                            );
                          }
                          /*storage.remove("pedido");
                        storage.remove("itemsPedido");
                        storage.remove("dirEnvio");
                        storage.remove("pedidoGuardado");
                        storage.write('estadoPedido', 'nuevo');*/
                          //await Future.delayed(Duration(seconds: 5));
                          //btnGuardadActivo = true;
                          /*Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );*/
                        }
                      : null,
                  child: Text("Si"),
                )
              ],
            );
          },
        );
      },
    ).then(
      (value) {
        setState(
          () {
            btnGuardarActivo = false;
          },
        );
      },
    );
  }

  void showAlertConfirmOrder(
      BuildContext context,
      Map<String, dynamic> pedidoFinal,
      bool btnConfirmarEnvio,
      String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Atención"),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: btnConfirmarEnvio
                      ? () async {
                          setState(
                            () {
                              btnConfirmarEnvio = false;
                            },
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text("No"),
                ),
                ElevatedButton(
                  onPressed: btnConfirmarEnvio
                      ? () async {
                          setState(
                            () {
                              btnConfirmarEnvio = false;
                              message =
                                  'Procesando pedido. Por favor espere...';
                            },
                          );
                          bool isConnected = await checkConnectivity();
                          if (isConnected == true) {
                            pedidoFinal['comments'] =
                                observacionesController.text;
                            storage.write('pedido', pedidoFinal);
                            setState(
                              () {
                                cargando = true;
                              },
                            );

                            http.Response response =
                                await _enviarPedido(context, pedidoFinal);
                            Map<String, dynamic> resultado =
                                jsonDecode(response.body);

                            if (response.statusCode == 200 &&
                                resultado['content'] != "") {
                              Navigator.pop(context);
                              setState(
                                () {
                                  showAlertPedidoEnviado(
                                    context,
                                    "Pedido: " +
                                        resultado['content'].toString(),
                                  );
                                },
                              );
                              Map<String, dynamic> actualizarPedidoGuardado =
                                  {};
                              if (GetStorage()
                                      .read('actualizarPedidoGuardado') !=
                                  null) {
                                actualizarPedidoGuardado = GetStorage()
                                    .read('actualizarPedidoGuardado');
                                setState(
                                  () {
                                    actualizarEstadoPed(
                                      int.parse(actualizarPedidoGuardado["id"]),
                                      resultado['content'],
                                      'F',
                                    );
                                  },
                                );
                              }
                              storage.remove("pedido");
                              storage.remove("itemsPedido");
                              storage.remove("dirEnvio");
                              storage.remove("pedidoGuardado");
                              storage.write('estadoPedido', 'nuevo');
                            } else {
                              Get.snackbar(
                                'Error',
                                'No se pudo crear el pedido',
                                colorText: Colors.red,
                                backgroundColor: Colors.white,
                              );
                            }
                          } else {
                            showAlertError(
                              context,
                              "No se pudo enviar el pedido, error de red, verifique conectividad por favor",
                            );
                          }
                        }
                      : null,
                  child: Text("Si"),
                )
              ],
            );
          },
        );
      },
    ).then(
      (value) {
        setState(
          () {
            btnPedidoActivo = false;
          },
        );
      },
    );
  }

  Future<void> listarPedidos() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Pedido> pedidos = await dbHelper.getPedidos();

    if (pedidos.isNotEmpty) {
      for (Pedido pedido in pedidos) {
        //print("ID: ${pedido.id}");
        //print("Cardcode: ${pedido.cardCode}");
        //print("Nombre: ${pedido.cardName}");
        // ... Mostrar los demás atributos del item ...
        //print("--------------------------");
      }
    }
  }

  Future<bool> buscarClientePedido(String cardCode) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Pedido> pedidos = await dbHelper.getPedidos();

    if (pedidos.isNotEmpty) {
      for (Pedido pedido in pedidos) {
        if (pedido.cardCode == cardCode) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> insertPedidoDb(Pedido pedidoFinal) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    int insertedPedidoId = await dbHelper.insertPedido(pedidoFinal);

    if (insertedPedidoId != null && insertedPedidoId > 0) {
      //print("El pedido ha sido insertado con éxito con el ID: $insertedPedidoId");
    } else {
      //print("Error al insertar el pedido en la base de datos");
    }
    //idPedidoDb= insertedPedidoId;
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
    final response = await http.get(Uri.parse(apiUrl));

    if (response.body == "true") {
      //print("Se cambió estado a " + status);
    } else {
      //print("No se pudo cambiar el estado a " + status);
    }
  }

  /*void _clearCache() {
    // Eliminamos todos los archivos de caché.
    for (final file in Directory('cache').listSync()) {
      file.delete();
    }
  }*/

  Future<void> requestStoragePermission() async {
    try {
      await DefaultCacheManager().emptyCache();
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caché borrada con éxito'),
        ),
      );*/
    } catch (e) {
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al borrar la caché: $e'),
        ),
      );*/
      //print('Error al borrar la caché: $e');
    }

    //final status = await Permission.storage.request();
    /*if (status.isGranted) {
      await DefaultCacheManager().emptyCache();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caché borrada con éxito'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se otorgó permiso para borrar la caché'),
        ),
      );
    }*/
  }

  Future<void> deleteAppData() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final dir = Directory(directory.path);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos borrados con éxito'),
          ),
        );*/
      } /*else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontraron datos para eliminar.'),
          ),
        );
      }*/
    } catch (e) {
      //print('Error al eliminar los datos de la aplicación: $e');
    }
  }

  /*Future<LocationData> activeteLocation() async {
    Location location = Location();
    bool serviceEnabled;
    LocationData locationData;
    serviceEnabled = await location.serviceEnabled();
    if (serviceEnabled) {
      locationData = await location.getLocation();
      return locationData;
    } else {
      return new LocationData.fromMap({"latitude": 0.0, "longitude": 0.0});
    }
  }*/

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

  Future<http.Response> createRecordGeoLocation(String latitude,
      String longitude, String slpCode, String companyName, String docType) {
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
          "docType": docType
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = new NumberFormat.simpleCurrency();

    if (GetStorage().read('pedido') != null) {
      Map<String, dynamic> pedidoFinal = GetStorage().read('pedido');
      if (GetStorage().read('pedidoGuardado') != null) {
        Map<String, dynamic> pedidoFinalG = GetStorage().read('pedidoGuardado');
        pedidoFinal['comments'] = pedidoFinalG['comments'] ?? '';
      }
      List<dynamic> itemsPedidoLocal = [];
      List itemsGuardados = [];
      int cantidadItems = 0;
      num subtotal = 0;

      String obs = "";
      if (GetStorage().read('observaciones') != null) {
        obs = GetStorage().read('observaciones');
        observacionesController.text = obs;
      }

      if (GetStorage().read('itemsPedido') == null) {
      } else {
        itemsPedidoLocal = GetStorage().read('itemsPedido');
      }
      if (GetStorage().read('items') == null) {
      } else {
        /////BUSCAR itemCode en lista de items para hallar el precio
        itemsGuardados = GetStorage().read('items');
        itemsPedidoLocal.forEach(
          (j) {
            itemsGuardados.forEach(
              (k) {
                String cantQ = j['quantity'];
                double cantidadQ = double.parse(cantQ);
                if (k['itemCode'] == j['itemCode']) {
                  subtotal = subtotal + k['price'] * cantidadQ;
                }
              },
            );
          },
        );
      }
      if (GetStorage().read('itemsPedido') == null) {
        cantidadItems = 0;
      } else {
        itemsPedidoLocal = GetStorage().read('itemsPedido');
        cantidadItems = itemsPedidoLocal.length;
      }

      double iva = 0.0;
      itemsPedidoLocal.forEach(
        (element) {
          var subt = double.parse(element["price"]) *
              double.parse(element["quantity"]);
          var ivaTemp =
              (double.parse(element["iva"].toString()) * subt.toDouble()) / 100;
          iva = iva + ivaTemp;
        },
      );

      String ivaTxt = numberFormat.format(iva);
      double total = subtotal.toDouble() + iva;
      String subtotalTxt = numberFormat.format(subtotal);
      String descuento = pedidoFinal['discountPercent'];
      String estadoPedido = "";

      if (subtotalTxt.contains('.')) {
        int decimalIndex = subtotalTxt.indexOf('.');
        subtotalTxt = subtotalTxt.substring(0, decimalIndex);
      }
      if (descuento.contains('.')) {
        int decimalIndex = descuento.indexOf('.');
        descuento = descuento.substring(0, decimalIndex);
      }
      ivaTxt = numberFormat.format(iva - (iva * (int.parse(descuento) / 100)));
      if (ivaTxt.contains('.')) {
        int decimalIndex = ivaTxt.indexOf('.');
        ivaTxt = ivaTxt.substring(0, decimalIndex);
      }
      String totalDocTxt = numberFormat.format(subtotal -
          (subtotal * (int.parse(descuento) / 100)) +
          (iva - (iva * (int.parse(descuento) / 100))));
      if (totalDocTxt.contains('.')) {
        int decimalIndex = totalDocTxt.indexOf('.');
        totalDocTxt = totalDocTxt.substring(0, decimalIndex);
      }
      String textoObservaciones = "";
      if (pedidoFinal['comments'] != null) {
        textoObservaciones = pedidoFinal['comments'];
        if (GetStorage().read('estadoPedido') != null) {
          estadoPedido = GetStorage().read('estadoPedido');
        } else {
          estadoPedido = "desconocido";
        }
        if (estadoPedido == "nuevo") {
          storage.remove('observaciones');
          observacionesController.text;
        }
        if (estadoPedido == "guardado") {
          String obs = textoObservaciones;
          observacionesController.text = obs;
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
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          pedidoFinal['nit'] + ' - ' + pedidoFinal['cardName'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Cant de ítems: " + cantidadItems.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Subtotal: " + subtotalTxt,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Descuento: %" + descuento,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Iva: " + ivaTxt,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Total: " + totalDocTxt,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Observaciones:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: 400,
                          child: TextField(
                            maxLines: 7,
                            controller: observacionesController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            onChanged: (text) {
                              pedidoFinal['comments'] =
                                  observacionesController.text;
                              pedidoFinal['id'] = text;
                              storage.write("observaciones",
                                  observacionesController.text);
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
            SizedBox(
              height: 20,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledColor: Colors.grey,
                      elevation: 0,
                      color: Color.fromRGBO(30, 129, 235, 1),
                      onPressed: btnPedidoActivo
                          ? null
                          : () async {
                              storage.write('estadoPedido', 'editado');
                              setState(
                                () {
                                  btnPedidoActivo = true;
                                },
                              );
                              if (GetStorage().read('dirEnvio') == null ||
                                  GetStorage().read('dirEnvio') == "" ||
                                  GetStorage().read('dirEnvio') ==
                                      "Elija un destino") {
                                showAlertErrorDir(
                                  context,
                                  "Obligatorio seleccionar la dirección de destino.",
                                );
                              } else if (GetStorage().read('itemsPedido') ==
                                      null ||
                                  GetStorage().read('itemsPedido') == "") {
                                showAlertErrorDir(
                                  context,
                                  "Obligatorio agregar ítems en detalle.",
                                );
                              } else {
                                Position locationData =
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
                                } else {
                                  try {
                                    http.Response response =
                                        await createRecordGeoLocation(
                                            locationData.latitude.toString(),
                                            locationData.longitude.toString(),
                                            GetStorage().read('usuario'),
                                            empresa,
                                            'P');
                                    Map<String, dynamic> res =
                                        jsonDecode(response.body);
                                    if (res['code'] == 0) {
                                      showAlertConfirmOrder(
                                        context,
                                        pedidoFinal,
                                        true,
                                        "¿Está seguro que deseea enviar el pedido?",
                                      );
                                    } else {
                                      showAlertErrorDir(
                                          context, res['content']);
                                    }
                                  } catch (e) {
                                    showAlertErrorDir(
                                      context,
                                      "Lo sentimos, ocurrió un error inesperado. Inténtelo nuevamente",
                                    );
                                  }
                                }
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          btnPedidoActivo ? 'Espere' : 'Enviar Pedido',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledColor: Colors.grey,
                      elevation: 0,
                      color: Color.fromRGBO(30, 129, 235, 1),
                      onPressed: btnGuardarActivo
                          ? null
                          : () async {
                              storage.write('estadoPedido', 'editado');
                              setState(
                                () {
                                  btnGuardarActivo = true;
                                },
                              );
                              if (GetStorage().read('dirEnvio') == null ||
                                  GetStorage().read('dirEnvio') == "" ||
                                  GetStorage().read('dirEnvio') ==
                                      "Elija un destino") {
                                showAlertErrorDir(
                                  context,
                                  "Obligatorio seleccionar la dirección de destino.",
                                );
                              } else if (GetStorage().read('itemsPedido') ==
                                      null ||
                                  GetStorage().read('itemsPedido') == "") {
                                showAlertErrorDir(
                                  context,
                                  "Obligatorio agregar ítems en detalle.",
                                );
                              } else {
                                Position locationData =
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
                                } else {
                                  try {
                                    http.Response response =
                                        await createRecordGeoLocation(
                                            locationData.latitude.toString(),
                                            locationData.longitude.toString(),
                                            GetStorage().read('usuario'),
                                            empresa,
                                            'G');
                                    Map<String, dynamic> res =
                                        jsonDecode(response.body);
                                    if (res['code'] == 0) {
                                      showAlertConfirmOrderForSave(
                                          context,
                                          pedidoFinal,
                                          true,
                                          "¿Está seguro que deseea guardar el pedido?");
                                    } else {
                                      showAlertErrorDir(
                                          context, res['content']);
                                    }
                                  } catch (e) {
                                    showAlertErrorDir(
                                      context,
                                      "Lo sentimos, ocurrió un error inesperado. Inténtelo nuevamente",
                                    );
                                  }
                                }
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          btnGuardarActivo ? 'Espere' : 'Guardar Pedido',
                          style: TextStyle(color: Colors.white),
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
    } else
      return Text("Sin ítems para pedido");
  }
}
