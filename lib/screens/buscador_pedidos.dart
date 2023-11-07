import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';

List pedidosGuardados = [];
List<String> allNames = ["Cliente"];
List<String> allNames2 = ["Cliente"];
var mainColor = Color(0xff1B3954);
var textColor = Color(0xff727272);
var accentColor = Color(0xff16ADE1);
var whiteText = Color(0xffF5F5F5);

class CustomSearchDelegate extends SearchDelegate {
  var suggestion = ["Cliente"];
  List<String> searchResult = [];
  List _pedidosBusqueda = [];
  List _pedidosBusqueda2 = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');

  Future<void> _fetchData() async {
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/customers/' +
            codigo +
            '/' +
            empresa;

    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);

    final data = resp["content"];
    //print(data.toString());

    _pedidosBusqueda = data;

    /// GUARDAR EN LOCAL STORAGE
    _guardarDatos();
  }

  Future<void> _guardarDatos() async {
    storage.write('ventas', _pedidosBusqueda);
  }

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
    if (GetStorage().read('ventas') == null) {
      //print("allnames VACIO :  *******__________________________________");
    } else {
      _pedidosBusqueda.clear();
      pedidosGuardados = GetStorage().read('ventas');
      //print("pedidosguardados::::::::::::::: ");
      //print(pedidosGuardados);
      pedidosGuardados.forEach((k) {
        allNames.add(k['cardCode'].toString().toLowerCase());
        allNames.add(k['cardName'].toString().toLowerCase());
        allNames.add(k['docNum'].toString().toLowerCase());

        List<String> palabras = query.split(' ');

        //print("PALABRAS: **********______________________///");
        //print(palabras);
        if (palabras.isEmpty) palabras.add(query);
        palabras.forEach((element) {
          if (k['cardCode']
                  .toLowerCase()
                  .contains(element.trim().toLowerCase()) ||
              k['docNum'].toString().contains(element.trim().toLowerCase()) ||
              k['cardName'].toString().contains(element.trim().toLowerCase())) {
            _pedidosBusqueda.add(k);
          }
        });
      });

      //print("allnames buscador:  __________________________________///");
      //print(allNames);
    }
    searchResult.clear();

    searchResult = allNames
        .where((element) =>
            element.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
    //print("searchResult:  ))))))))))))))))");
    //print(searchResult);
    return ListView.builder(
      itemCount: _pedidosBusqueda.length,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                'Fecha: ' +
                    _pedidosBusqueda[index]["docDate"].toString() +
                    ' - Nit: ' +
                    _pedidosBusqueda[index]["cardCode"].toString() +
                    '\n' +
                    'Número pedido: ' +
                    _pedidosBusqueda[index]["docNum"].toString() +
                    '\n' +
                    _pedidosBusqueda[index]["itemCode"].toString(),
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              //subtitle: Text("Nit: "+_pedidosBusqueda[index]['nit']),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _pedidosBusqueda2.clear();

    if (GetStorage().read('ventas') == null) {
      //print("allnames VACIO :  *******__________________________________");
    } else {
      pedidosGuardados = GetStorage().read('ventas');
      pedidosGuardados.forEach((k) {
        allNames2.add(k['cardCode'].toString().toLowerCase());
        if (k['cardCode'].toLowerCase().contains(query.trim().toLowerCase()) ||
            k['docNum'].toString().contains(query.trim().toLowerCase()) ||
            k['cardName'].toString().contains(query.trim().toLowerCase())) {
          _pedidosBusqueda2.add(k);
        }
      });
      if (_pedidosBusqueda2.isEmpty) _pedidosBusqueda2 = [];
    }

    final suggestionList = query.isEmpty
        ? suggestion
        : allNames2.where((element) => element.contains(query)).toList();
    if (query == "") {
      _pedidosBusqueda2 = [];
    }

    //print("_pedidosBusqueda2: ))))))))))))))))))");
    //print(_pedidosBusqueda2);
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          if (query.isEmpty) {
            query = suggestion[index];
          }
        },
        leading: Icon(query.isEmpty ? Icons.history : Icons.search),
        title: RichText(
            text: TextSpan(
          text: 'Fecha: ' +
              _pedidosBusqueda[index]["docDate"].toString() +
              ' - Nit: ' +
              _pedidosBusqueda[index]["cardCode"].toString() +
              '\n' +
              'Número pedido: ' +
              _pedidosBusqueda[index]["docNum"].toString(),
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        )),
      ),
      itemCount: _pedidosBusqueda.length,
    );
  }
}
