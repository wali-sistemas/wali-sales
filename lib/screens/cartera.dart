import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:productos_app/screens/pedidos_screen.dart';
import 'buscador_cartera.dart';
import 'package:productos_app/screens/home_screen.dart';
import 'package:connectivity/connectivity.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


class CarteraPage extends StatefulWidget {
  const CarteraPage({Key? key}) : super(key: key);

  @override
  State<CarteraPage> createState() => _carteraPageState();
}

class _carteraPageState extends State<CarteraPage> {
  List _cartera = [];
  String codigo = GetStorage().read('slpCode');
  GetStorage storage = GetStorage();
  String empresa = GetStorage().read('empresa');
  String usuario = GetStorage().read('usuario');
  Connectivity _connectivity = Connectivity();
  List _stockFull = [];
  Map<String, dynamic> pedidoLocal = {};
  List<dynamic> itemsPedidoLocal = [];
  List<Map<String, dynamic>> detalleCartera = [];
  List<Map<String, dynamic>> detallePortafolio = [];



  var numberFormat = new NumberFormat('#,##0.00', 'en_Us');

  @override
  void initState() {
    super.initState();
    sincCartera();
    sincronizarStock();
    _fetchData();
    fetchDataCartera();
  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> sincCartera() async {
    final String apiUrl ='http://wali.igbcolombia.com:8080/manager/res/app/customers-portfolio/'+empresa+'?slpcode='+codigo;
    // final String apiUrl =
    //     'http://wali.igbcolombia.com:8080/manager/res/app/customers/' +
    //         codigo +
    //         '/' +
    //         empresa;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      //print("Error de red");
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      String texto = "No se encontraron Cartera para usuario " +
          codigo +
          " y empresa " +
          empresa;

      final codigoError = resp["code"];
      if (codigoError == -1 ||
          response.statusCode != 200 ||
          isConnected == false) {
        //print("codigoError: $codigoError");
      } else {
        final data = resp["content"];
        //print(data.toString());
        if (!mounted) return;
        setState(() {
          _cartera = data;

          /// GUARDAR EN LOCAL STORAGE
          storage.write('datosCartera', _cartera);
        });
      }
    }
  }

  Future<void> sincronizarStock() async {
    //Map<String, String> stockTemp = {"id","valor"};
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/' +
            empresa +
            '?itemcode=0&whscode=0&slpcode=' +
            usuario;
    bool isConnected = await checkConnectivity();
    if (isConnected == false) {
      //print("Error de red");
    } else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      //print ("REspuesta stock: --------------------");
      //print(resp.toString());
      final codigoError = resp["code"];
      if (codigoError == -1) {
        //print("codigoError: $codigoError");
      } else {
        final data = resp["content"];
        //print(data.toString());
        if (!mounted) return;
        setState(() {
          _stockFull = data;

          /// GUARDAR
          storage.write('stockFull', _stockFull);
        });
      }
    }
  }

  Future<void> _fetchData() async {
    if (GetStorage().read('datosCartera') == null) {
      final String apiUrl ='http://wali.igbcolombia.com:8080/manager/res/app/customers-portfolio/'+empresa+'?slpcode='+codigo;


      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      String texto = "No se encontraron Cartera para usuario " +
          codigo +
          " y empresa " +
          empresa;

      final codigoError = resp["content"];
      if (codigoError == -1) {
        var snackBar = SnackBar(
          content: Text(texto),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      final data = resp["content"];
      //print ("Cartera: ");print(data.toString());
      if (!mounted) return;
      setState(() {
        _cartera = data;

        /// GUARDAR EN LOCAL STORAGE
        _guardarDatos();
      });
    } else {
      _cartera = GetStorage().read('datosCartera');
    }
  }

  Future<void> _guardarDatos() async {
    // SharedPreferences pref = await SharedPreferences.getInstance();
    // //Map json = jsonDecode(jsonString);
    // String user = jsonEncode(_cartera);
    // pref.setString('datosCartera', user);
    storage.write('datosCartera', _cartera);
  }


  Map<String, dynamic>? findElementByCardCode(List<Map<String, dynamic>> list, String cardCode) {
    for (Map<String, dynamic> element in list) {
      if (element['cardCode'] == cardCode) {
        return element;
      }
    }
    return null;
  }


  Future<void> fetchDataCartera() async {
    final String endpoint = 'http://wali.igbcolombia.com:8080/manager/res/app/detail-age-customer-portfolio/'+empresa+'?slpcode='+codigo;

    final response = await http.get(Uri.parse(endpoint));
    Map<String, dynamic> resp = jsonDecode(response.body);
    String texto = "No se encontraron datos de Cartera para usuario " +
        codigo +
        " y empresa " +
        empresa;

    final codigoError = resp["content"];
    if (codigoError == -1) {
      var snackBar = SnackBar(
        content: Text(texto),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    final data = resp["content"];
    //print ("Cartera: ");print(data.toString());
    if (!mounted) return;
    setState(() {
      List<Map<String, dynamic>> contentMapList = data.cast<Map<String, dynamic>>();
               detalleCartera= contentMapList;
         });

    //print ("detalleCartera: ");print(detalleCartera);
  }


  ///////////////////////-----


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          //CarritoPedido(),
        ],
        title: ListTile(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(),
            );
          },
          title: Text('Buscar', style: TextStyle(color: Colors.white)),
        ),
      ),
      body:Center(
        //height: 120.0, // Altura ajustada según los datos

    child:

      Column(
          //direction: Axis.horizontal,

        children: [
          Container(height: 80,
              //padding: EdgeInsets.all(10.0),
            child:
                Flex(
                    direction: Axis.horizontal,
                children: [ Expanded(child: tituloCartera(context))
        ]
                ),
          ),
          Container(child:
               Expanded(child:cartera(context)),
          )

      ]),),
    );
  }

  Widget tituloCartera(BuildContext context)
  {
    num totalCartera=0;
    _cartera.forEach((element) {

      totalCartera=totalCartera+element["detailPortfolio"][0]["docTotal"];

    });

    String totalCarteraTxt = numberFormat.format(totalCartera);
    if (totalCarteraTxt.contains('.')) {
      int decimalIndex = totalCarteraTxt.indexOf('.');
      totalCarteraTxt = "\$" + totalCarteraTxt.substring(0, decimalIndex);

    }
    return
      Card(
      child:
            Container(height: 60,
              child:

               ListTile(
                title:
                Center(child:
                Text(
                       'Clientes:   '+_cartera.length.toString()
                      +'  ' +'Total:   '+totalCarteraTxt+'\n'

                  ,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
               )

              ),

      ),

    );

  }

  Widget cartera(BuildContext context) {



    return SafeArea(
        child: ListView.builder(
          itemCount: _cartera.length,
          itemBuilder: (context, index) {
            Map<String, dynamic>? resultado =findElementByCardCode(detalleCartera, _cartera[index]["cardCode"].toString());
            String ageSinVencer="0";
            String age0a30="0";
            String age30a60="0";
            String ageo1a90="0";
            String age91a120="0";
            String ageMas120="0";
            num totalCartera=0;
            String totalCarteraS ="0";

            if (resultado!=null) {
               ageSinVencer = numberFormat.format(
                  resultado!["ageSinVencer"]);
              if (ageSinVencer.contains('.')) {
                int decimalIndex = ageSinVencer.indexOf('.');
                ageSinVencer = "\$" + ageSinVencer.substring(0, decimalIndex);
                ageSinVencer = ageSinVencer.replaceAll("-", "");
              }

               age0a30 = numberFormat.format(resultado!["age0a30"]);
              if (age0a30.contains('.')) {
                int decimalIndex = age0a30.indexOf('.');
                age0a30 = "\$" + age0a30.substring(0, decimalIndex);
                age0a30 = age0a30.replaceAll("-", "");
              }

               age30a60 = numberFormat.format(resultado!["age30a60"]);
              if (age30a60.contains('.')) {
                int decimalIndex = age30a60.indexOf('.');
                age30a60 = "\$" + age30a60.substring(0, decimalIndex);
                age30a60 = age30a60.replaceAll("-", "");
              }

               ageo1a90 = numberFormat.format(resultado!["age61a90"]);
              if (ageo1a90.contains('.')) {
                int decimalIndex = ageo1a90.indexOf('.');
                ageo1a90 = "\$" + ageo1a90.substring(0, decimalIndex);
                ageo1a90 = ageo1a90.replaceAll("-", "");
              }

               age91a120 = numberFormat.format(resultado!["age91a120"]);
              if (age91a120.contains('.')) {
                int decimalIndex = age91a120.indexOf('.');
                age91a120 = "\$" + age91a120.substring(0, decimalIndex);
                age91a120 = age91a120.replaceAll("-", "");
              }

               ageMas120 = numberFormat.format(resultado!["ageMas120"]);
              if (ageMas120.contains('.')) {
                int decimalIndex = ageMas120.indexOf('.');
                ageMas120 = "\$" + ageMas120.substring(0, decimalIndex);
                ageMas120 = ageMas120.replaceAll("-", "");
              }
               totalCartera=resultado!["ageSinVencer"]-(resultado!["age0a30"]+resultado!["age30a60"]+resultado!["age61a90"]+resultado!["age91a120"]+resultado!["ageMas120"]);
                totalCarteraS = numberFormat.format(totalCartera);
               if (totalCarteraS.contains('.')) {
                 int decimalIndex = totalCarteraS.indexOf('.');
                 totalCarteraS = "\$" + totalCarteraS.substring(0, decimalIndex);

               }
            }


            return Card(
                child:

                   Container(child:
                       Column(
                         children:[
                    ListTile(
                      title:  Center(child:
                      Text(
                        _cartera[index]["cardName"].toString() +
                            '\n' +
                            _cartera[index]["cardCode"].toString()+'- '+_cartera[index]["payCondition"].toString()+'\n'+_cartera[index]["cupo"].toString()
                        +'\n\n'+'Sin vencer    '+ageSinVencer.toString()+'\n'
                        +'1 - 30 días  '+age0a30.toString()+'  \n'
                            +'31 - 60 días    '+age30a60.toString()+'\n'
                        +'61 - 90 días    '+ageo1a90.toString()+'\n'
                            +'91 - 120 días    '+age91a120.toString()+'\n'
                            +'+ 120 días    '+ageMas120.toString()+'\n'
                            + 'Total  '+totalCarteraS
                        ,
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
            )
                      //subtitle: Text("Nit: "+_cartera[index]['nit']),

                    ),
                           Row (mainAxisAlignment: MainAxisAlignment.end,

                               children: [
                             IconButton(
                               icon: Icon(Icons.wallet_outlined),
                               onPressed: () {
                                 storage.write('clienteDetalle', _cartera[index]);

                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => CarteraDetalle(),
                                   ),
                                 );
                               },
                             ),
                             IconButton(
                                 icon: Icon(Icons.mail_outline),
                                 onPressed: () {
                                   _launchEmail();
                                 }
                             )
                           ]
                           )
                     ]

                       )
                  )
            );



          },
        ));
  }

  showAlertDialog(BuildContext context, String nit) {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed: () {

        Navigator.pop(context);
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed: () {

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PedidosPage()),
        );
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text(
          "Tiene ítmes pendientes para otro cliente, si continúa se borrarán e inciará un pedido nuevo, desea continuar?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
///// detalle portafolio

class CarteraDetalle extends StatelessWidget {
  Map<String, dynamic> clienteDetalle = {};


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 129, 235, 1),
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          //CarritoPedido(),
        ],
        title: ListTile(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(),
            );
          },
          title: Text('Buscar', style: TextStyle(color: Colors.white)),
        ),
      ),
      body:Center(
        //height: 120.0, // Altura ajustada según los datos

        child:

        Column(
          //direction: Axis.horizontal,

            children: [
              Container(height: 80,
                //padding: EdgeInsets.all(10.0),
                child:
                Flex(
                    direction: Axis.horizontal,
                    children: [ Expanded(child: tituloDetalle(context))
                    ]
                ),
              ),
              Container(child:
              Expanded(child:carteraDetalle(context)),
              )

            ]),),
    );
  }
}

Future<void> _launchEmail() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: "",
    queryParameters: {
      'subject': "",
      'body': "",
      'attachment': "",
    },
  );
  final String emailUrl = emailUri.toString();

  if (await canLaunch(emailUrl)) {
    await launch(emailUrl);
  } else {
    throw 'No se pudo abrir el cliente de correo.';
  }
}


Widget tituloDetalle(BuildContext context){
  Map<String, dynamic>  clienteDetalle = GetStorage().read('clienteDetalle');
  return
    Card(
      child:
      Container(height: 60,
        child:

        ListTile(
            title:
            Center(child:
            Text(

              clienteDetalle["cardName"].toString()+'\n '+ clienteDetalle["cardCode"].toString() ,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            )

        ),

      ),

    );

}


Widget carteraDetalle(BuildContext context) {
  Map<String, dynamic>  clienteDetalle = GetStorage().read('clienteDetalle');

  var numberFormat = new NumberFormat('#,##0.00', 'en_Us');

  List detallPortafolio= clienteDetalle["detailPortfolio"];
   return SafeArea(
      child: ListView.builder(
        itemCount: detallPortafolio.length,
        itemBuilder: (context, index) {

          String saldo = numberFormat.format(clienteDetalle["detailPortfolio"][index]["balance"]);
          if (saldo.contains('.')) {
            int decimalIndex = saldo.indexOf('.');
            saldo = "\$" + saldo.substring(0, decimalIndex);
          }

          String valor = numberFormat.format(clienteDetalle["detailPortfolio"][index]["docTotal"]);
          if (valor.contains('.')) {
            int decimalIndex = valor.indexOf('.');
            valor = "\$" + valor.substring(0, decimalIndex);
          }


          return Card(
              child:

              Container(child:
              Column(
                  children:[
                    ListTile(
                        title:  Center(child:
                        Text(
                          'Tipo de documento: ' +clienteDetalle["detailPortfolio"][index]["docDueDate"].toString()+
                              '\n' +
                              'Nro. Documento: '+clienteDetalle["detailPortfolio"][index]["docNum"].toString()
                               +'\n\n'+'Fecha    '+clienteDetalle["detailPortfolio"][index]["docDate"].toString()+'\n'
                               +'Vencimiento  '+clienteDetalle["detailPortfolio"][index]["docDueDate"].toString()+'  \n'
                               +'Saldo    '+saldo+'\n'
                              +'Valor    '+valor+'\n'
                              +'Días vencidos  '+clienteDetalle["detailPortfolio"][index]["expiredDays"].toString()+'\n'

                          ,
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        )
                      //subtitle: Text("Nit: "+_cartera[index]['nit']),

                    ),
                    Row (mainAxisAlignment: MainAxisAlignment.end,

                        children: [
                          IconButton(
                            icon: Icon(Icons.picture_as_pdf_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebViewPage(webUrl: clienteDetalle["detailPortfolio"][index]["urlFE"].toString()),
                                ),
                              );
                            },
                          ),

                        ]
                    )
                  ]

              )
              )
          );



        },
      ));

}


class WebViewPage extends StatelessWidget {
  final String webUrl;

  WebViewPage({required this.webUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visor documento'),
      ),
      body: WebView(
        initialUrl: webUrl,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}