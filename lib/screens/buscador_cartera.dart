import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/screens/cartera.dart';

List carteraGuardados = [];
List<String> allNames = ["Cliente"];
List<String> allNames2 = ["Cliente"];
var mainColor = Color(0xff1B3954);
var textColor = Color(0xff727272);
var accentColor = Color(0xff16ADE1);
var whiteText = Color(0xffF5F5F5);

class CustomSearchDelegateCartera extends SearchDelegate {
  var suggestion = ["Cliente"];
  List<String> searchResult = [];
  List _carteraBusqueda = [];
  List _carteraBusqueda2 = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');

  Future<void> _guardarDatos() async {
    storage.write('datosCartera', _carteraBusqueda);
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
    if (GetStorage().read('datosCartera') == null) {
      //print("allnames VACIO :  *******__________________________________");
    } else {
      _carteraBusqueda.clear();
      carteraGuardados = GetStorage().read('datosCartera');
      carteraGuardados.forEach((k) {
        allNames.add(k['cardName'].toString().toLowerCase());
        if (k['cardName'].toLowerCase().contains(query.trim().toLowerCase()) ||
            k['cardCode'].toLowerCase().contains(query.trim().toLowerCase())) {
          _carteraBusqueda.add(k);
        }
      });
    }
    searchResult.clear();

    searchResult = allNames
        .where((element) =>
            element.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: _carteraBusqueda.length,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                _carteraBusqueda[index]['cardCode'] +
                    '\n' +
                    _carteraBusqueda[index]['cardName'],
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () {
                  if (GetStorage().read('itemsPedido') == null) {
                    storage.remove('itemsPedido');
                    storage.remove('pedidoGuardado');
                  }

                  storage.write(
                      'nitFiltroCartera', _carteraBusqueda[index]['cardCode']);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarteraPage(),
                    ),
                  );
                },
                label: const Text(''),
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    searchResult.clear();
    _carteraBusqueda2.clear();

    if (GetStorage().read('datosCartera') == null) {
      //print("allnames VACIO :  *******__________________________________");
    } else {
      carteraGuardados = GetStorage().read('datosCartera');
      carteraGuardados.forEach((k) {
        allNames2.add(k['cardName'].toString().toLowerCase());
        if (k['cardName'].toLowerCase().contains(query.trim().toLowerCase()) ||
            k['cardCode'].toLowerCase().contains(query.trim().toLowerCase())) {
          _carteraBusqueda2.add(k);
        }
      });
    }

// This method is called everytime the search term changes.
// If you want to add search suggestions as the user enters their search term, this is the place to do that.
    final suggestionList = query.isEmpty
        ? suggestion
        : allNames2.where((element) => element.contains(query)).toList();
    if (query == "") {
      _carteraBusqueda2 = [];
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
            if (GetStorage().read('itemsPedido') == null) {
              storage.remove('itemsPedido');
              storage.remove('pedidoGuardado');
            }

            storage.write(
                'nitFiltroCartera', _carteraBusqueda2[index]['cardCode']);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CarteraPage(),
              ),
            );
          },
          label: const Text(''),
          icon: const Icon(Icons.add),
        ),
        title: RichText(
            text: TextSpan(
          text: _carteraBusqueda2[index]["cardCode"] +
              "\n" +
              _carteraBusqueda2[index]["cardName"],
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        )),
      ),
      itemCount: _carteraBusqueda2.length,
    );
  }
}
