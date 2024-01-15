import 'dart:ffi';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:productos_app/screens/screens.dart';
import 'dart:convert'; // for using json.decode()
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'buscador.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:productos_app/models/DatabaseHelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  List _items = [];
  List _stock = [];
  List listaItems = [];
  String empresa = GetStorage().read('empresa');
  String usuario = GetStorage().read('usuario');
  TextEditingController cantidadController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
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

  Future<void> _leerDatosold() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var userPref = pref.getString('datosClientes');
    if (userPref != null) {
      List<dynamic> clientesMap = jsonDecode(userPref);
      if (!mounted) return;
      setState(() {
        datosClientesArr = clientesMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
        home: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Color.fromRGBO(30, 129, 235, 1),
                leading: GestureDetector(
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                title: ListTile(
                  onTap: () {
                    showSearch(
                      context: context,
                      delegate: CustomSearchDelegate(),
                    );
                  },
                  title: Text('Buscar', style: TextStyle(color: Colors.white)),
                ),
                bottom: const TabBar(
                  tabs: [
                    Tab(
                        child: Text('Cliente',
                            style: TextStyle(color: Colors.white))),
                    Tab(
                        child: Text('Items',
                            style: TextStyle(color: Colors.white))),
                    Tab(
                        child: Text('Detalle',
                            style: TextStyle(color: Colors.white))),
                    Tab(
                        child: Text('Total',
                            style: TextStyle(color: Colors.white))),
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
            )));
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

  Future<void> _listarStock(String item) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
            empresa +
            '?itemcode=' +
            item +
            '&whscode=0&slpcode=' +
            usuario;
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    final data = resp["content"];
    if (!mounted) return;
    setState(() {
      _stock = data;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(2015),
        lastDate: DateTime(2050));
    if (pickedDate != null && pickedDate != currentDate)
      setState(() {
        currentDate = pickedDate;
      });
  }

  int findItemIndex(List<dynamic> list, dynamic item) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == item) {
        return i;
      }
    }
    return -1; // Si el elemento no se encuentra en la lista
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
      if (GetStorage().read('cardCode') != null)
        nit = GetStorage().read('cardCode');
      else
        nit = "no exite nit";

      clientesGuardados.forEach((k) {
        //print("NIT2: ");
        //print(k['cardCode']);
        //print("NIT2: ");
        //print(nit);
        if (nit == k['cardCode']) {
          //print("Nitencontrado: ");
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
                                  datosClientesArr[indice]['cardName']
                                      .toString(),
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Cliente', textAlign: TextAlign.left),
                          SizedBox(
                            height: 30,
                          ),
                          Text(
                              datosClientesArr[indice]['addressToDef']
                                  .toString(),
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Dirección ',
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text(datosClientesArr[indice]['location'].toString(),
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Ciudad ', textAlign: TextAlign.left),
                          SizedBox(
                            height: 30,
                          ),
                          Text(datosClientesArr[indice]['wayToPay'].toString(),
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Forma de Pago ', textAlign: TextAlign.left),
                          SizedBox(
                            height: 30,
                          ),
                          Text(cupoTxt,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Cupo', textAlign: TextAlign.left),
                          SizedBox(
                            height: 30,
                          ),
                          Text(saldoTxt,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Saldo', textAlign: TextAlign.left),
                          SizedBox(
                            height: 30,
                          ),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: dropdownvalue2.isNotEmpty
                                ? dropdownvalue2
                                : null,
                            // Down Arrow Icon
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: direccionesEnvioAsesor.map((String items) {
                              return DropdownMenuItem(
                                value: items,
                                child: Text(items),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (!mounted) return;
                              setState(() {
                                int indice = findItemIndex(
                                    direccionesEnvioAsesor, newValue);
                                // print("direccion elegida");print(newValue);
                                // print ("direcion lineNum");
                                // print(direccionesEnvio[indice]);
                                // print(indice);
                                storage.write(
                                    "dirEnvio", direccionesEnvio[indice]);
                                //pedidoFinal['shipToCode']=newValue;
                                dropdownvalue2 = newValue!;
                              });
                            },
                          ),
                          Text('Dirección de destino',
                              textAlign: TextAlign.left),
                          SizedBox(
                            height: 10,
                          ),
                        ])),
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

  void _updatePage() {
    setState(() {});
  }

  @override
  Widget items(BuildContext context) {
    List _inventario = [];
    var itemsPedidoLocal = <Map<String, String>>[];
    var itemsPedido = <Map<String, String>>[];
    bool isDropDownVisible = false;

    _listarItems();
    return SafeArea(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final itemTemp = {
            "quantity": "",
            "itemCode": "",
            "itemName": "",
            "whsCode": ""
          };

          return Card(
            child: Padding(
              padding: EdgeInsets.all(1),
              child: Container(
                color: Colors.white,
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return DetailScreen(_items[index]['pictureUrl']);
                      }));
                    }, // Image tapped
                    child: //Image.network(_items[index]['pictureUrl'], width: 40,height: 40),
                        CachedNetworkImage(
                      imageUrl: _items[index]['pictureUrl'],
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      String dropdownvalue = 'Elija una Bodega';

                      showDialog(
                          context: context,
                          builder: (_) {
                            storage.write("index", index);
                            return MyDialog();
                          });
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

  void showAlertDialog(BuildContext context, String pedido) {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {},
    );
    AlertDialog alert = AlertDialog(
      title: Text("Pedido creado"),
      content: Text(pedido),
      actions: [
        okButton,
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
  bool isDropDownVisible = false;
  bool textoVisible = false;
  TextEditingController cantidadController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
  // var itemsPedidoLocal = <Map<String, String>>[];
  // var itemsPedido = <Map<String, String>>[];
  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> itemsPedido = [];
  String dropdownvalue = 'Elija una Bodega';
  String empresa = GetStorage().read('empresa');
  String mensaje = "";
  bool btnAgregarActivo = false;
  final numberFormat = new NumberFormat.simpleCurrency();
  var stockItem;
  String zona = "";
  String usuario = GetStorage().read('usuario');
  List _stockFull = [];
  int idPedidoDb = 0;
  int idLocal = 0;

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
    //sincronizarStock();
  }

  Future<void> _listarItems() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/' + empresa;
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
  }

  Future<void> sincronizarStock() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
            empresa +
            '?itemcode=0&whscode=0&slpcode=' +
            usuario;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      if (GetStorage().read('stockFull') != null) {
        List _stockFullLocal = GetStorage().read('stockFull');
        setState(() {
          _stockFull = _stockFullLocal;
        });
      }
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      final codigoError = resp["code"];
      if (codigoError == -1) {
        //print("codigoError: $codigoError");
        //print("Error de red");
      } else {
        final data = resp["content"];
        if (!mounted) return;
        setState(() {
          _stockFull = data;

          /// GUARDAR
          storage.write('stockFull', _stock);
        });
      }
    }
  }

  // Future<void> _listarStock( String item) async {
  //   List _stockTemp=[];
  //   bool isConnected =  await checkConnectivity();
  //   if (isConnected==false)
  //     {
  //       if (GetStorage().read('stockFull') != null) {
  //         List _stockFull = GetStorage().read('stockFull');
  //
  //         _stockFull.forEach((j) {
  //           if (item == j["itemCode"]) {
  //             _stockTemp.add(j);
  //             print("_stock $_stock");
  //           }
  //         });
  //       }
  //       setState(() {
  //         _stock = _stockTemp;
  //       });
  //
  //   } else {
  //     final String apiUrl = 'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
  //         empresa + '?itemcode=' + item + '&whscode=0&slpcode='+usuario;
  //     http://wali.igbcolombia.com:8080/manager/res/app/stock-current/IGB?itemcode=ED0023&whscode=0&slpcode=22
  //     print (apiUrl);
  //     final response = await http.get(Uri.parse(apiUrl));
  //     Map<String, dynamic> resp = jsonDecode(response.body);
  //     //print ("REspuesta stock: --------------------");
  //     //print(resp.toString());
  //     final data = resp["content"];
  //     //print(data.toString());
  //     if (!mounted) return;
  //     setState(() {
  //       _stock = data;
  //     });
  //   }
  // }

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
    var _bodegas1 = [];
    var fullStock = 0;

    if (itemsGuardados.length > 0) {
      List _stockTemp = [];
      //print("itemcode index");
      //print(itemsGuardados[index]["itemCode"]);
      if (GetStorage().read('stockFull') != null) {
        _stockFull = GetStorage().read('stockFull');
        //print("stockFULL: ");
        //print(_stockFull);
        _stockFull.forEach((j) {
          if (itemsGuardados[index]["itemCode"] == j["itemCode"]) {
            _stockTemp.add(j);
            //print("encontrado item en stock local");
          } //else {print("no ENCONTRADO");}
        });
        setState(() {
          _stock = _stockTemp;
        });
      }
    }

    if (_stock.length > 0) {
      _inventario = _stock[0]['stockWarehouses'];
      fullStock = _stock[0]['stockFull'];
    }

    num stockSuma = 0;
    int mayor = 0;
    for (var bodega in _inventario) {
      if (bodega['quantity'] > 0 && bodega['whsCode'] == zona) {
        stockItem = bodega['whsCode'];
        fullStock = bodega['quantity'];
      } else {
        stockItem = itemsGuardados[index]["whsCode"];
        stockSuma = stockSuma + bodega['quantity'];
      }
    }

    String precioTxt = numberFormat.format(itemsGuardados[index]['price']);
    if (precioTxt.contains('.')) {
      int decimalIndex = precioTxt.indexOf('.');
      precioTxt = precioTxt.substring(0, decimalIndex);
    }

    return AlertDialog(
      title: Text(
        itemsGuardados[index]['itemName'],
        style: TextStyle(fontSize: 18),
      ),
      content: Text(
        'Sku: ' + itemsGuardados[index]['itemCode'],
        textAlign: TextAlign.right,
      ),
      actions: <Widget>[
        Text('Stock: ' + fullStock.toString()),
        Text('Precio: ' + precioTxt),
        SizedBox(
            //height: 40,
            width: 200,
            child: TextField(
              onChanged: (text) {
                RegExp regex = RegExp(r'0+[1-9]');
                if (text.length == 0) {
                  setState(() {
                    btnAgregarActivo = false;
                  });
                }
                if (text.isEmpty) {
                  btnAgregarActivo = false;
                } else {
                  if (!areAllCharactersNumbers(text)) {
                    setState(() {
                      mensaje = "La cantidad debe ser un número ";
                      textoVisible = true;
                      btnAgregarActivo = false;
                    });
                  } else {
                    if (int.parse(text) > fullStock) {
                      setState(() {
                        mensaje =
                            "Cantidad ingresada es mayor al stock disponible";
                        textoVisible = true;
                        btnAgregarActivo = false;
                        //print("mensaje:");
                        //print(mensaje);
                      });
                    } else {
                      if (int.parse(text) < 1) {
                        setState(() {
                          mensaje = "Cantidad ingresada debe ser mayor a 0";
                          textoVisible = true;
                          btnAgregarActivo = false;
                        });
                      } else {
                        if (regex.hasMatch(text)) {
                          setState(() {
                            mensaje =
                                "Cantidad ingresada contiene ceros a la izquierda";
                            textoVisible = true;
                            btnAgregarActivo = false;
                          });
                        } else {
                          setState(() {
                            mensaje = "";
                            textoVisible = false;
                            btnAgregarActivo = true;
                          });
                        }
                      }
                    }
                  }
                }
              },
              style: const TextStyle(color: Colors.black),
              controller: cantidadController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Por favor ingrese cantidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.all(15),
                hintStyle: const TextStyle(color: Colors.black, fontSize: 10),
              ),
            )),
        SizedBox(
          height: 10,
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
                        setState(() {
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
                          itemTemp["discountItem"] =
                              itemsGuardados[index]["discountItem"].toString();
                          itemTemp["discountPorc"] =
                              itemsGuardados[index]["discountPorc"].toString();
                          itemTemp["whsCode"] = stockItem;
                          itemTemp["iva"] =
                              itemsGuardados[index]["iva"].toString();
                          itemsPedido.add(itemTemp);

                          int precioI = itemsGuardados[index]["price"];
                          double precioD = precioI.toDouble();
                          int discountI = itemsGuardados[index]["discountPorc"];
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
                            whsCode: stockItem,
                            presentation: itemsGuardados[index]["presentation"],
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
                            itemsPedidoLocal = GetStorage().read('itemsPedido');
                            //// VALIDAR SI EL ITME SELECCIONADO YA ESTÁ,ENTONCES SE SUMA LA CANTIDAD
                            int repetido = 0;
                            itemsPedidoLocal.forEach((j) {
                              if (itemTemp["itemCode"] == j["itemCode"]) {
                                int cant = 0;
                                cant = int.parse(j["quantity"]!) +
                                    int.parse(itemTemp["quantity"]!);
                                j["quantity"] = cant.toString();
                                repetido = 1;
                              }
                            });
                            if (repetido == 0) {
                              itemsPedidoLocal.add(itemTemp);
                            }
                            storage.write('itemsPedido', itemsPedidoLocal);
                          }
                          storage.write('index', index);
                        });
                        Navigator.pop(context);
                      }
                    : null,
              ),
            ]),
        SizedBox(
          height: 10,
        ),
        Visibility(
            visible: textoVisible,
            child: Center(
              child: Material(
                elevation: 5,
                color: Colors.grey,
                borderRadius: BorderRadius.horizontal(),
                child: Container(
                  width: 250,
                  height: 40,
                  child: Center(
                    child: Text(
                      mensaje,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            )
            //Text("Cantidad ingresa es mayor al stock disponible")
            )
      ],
    );
  }
}

class DetallePedido extends StatefulWidget {
  @override
  _DetallePedidoState createState() => new _DetallePedidoState();
}

class _DetallePedidoState extends State<DetallePedido> {
  //var itemsPedidoLocal = <Map<String, String>>[];
  List<dynamic> itemsPedidoLocal = [];
  List listaItems = [];
  num subtotalDetalle = 0;
  num iva = 0;
  num totalDetalle = 0;
  int borrar = 0;
  //final numberFormat = NumberFormat.currency(locale: 'es.CO', symbol:"\$");
  final numberFormat = new NumberFormat.simpleCurrency();
  int cantidadAdicionalItem = 0;
  GetStorage storage = GetStorage();
  List _stock2 = [];
  List _stockFull2 = [];
  var fullStock = 0;
  var stockItem;

  void _mostrarDialogoCantidad(BuildContext context) {}

  void borrarItemDetalle(String item) {
    itemsPedidoLocal = GetStorage().read('itemsPedido');
    itemsPedidoLocal.forEach((j) {
      if (j['itemCode'] == item) {
        itemsPedidoLocal.remove(j);
      }
    });
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
                setState(() {
                  itemsPedidoLocal.clear();
                  storage.remove('itemsPedido');
                });
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
      //barrierDismissible: false,
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
                setState(() {
                  itemsPedidoLocal.forEach((j) {
                    if (j['itemCode'] == itemCode) {
                      itemsPedidoLocal.remove(j);
                    }
                  });
                });
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
      //print("si hay items ");
      listaItems = [];
      itemsPedidoLocal.forEach((j) {
        listaItems.add(j);
      });
    }
    return SafeArea(
      child: listaItems.isEmpty
          ? Text("\n\n\n        Sin ítems")
          : Column(
              children: [
                //SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Alinea en el centro horizontal
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        showAlertDetailItems(
                            context, "¿Está seguro de borrar todos los ítems?");
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
                //SizedBox(height: 5.0),
                Expanded(
                    child: ListView.builder(
                  itemCount: listaItems.length,
                  itemBuilder: (context, index) {
                    subtotalDetalle = double.parse(listaItems[index]['price']) *
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
                    String totalDetalleTxt = numberFormat.format(totalDetalle);
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
                              // Columna de íconos en la izquierda
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
                                              "?");
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
                                        _stockFull2.forEach((j) {
                                          if (listaItems[index]["itemCode"] ==
                                              j["itemCode"]) {
                                            _stockTemp.add(j);
                                          }
                                        });
                                        setState(() {
                                          _stock2 = _stockTemp;
                                        });
                                      }
                                      if (_stock2.length > 0) {
                                        _inventario =
                                            _stock2[0]['stockWarehouses'];
                                        fullStock = _stock2[0]['stockFull'];
                                      }
                                      num stockSuma = 0;
                                      int mayor = 0;

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
                                        cant1 = double.parse(
                                                listaItems[index]['quantity']) +
                                            1;
                                        listaItems[index]['quantity'] =
                                            cant1.toInt().toString();
                                      } else {
                                        //////////////
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
                                            }); //////
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
                                        _stockFull2.forEach((j) {
                                          if (listaItems[index]["itemCode"] ==
                                              j["itemCode"]) {
                                            _stockTemp.add(j);
                                          }
                                        });
                                        setState(() {
                                          _stock2 = _stockTemp;
                                        });
                                      }
                                      if (_stock2.length > 0) {
                                        _inventario =
                                            _stock2[0]['stockWarehouses'];
                                        fullStock = _stock2[0]['stockFull'];
                                      }

                                      num stockSuma = 0;
                                      int mayor = 0;

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
                                                  "La cantidad de ítems es menor a 1"),
                                              actions: [
                                                TextButton(
                                                  child: Text("Aceptar"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
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
                              SizedBox(width: 16.0), // Espacio entre columnas
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
                                        'Subtotal: ' +
                                        subtotalDetalleTxt +
                                        '\n' +
                                        'Iva: ' +
                                        ivaTxt +
                                        '\n' +
                                        'Total: ' +
                                        totalDetalleTxt,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )),
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

  bool btnPedidoActivo = true;
  bool btnGuardadActivo = true;

  bool cargando = false;
  final numberFormat = new NumberFormat.simpleCurrency();
  Connectivity _connectivity = Connectivity();
  String textoObservaciones = "";
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
    String fechaPedido = fecha.toString() +
        pedidoFinal['cardCode'].toString() +
        formatter.toString();
    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.deleteAllItemsP();
    dbHelper.deleteAllItems();

    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'cardCode': pedidoFinal['cardCode'],
        "comments": observacionesController.text,
        "companyName": empresa,
        "numAtCard": fechaPedido,
        "shipToCode": dirEnvio,
        "payToCode": pedidoFinal['payToCode'],
        "slpCode": pedidoFinal['slpCode'],
        "discountPercent": pedidoFinal['discountPercent'].toString(),
        "docTotal": pedidoFinal['docTotal'],
        "lineNum": pedidoFinal['lineNum'],
        "detailSalesOrder": GetStorage().read('itemsPedido'),
      }),
    );
  }

  Future<http.Response> _enviarPedidoGuardado(
      BuildContext context, Map<String, dynamic> pedidoFinal) {
    final String url =
        'http://wali.igbcolombia.com:8080/manager/res/app/save-order';
    var dirEnvio = GetStorage().read('dirEnvio');

    DateTime now = DateTime.now();
    String formatter = DateFormat('hhmm').format(now);
    formatter = formatter.replaceAll(":", "");
    String fecha = DateFormat("yyyyMMdd").format(now);
    String fechaPedido = fecha.toString() +
        pedidoFinal['cardCode'].toString() +
        formatter.toString();
    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        "cardCode": pedidoFinal['cardCode'],
        "comments": observacionesController.text,
        "companyName": empresa,
        "numAtCard": fechaPedido,
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
      }),
    );
  }

  Future<http.Response> _enviarPedidoTemp(
      BuildContext context, Map<String, dynamic> pedidoFinal) {
    final String url = 'http://179.50.4.120:8580/igb/igb.php';
    //DateFormat formatter = DateFormat('hhmm');
    DateTime now = DateTime.now();
    //String formatter = DateFormat.Hms().format(now);
    String formatter = DateFormat('hhmm').format(now);
    formatter = formatter.replaceAll(":", "");
    String fecha = DateFormat("yyyyMMdd").format(now);
    String fechaPedido = fecha.toString() +
        pedidoFinal['cardCode'].toString() +
        formatter.toString();
    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.deleteAllItems();
    return http.post(
      Uri.parse(url),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'cardCode': pedidoFinal['cardCode'],
        "comments": observacionesController.text,
        "companyName": "IGB",
        "numAtCard": fechaPedido,
        "shipToCode": pedidoFinal['shipToCode'],
        "payToCode": pedidoFinal['payToCode'],
        "slpCode": pedidoFinal['slpCode'],
        "discountPercent": pedidoFinal['discountPercent'].toString(),
        "docTotal": pedidoFinal['docTotal'],
        "lineNum": pedidoFinal['lineNum'],
        "detailSalesOrder": GetStorage().read('itemsPedido'),
      }),
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
      setState(() {
        storage.write("stockFull", _stockFull);
      });
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
                btnGuardadActivo = true;
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
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
                  MaterialPageRoute(builder: (context) => HomePage()),
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
                        setState(() {
                          btnConfirmarEnvio = false;
                        });
                        Navigator.pop(context);
                      }
                    : null,
                child: Text("No"),
              ),
              ElevatedButton(
                onPressed: btnConfirmarEnvio
                    ? () async {
                        setState(() {
                          btnConfirmarEnvio = false;
                          message = 'Guardando pedido. Por favor espere...';
                        });

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

                        setState(() {
                          cargando = true;
                        });

                        try {
                          http.Response response =
                              await _enviarPedidoGuardado(context, pedidoFinal);
                          Map<String, dynamic> resultado =
                              jsonDecode(response.body);

                          if (response.statusCode == 200 &&
                              resultado['content'] != "") {
                            Navigator.pop(context);
                            setState(() {
                              showAlertPedidoEnviado(
                                  context,
                                  "Pedido Guardado: " +
                                      resultado['content'].toString());
                            });
                            //modificar el estado del pedido editado a cerrado
                            setState(() {
                              actualizarEstadoPed(
                                  GetStorage().read('pedidoGuardado')['id'],
                                  0,
                                  'C');
                            });
                          } else {
                            showAlertError(context,
                                "No se pudo guardar el pedido, error de red, verifique conectividad por favor");
                          }
                        } catch (e) {
                          setState(() {
                            Get.snackbar('Error',
                                'El servicio no responde, contacte al administrador',
                                colorText: Colors.red,
                                backgroundColor: Colors.white);
                          });
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
        });
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
                        setState(() {
                          btnConfirmarEnvio = false;
                        });
                        Navigator.pop(context);
                      }
                    : null,
                child: Text("No"),
              ),
              ElevatedButton(
                onPressed: btnConfirmarEnvio
                    ? () async {
                        setState(() {
                          btnConfirmarEnvio = false;
                          message = 'Procesando pedido. Por favor espere...';
                        });

                        bool isConnected = await checkConnectivity();
                        if (isConnected == true) {
                          pedidoFinal['comments'] =
                              observacionesController.text;
                          storage.write('pedido', pedidoFinal);
                          setState(() {
                            cargando = true;
                          });
                          http.Response response =
                              await _enviarPedido(context, pedidoFinal);
                          Map<String, dynamic> resultado =
                              jsonDecode(response.body);

                          if (response.statusCode == 200 &&
                              resultado['content'] != "") {
                            Navigator.pop(context);
                            setState(() {
                              showAlertPedidoEnviado(context,
                                  "Pedido: " + resultado['content'].toString());
                            });

                            Map<String, dynamic> actualizarPedidoGuardado = {};
                            if (GetStorage().read('actualizarPedidoGuardado') !=
                                null) {
                              actualizarPedidoGuardado =
                                  GetStorage().read('actualizarPedidoGuardado');
                              setState(() {
                                actualizarEstadoPed(
                                    int.parse(actualizarPedidoGuardado["id"]),
                                    resultado['content'],
                                    'F');
                              });
                            }

                            storage.remove("pedido");
                            storage.remove("itemsPedido");
                            storage.remove("dirEnvio");
                            storage.remove("pedidoGuardado");
                            storage.write('estadoPedido', 'nuevo');
                            btnPedidoActivo = true;

                            setState(() {
                              cargando = true;
                            });
                          } else {
                            Get.snackbar('Error', 'No se pudo crear el pedido',
                                colorText: Colors.red,
                                backgroundColor: Colors.white);
                          }
                        } else {
                          showAlertError(context,
                              "No se pudo enviar el pedido, error de red, verifique conectividad por favor");
                        }
                      }
                    : null,
                child: Text("Si"),
              )
            ],
          );
        });
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

  void _clearCache() {
    // Eliminamos todos los archivos de caché.
    for (final file in Directory('cache').listSync()) {
      file.delete();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (GetStorage().read('pedido') != null) {
      Map<String, dynamic> pedidoFinal = GetStorage().read('pedido');
      if (GetStorage().read('pedidoGuardado') != null) {
        Map<String, dynamic> pedidoFinalG = GetStorage().read('pedidoGuardado');
        pedidoFinal['comments'] = pedidoFinalG['comments'] ?? '';
      }
      //var itemsPedidoLocal = <Map<String, String>>[];
      List<dynamic> itemsPedidoLocal = [];
      List itemsGuardados = [];
      int cantidadItems = 0;
      num subtotal = 0;
      int cantidad = 0;

      String obs = "";
      if (GetStorage().read('observaciones') != null) {
        obs = GetStorage().read('observaciones');
        observacionesController.text = obs;
      }

      // observacionesController.text = textoObservaciones;
      //print ("pedido final desde pedidoGuardado");print (pedidoFinal);

      if (GetStorage().read('itemsPedido') == null) {
      } else {
        itemsPedidoLocal = GetStorage().read('itemsPedido');
      }
      if (GetStorage().read('items') == null) {
      } else {
        /////BUSCAR itemCode en lista de items para hallar el precio
        itemsGuardados = GetStorage().read('items');
        itemsPedidoLocal.forEach((j) {
          itemsGuardados.forEach((k) {
            String cantQ = j['quantity'];
            double cantidadQ = double.parse(cantQ);
            if (k['itemCode'] == j['itemCode']) {
              subtotal = subtotal + k['price'] * cantidadQ;
            }
          });
        });
      }
      if (GetStorage().read('itemsPedido') == null) {
        cantidadItems = 0;
      } else {
        itemsPedidoLocal = GetStorage().read('itemsPedido');
        cantidadItems = itemsPedidoLocal.length;
      }
      double iva = 0.0;

      itemsPedidoLocal.forEach((element) {
        //print(element["iva"].toString());
        var subt =
            double.parse(element["price"]) * double.parse(element["quantity"]);
        var ivaTemp =
            (double.parse(element["iva"].toString()) * subt.toDouble()) / 100;
        iva = iva + ivaTemp;
      });

      String ivaTxt = numberFormat.format(iva);
      double total = subtotal.toDouble() + iva;
      String subtotalTxt = numberFormat.format(subtotal);
      String totalTxt = numberFormat.format(total);
      String estadoPedido = "";
      if (ivaTxt.contains('.')) {
        int decimalIndex = ivaTxt.indexOf('.');
        ivaTxt = ivaTxt.substring(0, decimalIndex);
      }
      if (subtotalTxt.contains('.')) {
        int decimalIndex = subtotalTxt.indexOf('.');
        subtotalTxt = subtotalTxt.substring(0, decimalIndex);
      }

      if (pedidoFinal['comments'].toString() != null) {
        textoObservaciones = pedidoFinal['comments'];
        if (GetStorage().read('estadoPedido') != null) {
          estadoPedido = GetStorage().read('estadoPedido');
        } else {
          estadoPedido = "desconocido";
        }
        if (estadoPedido != "nuevo") {
          String obs = textoObservaciones;
          // observacionesController.text = textoObservaciones;
          observacionesController.text = obs;
        }
      }

      // if (totalTxt.contains('.')) {
      //   int decimalIndex = totalTxt.indexOf('.');
      //   totalTxt = subtotalTxt.substring(0, decimalIndex);
      // }

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
                                pedidoFinal['nit'] +
                                    ' - ' +
                                    pedidoFinal['cardName'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                                "Cantidad de items: " +
                                    cantidadItems.toString(),
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 10,
                            ),
                            Text("Subtotal: " + subtotalTxt,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 10,
                            ),
                            Text("Descuento: " + pedidoFinal['discountPercent'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 10,
                            ),
                            Text("Iva: " + ivaTxt,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 10,
                            ),
                            Text("Total: " + totalTxt,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 20,
                            ),
                          ])),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("Observaciones:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                  //height: 40,
                  width: 400,
                  child: TextField(
                    maxLines: 7,
                    controller: observacionesController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction
                        .newline, // Cambiar la acción al presionar "Enter"
                    onChanged: (text) {
                      pedidoFinal['comments'] = observacionesController.text;
                      pedidoFinal['id'] = text;
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
                  )),
            ),
            SizedBox(
              height: 20,
            ),
            Row(children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(30, 129, 235, 1))),
                    onPressed: () {
                      if (GetStorage().read('dirEnvio') == null ||
                          GetStorage().read('dirEnvio') == "" ||
                          GetStorage().read('dirEnvio') == "Elija un destino") {
                        showAlertErrorDir(context,
                            "Obligatorio seleccionar la dirección de destino");
                      } else if (GetStorage().read('itemsPedido') == null ||
                          GetStorage().read('itemsPedido') == "") {
                        showAlertErrorDir(
                            context, "Obligatorio agregar ítems en detalle");
                      } else {
                        showAlertConfirmOrder(context, pedidoFinal, true,
                            "¿Está seguro que deseea enviar el pedido?");
                      }
                    },
                    child: Text('Enviar Pedido',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(30, 129, 235, 1))),
                    onPressed: btnGuardadActivo
                        ? () async {
                            String responseMessage = '';
                            int responseCode = 0;
                            btnGuardadActivo = false;

                            if (GetStorage().read('dirEnvio') == null ||
                                GetStorage().read('dirEnvio') == "" ||
                                GetStorage().read('dirEnvio') ==
                                    "Elija un destino") {
                              showAlertErrorDir(context,
                                  "Obligatorio seleccionar la dirección de destino");
                            } else if (GetStorage().read('itemsPedido') ==
                                    null ||
                                GetStorage().read('itemsPedido') == "") {
                              showAlertErrorDir(context,
                                  "Obligatorio agregar ítems en detalle");
                            } else {
                              showAlertConfirmOrderForSave(
                                  context,
                                  pedidoFinal,
                                  true,
                                  "¿Está seguro que deseea guardar el pedido?");
                            }
                          }
                        : null,
                    child: Text('Guardar Pedido',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              /*Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(30, 129, 235, 1))),
                    onPressed: () {
                      DatabaseHelper dbHelper = DatabaseHelper();
                      dbHelper.deleteAllItemsP();
                      dbHelper.deleteAllItems();
                      requestStoragePermission();
                      //deleteAppData();
                    },
                    child: Text('Borrar Cache',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),*/
            ]),
          ],
        ),
      );
    } else
      return Text("Sin ítems para pedido");
  }
}
