
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';

List clientesGuardados = [];
List<String> allNames = ["Cliente"];
List<String> allNames2 = ["Cliente"];
var mainColor = Color(0xff1B3954);
var textColor = Color(0xff727272);
var accentColor = Color(0xff16ADE1);
var whiteText = Color(0xffF5F5F5);

class CustomSearchDelegate extends SearchDelegate {
  var suggestion = ["Cliente"];
  List<String> searchResult = [];
  List _clientesBusqueda = [];
  List _clientesBusqueda2 = [];
  String codigo=GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa=GetStorage().read('empresa');

  Future<void> _fetchData() async {
    final String apiUrl = 'http://wali.igbcolombia.com:8080/manager/res/app/customers/'+codigo+'/'+empresa;

    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);

    final data = resp["content"];
    //print(data.toString());

      _clientesBusqueda = data;
      /// GUARDAR EN LOCAL STORAGE
      _guardarDatos();

  }

  Future<void> _guardarDatos() async {

    storage.write('datosClientes', _clientesBusqueda);

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

    if (GetStorage().read('datosClientes')==null)
    { print ("allnames VACIO :  *******__________________________________");}
    else
    {_clientesBusqueda.clear();
      clientesGuardados=GetStorage().read('datosClientes');
      clientesGuardados.forEach((k) {
        allNames.add(k['cardName'].toString().toLowerCase());
        if(k['cardName'].toLowerCase().contains(query.trim().toLowerCase()) ||
        k['cardCode'].toLowerCase().contains(query.trim().toLowerCase())
        ){
          _clientesBusqueda.add(k);
        }
      });

       print ("allnames buscador:  __________________________________///");print (allNames);
    }
    searchResult.clear();

    searchResult =   allNames.where((element) => element.toLowerCase().contains(query.trim().toLowerCase())).toList();
    print ("searchResult:  ))))))))))))))))");print (searchResult);
    return  ListView.builder(
          itemCount: _clientesBusqueda.length,
          itemBuilder: (context, index) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(_clientesBusqueda[index]['cardCode']+' - '+
                      _clientesBusqueda[index]['cardName'],
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  //subtitle: Text("Nit: "+_clientesBusqueda[index]['nit']),

                  trailing: TextButton.icon(
                    onPressed: () {
                      storage.write('nit',_clientesBusqueda[index]["nit"]);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PedidosPage()),
                      );
                    },

                    label: const Text(
                      '',
                    ), icon: const Icon(Icons.add),
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
    _clientesBusqueda2.clear();

    if (GetStorage().read('datosClientes')==null)
    { print ("allnames VACIO :  *******__________________________________");}
    else
    {
      clientesGuardados=GetStorage().read('datosClientes');
      clientesGuardados.forEach((k) {
        allNames2.add(k['cardName'].toString().toLowerCase());
        if(k['cardName'].toLowerCase().contains(query.trim().toLowerCase()) ||
            k['cardCode'].toLowerCase().contains(query.trim().toLowerCase())
        ){
          _clientesBusqueda2.add(k);
        }
      });

    }


// This method is called everytime the search term changes.
// If you want to add search suggestions as the user enters their search term, this is the place to do that.
    final suggestionList = query.isEmpty
        ? suggestion
        : allNames2.where((element) => element.contains(query)).toList();
    if (query==""){_clientesBusqueda2=[];}


    return
      ListView.builder(
        itemBuilder: (context, index) => ListTile(

          onTap: () {
            if (query.isEmpty) {

              query = suggestion[index];
            }
          },
          leading: Icon(query.isEmpty ? Icons.history : Icons.search),
          trailing: TextButton.icon(
            onPressed: () {
              storage.write('nit',_clientesBusqueda2[index]["nit"]);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PedidosPage()),
              );
            },

            label: const Text(
              '',
            ), icon: const Icon(Icons.add),
          ),
          title: RichText(
              text: TextSpan(
                  text: _clientesBusqueda2[index]["cardName"],
                  style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 20),
                  )),
        ),
        itemCount: _clientesBusqueda2.length,
      );
  }
}