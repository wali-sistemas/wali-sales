import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:productos_app/models/DatabaseHelper.dart';
import 'pedidos_screen.dart';
import 'package:http/http.dart' as http;
import 'package:productos_app/icomoon.dart';

List itemsGuardados = [];
List<String> allNames = [''];
List<String> allNames2 = [''];
var mainColor = Color(0xff1B3954);
var textColor = Color(0xff727272);
var accentColor = Color(0xff16ADE1);
var whiteText = Color(0xffF5F5F5);
List _stockB = [];

class CustomSearchDelegate extends SearchDelegate {
  var suggestion = [''];
  List<String> searchResult = [];
  TextEditingController cantidadController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
  GetStorage storage = GetStorage();
  List _itemsBuscador = [];
  List _itemsBuscador2 = [];
  String empresa = GetStorage().read('empresa');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List _inventario = [];

    if (GetStorage().read('items') == null) {
    } else {
      _itemsBuscador.clear();
      itemsGuardados = GetStorage().read('items');
      itemsGuardados.forEach(
        (k) {
          allNames.add(k['itemName'].toString().toLowerCase());

          List<String> palabras = query.split(' ');
          if (palabras.isEmpty) palabras.add(query);
          int n = 0;
          palabras.forEach(
            (element) {
              if (k['itemName']
                      .toLowerCase()
                      .contains(element.trim().toLowerCase()) ||
                  k['itemCode']
                      .toLowerCase()
                      .contains(element.trim().toLowerCase())) {
                n++;
              }
            },
          );
          if (n == palabras.length) _itemsBuscador.add(k);
        },
      );
    }
    searchResult.clear();

    searchResult = allNames
        .where((element) =>
            element.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();

    return Container(
      margin: EdgeInsets.all(20),
      child: ListView.builder(
        itemCount: _itemsBuscador.length,
        itemBuilder: (context, indexB) {
          if (_stockB.length > 0) {
            _inventario = _stockB[0]['stockWarehouses'];
          }

          var listaBodegas = ['Elija una Bodega'];
          for (var bodega in _inventario) {
            listaBodegas.add('Bodega: ' +
                bodega['whsCode'].toString() +
                ': ' +
                bodega['quantity'].toString());
          }
          return Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  _itemsBuscador[indexB]['itemName'],
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                subtitle: Text('Sku: ' + _itemsBuscador[indexB]['itemCode']),
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return DetailScreen(
                            _itemsBuscador[indexB]['pictureUrl'],
                          );
                        },
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: _itemsBuscador[indexB]['pictureUrl'],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.image_not_supported_outlined),
                    maxHeightDiskCache: 300,
                    maxWidthDiskCache: 300,
                    memCacheHeight: 300,
                    memCacheWidth: 300,
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: () {
                    int i = 0;
                    int indexSeleccionado = 0;
                    itemsGuardados.forEach(
                      (item) {
                        if (_itemsBuscador[indexB]['itemCode'] ==
                            item['itemCode']) {
                          indexSeleccionado = i;
                        }
                        i++;
                      },
                    );
                    storage.write('index', indexSeleccionado);
                    showDialog(
                      context: context,
                      builder: (_) {
                        return MyDialog();
                      },
                    );
                  },
                  label: const Text(''),
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (GetStorage().read('items') == null) {
    } else {
      _itemsBuscador2.clear();
      allNames2.clear();

      itemsGuardados = GetStorage().read('items');
      itemsGuardados.forEach(
        (k) {
          allNames2.add(k['itemName'].toString().toLowerCase());

          List<String> palabras2 = query.split(' ');
          if (palabras2.isEmpty) palabras2.add(query);

          int m = 0;
          palabras2.forEach(
            (element2) {
              if (element2.length > 1) {
                if (k['itemName']
                    .toLowerCase()
                    .contains(element2.toLowerCase())) {
                  m++;
                }
              }
            },
          );
          if (m == palabras2.length) {
            _itemsBuscador2.add(k);
          }
          palabras2.clear();
        },
      );
    }

    if (query == '' || query == ' ') {
      _itemsBuscador2.clear();
    }

    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          if (query.isEmpty) {
            query = suggestion[index];
          }
        },
        leading: Icon(query.isEmpty ? Icons.history : Icons.search),
        trailing: TextButton.icon(
          onPressed: () {
            int i = 0;
            int indexSeleccionado = 0;
            itemsGuardados.forEach(
              (item) {
                if (_itemsBuscador2[index]['itemCode'] == item['itemCode']) {
                  indexSeleccionado = i;
                }
                i++;
              },
            );

            storage.write('index', indexSeleccionado);
            showDialog(
              context: context,
              builder: (_) {
                return MyDialog();
              },
            );
          },
          label: const Text(''),
          icon: const Icon(Icons.add),
        ),
        title: RichText(
          text: TextSpan(
            text: _itemsBuscador2[index]['itemName'] +
                '\n' +
                _itemsBuscador2[index]['itemCode'],
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      itemCount: _itemsBuscador2.length,
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
  GetStorage storage = GetStorage();
  bool textoVisible = false;
  TextEditingController cantidadController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
  List<dynamic> itemsPedidoLocal = [];
  List<dynamic> itemsPedido = [];
  String dropdownvalueBodega = 'Elija una bodega';
  String empresa = GetStorage().read('empresa');
  String mensaje = '';
  bool btnSoldOutActivo = false;
  final numberFormat = new NumberFormat.simpleCurrency();
  var whsCodeStockItem;
  String zona = '';
  String usuario = GetStorage().read('usuario');
  List _stockFull = [];
  int idPedidoDb = 0;
  int idLocal = 0;
  int fullStock = 0;
  FocusNode _focusNode = FocusNode();

  Connectivity _connectivity = Connectivity();
  final itemTemp = {
    'quantity': '',
    'itemCode': '',
    'itemName': '',
    'group': '',
    'whsCode': '',
    'presentation': '',
    'price': '',
    'discountItem': '',
    'discountPorc': '',
    'iva': ''
  };
  final actualizarPedidoGuardado = {'id': '', 'docNum': ''};

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  Future<void> _listarItems() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/items/' + empresa;
    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    final data = resp['content'];
    if (!mounted) return;
    setState(
      () {
        _items = data;
        storage.write('items', _items);
      },
    );
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
    final codigoError = resp['code'];
    if (codigoError == 0) {
      final data = resp['content'];
      return data[0]['stockFull'];
    } else {
      return 0;
    }
  }

  bool isDigit(String character) {
    return character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;
  }

  bool areAllCharactersNumbers(String text) {
    if (text.isEmpty) {
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
    if (insertedItemId > 0) {
      //print('El item ha sido insertado con éxito con el ID: $insertedItemId');
    }
  }

  Future<void> listarItemDb() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Item> items = await dbHelper.getItems();

    if (items.isNotEmpty) {
      for (Item item in items) {
        // print('ID: ${item.id}');
        // print('ID Pedido: ${item.idPedido}');
        // print('Quantity: ${item.quantity}');
        // print('--------------------------');
      }
    }
  }

  Future<void> listarPedidos() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Pedido> pedidos = await dbHelper.getPedidos();

    if (pedidos.isNotEmpty) {
      for (Pedido pedido in pedidos) {
        //print('ID: ${pedido.id}');
        //print('Cardcode: ${pedido.cardCode}');
        //print('Nombre: ${pedido.cardName}');
        // ... Mostrar los demás atributos del item ...
        //print('--------------------------');
      }
    }
  }

  Future<void> insertPedidoDb() async {
    Pedido newPedido = Pedido(
      cardCode: 'C12345',
      cardName: 'Cliente Ejemplo',
      comments: 'Pedido de prueba',
      companyName: 'Empresa Ejemplo',
      numAtCard: '123456',
      shipToCode: 'S123',
      payToCode: 'P123',
      slpCode: 5,
      discountPercent: 0.1,
      docTotal: 100.0,
      lineNum: 'L001',
      detailSalesOrder: 'Detalle del pedido',
    );

    // Insertar el nuevo pedido en la base de datos y obtener el ID asignado
    DatabaseHelper dbHelper = DatabaseHelper();
    int insertedPedidoId = await dbHelper.insertPedido(newPedido);

    if (insertedPedidoId > 0) {
      //print('El pedido ha sido insertado con éxito con el ID: $insertedPedidoId');
    } else {
      //print('Error al insertar el pedido en la base de datos');
    }
    idPedidoDb = insertedPedidoId;
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<http.Response> _addItemSoldOut(String itemCode, String itemName,
      int quantity, String origen, String whsName) {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/add-item-sold-out';

    return http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          'itemCode': itemCode,
          'itemName': itemName,
          'quantity': quantity,
          'slpCode': usuario,
          'companyName': empresa,
          'origen': origen,
          'whsName': whsName
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var bodegas = [''];
    bool isVisibleBod = false;

    if (GetStorage().read('items') == null) {
      _listarItems();
    } else {
      itemsGuardados = GetStorage().read('items');
    }

    if (GetStorage().read('zona') == null) {
      zona = '01';
    } else {
      zona = GetStorage().read('zona');
    }

    if (GetStorage().read('index') == null) {
      index = 0;
    } else {
      index = GetStorage().read('index');
    }
    //Activar seleccion de bodega para las llantas
    if (itemsGuardados[index]['grupo'] == 'LLANTAS' &&
        itemsGuardados[index]['marca'] == 'XCELINK') {
      bodegas = ['Elija una bodega', 'CARTAGENA', 'CALI'];
      isVisibleBod = true;
    }
    //Activar seleccion de bodega para los lubricantes de REVO bodega 35-MAGNUN BOGOTA y 01-CEDI MEDELLÍN
    if (itemsGuardados[index]['subgrupo'] == 'LUBRICANTES' &&
        itemsGuardados[index]['marca'] == 'REVO') {
      bodegas = ['Elija una bodega', 'MEDELLÍN', 'BOGOTÁ'];
      isVisibleBod = true;
    }
    //Activar seleccion de bodega para las llantas TIMSUN bodega 35-MAGNUN BOGOTA, 26-MAGNUN CALI, 05-MAGNUM CARTAGENA y 45-ALMAVIVA MEDELLÍN
    if (itemsGuardados[index]['grupo'] == 'LLANTAS' &&
        itemsGuardados[index]['marca'] == 'TIMSUN') {
      bodegas = ['Elija una bodega', 'CARTAGENA', 'CALI', 'BOGOTÁ', 'MEDELLÍN'];
      isVisibleBod = true;
    }

    if (itemsGuardados.length > 0) {
      List _stockTemp = [];
      if (GetStorage().read('stockFull') != null) {
        _stockFull = GetStorage().read('stockFull');
        _stockFull.forEach(
          (j) {
            if (itemsGuardados[index]['itemCode'] == j['itemCode']) {
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
        whsCodeStockItem = itemsGuardados[index]['whsCode'];
        stockSuma = stockSuma + bodega['quantity'];
      }
    }

    String precioTxt = numberFormat.format(itemsGuardados[index]['price'] +
        (itemsGuardados[index]['price'] * 0.19));
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
              Text('Sku: ' + itemsGuardados[index]['itemCode']),
            ],
          ),
        ),
        SizedBox(
          child: Text('Stock: ' + fullStock.toString()),
        ),
        SizedBox(
          child: Text('Precio Incl. IVA 19%: ' + precioTxt),
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
                          if (empresa == 'VARROC') {
                            whsCode = '13';
                          } else {
                            whsCode = '05';
                          }
                          break;
                        case 'CALI':
                          whsCode = '26';
                          break;
                        case 'MEDELLÍN':
                          if (itemsGuardados[index]['grupo'] == 'LLANTAS' &&
                              itemsGuardados[index]['marca'] == 'TIMSUN') {
                            whsCode = '45';
                          } else if (itemsGuardados[index]['subgrupo'] ==
                                  'LUBRICANTES' &&
                              itemsGuardados[index]['marca'] == 'REVO') {
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
              if (empresa != 'REDPLAS') {
                RegExp regex = RegExp(r'0+[1-9]');
                if (text.length == 0) {
                  setState(
                    () {
                      btnSoldOutActivo = false;
                    },
                  );
                }
                if (text.isEmpty) {
                  btnSoldOutActivo = false;
                } else {
                  if (!areAllCharactersNumbers(text)) {
                    setState(
                      () {
                        mensaje = 'Cantidad debe ser numérica';
                        textoVisible = true;
                        btnSoldOutActivo = false;
                      },
                    );
                  } else {
                    if (regex.hasMatch(text)) {
                      setState(
                        () {
                          mensaje = 'Cantidad contiene 0 a la izq';
                          textoVisible = true;
                          btnSoldOutActivo = false;
                        },
                      );
                    } else {
                      if (int.parse(text) < 1) {
                        setState(
                          () {
                            mensaje = 'Cantidad debe ser mayor a 0';
                            textoVisible = true;
                            btnSoldOutActivo = false;
                          },
                        );
                      } else {
                        if (int.parse(text) > fullStock) {
                          setState(
                            () {
                              btnSoldOutActivo = true;
                            },
                          );
                        } else {
                          setState(
                            () {
                              mensaje = '';
                              textoVisible = false;
                              btnSoldOutActivo = false;
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
                    mensaje = '';
                    textoVisible = false;
                    btnSoldOutActivo = true;
                  },
                );
              }
            },
            style: const TextStyle(color: Colors.black),
            controller: cantidadController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Cant agotada',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              contentPadding: const EdgeInsets.all(5),
              hintStyle: const TextStyle(
                color: Colors.grey,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icomoon.soldOut,
              ),
              color: Colors.black,
              iconSize: 36,
              onPressed: btnSoldOutActivo
                  ? () async {
                      var whsName = dropdownvalueBodega == 'Elija una bodega'
                          ? 'CEDI'
                          : dropdownvalueBodega;

                      http.Response response = await _addItemSoldOut(
                          itemsGuardados[index]['itemCode'],
                          itemsGuardados[index]['itemName'],
                          int.parse(cantidadController.text),
                          'CATALOGO',
                          whsName);
                      bool res = jsonDecode(response.body);
                      if (res) {
                        setState(
                          () {
                            mensaje = 'Agotado reportado con éxito';
                            textoVisible = true;
                            btnSoldOutActivo = false;
                            cantidadController.text = '';
                          },
                        );
                      } else {
                        setState(
                          () {
                            mensaje = 'No se pudo reportar el agotado';
                            textoVisible = true;
                            btnSoldOutActivo = true;
                            cantidadController.text = '';
                          },
                        );
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
