import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pedidos_screen.dart';

List itemsGuardados = [];
List<String> allNames = [""];
List<String> allNames2 = [""];
var mainColor = Color(0xff1B3954);
var textColor = Color(0xff727272);
var accentColor = Color(0xff16ADE1);
var whiteText = Color(0xffF5F5F5);
List _itemsBuscador = [];
List _stockB = [];

class CustomSearchDelegate extends SearchDelegate {
  var suggestion = [""];
  List<String> searchResult = [];
  TextEditingController cantidadController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
  GetStorage storage = GetStorage();
  List _itemsBuscador = [];
  List _itemsBuscador2 = [];
  String empresa = GetStorage().read('empresa');

  /*Future<void> _listarStock(String item) async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
            empresa +
            '?itemcode=' +
            item +
            '&whscode=0';

    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);

    final data = resp["content"];

    //if (!mounted) return;
    //setState(() {
    _stockB = data;
    //});
  }*/

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
    var itemsPedidoLocal = <Map<String, String>>[];
    var itemsPedido = <Map<String, String>>[];

    if (GetStorage().read('items') == null) {
      //print("allnames VACIO :  *******__________________________________");
    } else {
      _itemsBuscador.clear();
      itemsGuardados = GetStorage().read('items');
      itemsGuardados.forEach((k) {
        allNames.add(k['itemName'].toString().toLowerCase());

        List<String> palabras = query.split(' ');
        if (palabras.isEmpty) palabras.add(query);
        int n = 0;
        palabras.forEach((element) {
          if (k['itemName']
                  .toLowerCase()
                  .contains(element.trim().toLowerCase()) ||
              k['itemCode']
                  .toLowerCase()
                  .contains(element.trim().toLowerCase())) {
            n++;
          }
        });
        if (n == palabras.length) _itemsBuscador.add(k);
      });
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
          final itemTemp = {
            "quantity": "",
            "itemCode": "",
            "itemName": "",
            "whsCode": ""
          };
          var _bodegas1 = [];

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
                subtitle: Text("Código: " + _itemsBuscador[indexB]['itemCode']),
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) {
                      return DetailScreen(_itemsBuscador[indexB]['pictureUrl']);
                    }));
                  }, // Image tapped
                  child: //Image.network(_items[index]['pictureUrl'], width: 40,height: 40),
                      CachedNetworkImage(
                    imageUrl: _itemsBuscador[indexB]['pictureUrl'],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                //Image.network(_itemsBuscador[indexB]['pictureUrl']),
                trailing: TextButton.icon(
                  onPressed: () {
                    ///BUSCAR ITEM SELLECCIONADO
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

                    storage.write("index", indexSeleccionado);
                    //print(GetStorage().read('index'));
                    //String dropdownvalue = 'Elija una Bodega';
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
      //print("allnames VACIO :  *******__________________________________");
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
                if (k['itemName'].toLowerCase().contains(element2.toLowerCase())
                    // || k['itemCode'].toLowerCase().contains(element2.trim().toLowerCase())
                    ) {
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

// This method is called everytime the search term changes.
// If you want to add search suggestions as the user enters their search term, this is the place to do that.
//     final suggestionList = query.isEmpty
//         ? suggestion
//         : allNames2.where((element) => element.contains(query)).toList();
    if (query == "" || query == " ") {
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
            ///BUSCAR ITEM SELLECCIONADO
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

            storage.write("index", indexSeleccionado);
            //print(GetStorage().read('index'));
            //String dropdownvalue = 'Elija una Bodega';
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
            text: _itemsBuscador2[index]["itemName"] +
                '\n' +
                _itemsBuscador2[index]["itemCode"],
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
      itemCount: _itemsBuscador2.length,
    );
  }
}
