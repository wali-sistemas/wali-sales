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


class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> datosClientesArr = [];
  final _formKey = GlobalKey<FormState>();
  List _items = [];
  List _stock = [];
  List listaItems=[];
  String empresa=GetStorage().read('empresa');


  TextEditingController cantidadController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
  GetStorage storage = GetStorage();
  List clientesGuardados = [];

  String dropdownvalue2 = 'Elija un destino';


  String nit="";
  String urlImagenItem="";

  final pedidoJson={
    "cardCode": "C890911260",
    "cardName":"TRANSALGAR SA",
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

  final pedidoTemp={
    "cardCode": "",
    "cardName":"",
    "nit": "",
    "comments": "",
    "companyName": "IGB",
    "numAtCard": "",
    "shipToCode": "",
    "payToCode": "",
    "slpCode": 0,
    "discountPercent": 0.0,
    "docTotal":  ""
  };



  Future<void> _leerDatos() async {
    List clientesGuardados = [];
    clientesGuardados=GetStorage().read('datosClientes');
    datosClientesArr =clientesGuardados;
  }

  Future<void> _leerDatosold() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    //Map json = jsonDecode(jsonString);
    var userPref = pref.getString('datosClientes');
    if(userPref!= null) {
      List<dynamic> clientesMap = jsonDecode(userPref);
      if (!mounted) return;
      setState(() {
        datosClientesArr = clientesMap;
      });
    } else {print("userPref es null");}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);


    return MaterialApp(
        home: DefaultTabController(
        length: 4,
        child: Scaffold(
        appBar: AppBar(backgroundColor: Color.fromRGBO(30, 129, 235, 1),
          leading: GestureDetector(
            child: Icon( Icons.arrow_back_ios, color: Colors.white,  ),
            onTap: () {
              Navigator.pop(context);
            } ,
          ) ,
          title: ListTile(
            onTap: () {

              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
            title: Text('Buscar',style: TextStyle(color: Colors.white)),
          ),

          bottom: const TabBar(
            tabs: [
              Tab(child: Text('Cliente')),
              Tab(child: Text('Items')),
              Tab(child: Text('Detalle')),
              Tab(child: Text('Total')),
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



        )
        )
    );


  }

  Future<void> _listarItems() async {
    if (GetStorage().read('items')==null) {
      final String apiUrl = 'http://wali.igbcolombia.com:8080/manager/res/app/items/'+empresa;

      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      //print ("Respuesta: --------------------");
      //print(resp.toString());
      final data = resp["content"];
      //print(data.toString());
      if (!mounted) return;
      setState(() {
        _items = data;

        /// GUARDAR EN SHAREDPREFERENCES MIENTRAS SE HACE CON SQL
        //String itemsG = jsonEncode(_items);
        storage.write('items', _items);
        //_guardarItems();

      });
    } else {_items=GetStorage().read('items');}
  }

  Future<void> _listarStock( String item) async {
    final String apiUrl = 'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/'+empresa+'?itemcode='+item+'&whscode=0';

    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    //print ("REspuesta stock: --------------------");
    //print(resp.toString());
    final data = resp["content"];
    //print(data.toString());
    if (!mounted) return;
    setState(() {
      _stock = data;
    });
  }

///
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
  ///

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
    var direccionesEnvio=['Elija un destino'];
    var direccionesEnvioAsesor=['Elija un destino'];

    _leerDatos();
     List _direcciones = [];
     var indice=0;
     var i=0;
     storage.remove('pedido');

     List direccionesTemp=[];
    final numberFormat = new NumberFormat.simpleCurrency();
     /// DIRECCIONES DE ENVIO
     if (GetStorage().read('datosClientes')==null)
     {}else
     {
       /////BUSCAR nit en lista de clientes para hallar direcciones de envio

       clientesGuardados=GetStorage().read('datosClientes');
       nit=GetStorage().read('nit');
       clientesGuardados.forEach((k) {
         // print("K:  #####################");
         // print (k);
         if(nit==k['nit'])
         {  //print ("Encontrada dir @@@@@@@@@@@@@@@@@@@@@@@@@@@");
           direccionesTemp=k['addresses'];}
       });

     }
     for(var dir in direccionesTemp)
     { direccionesEnvio.add(dir['lineNum']);
     direccionesEnvioAsesor.add(dir['address']);
     }
     ///

     //BUSCAR CLIENTE CON EL NIT QUE TRAE DE PESTAÑA DE CLIENTES
     for (var cliente in datosClientesArr) {
       if (cliente['nit']==GetStorage().read('nit'))
         {indice=i;}
       i++;
     }
     _direcciones=datosClientesArr[indice]['addresses'];
     String dirs="";
     _direcciones.forEach((element) {dirs=dirs+element['lineNum']+'\n';});

     pedidoTemp['cardCode']=datosClientesArr[indice]['cardCode'].toString();
     pedidoTemp['cardName']=datosClientesArr[indice]['cardName'].toString();
     pedidoTemp['nit']=datosClientesArr[indice]['nit'].toString();
     pedidoTemp['companyName']="IGB";
    pedidoTemp['lineNum']=dirs;
     pedidoTemp['shipToCode']=datosClientesArr[indice]['addressToDef'].toString();
     pedidoTemp['payToCode']=datosClientesArr[indice]['addressToDef'].toString();
     pedidoTemp['slpCode']=GetStorage().read('usuario');
     pedidoTemp['discountPercent']=datosClientesArr[indice]['discountCommercial'].toString();
     storage.write('pedido', pedidoTemp);


    String saldoTxt=numberFormat.format(datosClientesArr[indice]['balance']);
    if (saldoTxt.contains('.')) {
      int decimalIndex = saldoTxt.indexOf('.');
      saldoTxt=saldoTxt.substring(0, decimalIndex);
    }

    String cupoTxt=numberFormat.format(datosClientesArr[indice]['cupo']);
    if (cupoTxt.contains('.')) {
      int decimalIndex = cupoTxt.indexOf('.');
      cupoTxt=cupoTxt.substring(0, decimalIndex);
    }

    return SingleChildScrollView( child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          elevation: 10,
          child: SizedBox(
            width: 400,
            child: Padding(
                padding: EdgeInsets.all(8),

                child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(datosClientesArr[indice]['nit'].toString()+' - '+datosClientesArr[indice]['cardName'].toString(),style:TextStyle(fontWeight: FontWeight.bold)),
                      Text('Cliente',textAlign: TextAlign.left),
                      SizedBox(
                        height: 30,
                      ),

                      Text(datosClientesArr[indice]['addressToDef'].toString(),style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Dirección ',textAlign: TextAlign.left,
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text(datosClientesArr[indice]['location'].toString(),style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Ciudad ',textAlign: TextAlign.left),
                      SizedBox(
                        height: 30,
                      ),
                      Text(datosClientesArr[indice]['wayToPay'].toString(),style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Forma de Pago ',textAlign: TextAlign.left),
                      SizedBox(
                        height: 30,
                      ),
                      Text(datosClientesArr[indice]['cupo'].toString(),style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Cupo',textAlign: TextAlign.left),
                      SizedBox(
                        height: 30,
                      ),
                      Text(saldoTxt,style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Saldo',textAlign: TextAlign.left),
                      SizedBox(
                        height: 30,
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: dropdownvalue2.isNotEmpty ? dropdownvalue2 : null,

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
                            int indice=findItemIndex(direccionesEnvioAsesor,newValue);
                            print("direccion elegida");print(newValue);
                            print ("direcion lineNum");
                            print(direccionesEnvio[indice]);
                            print(indice);
                            storage.write("dirEnvio", direccionesEnvio[indice]);
                            //pedidoFinal['shipToCode']=newValue;
                            dropdownvalue2 = newValue!;


                          });
                        },
                      ),
                      SizedBox(
                        height: 10,
                      ),




                    ]
                )
            ),
          ),
        ),

        SizedBox(
          height: 20,
        ),

         ],
    ),
    )
    ;



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

    //_listarStock("D0023");
    _listarItems();
    return SafeArea(
        child:  ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {


            final itemTemp={
              "quantity": "",
              "itemCode": "",
              "itemName": "",
              "whsCode": ""
            };

            return Card(
              child: Padding(
                padding: EdgeInsets.all(1),
                child: ListTile(
                  title: Text(
                    _items[index]['itemName'],
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text("Código: "+_items[index]['itemCode'],style: TextStyle(
                    fontSize: 13,
                  ),),
                  leading:  GestureDetector(
                    onTap: () {
                      urlImagenItem=_items[index]['pictureUrl'];
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return DetailScreen(_items[index]['pictureUrl']);
                      }));



                    }, // Image tapped
                    child: //Image.network(_items[index]['pictureUrl'], width: 40,height: 40),
                    CachedNetworkImage(
                      imageUrl: _items[index]['pictureUrl'],
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                  //leading: Image.network("http://179.50.4.10/item.jpg", width: 40,height: 40,),
                  trailing: IconButton(
                      icon: const Icon(Icons.add),
                    onPressed: () {

                      String dropdownvalue = 'Elija una Bodega';

                      showDialog(context: context,
                          builder: (_) {
                            storage.write("index", index);
                            return MyDialog();
                          });
                    },
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



  showAlertDialog(BuildContext context,String pedido) {

    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),


      onPressed: () { },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Pedido creado"),
      content: Text(pedido),
      actions: [
        okButton,
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
  @override
  Widget total(BuildContext context) {
    return TotalPedido();
 }

}

class MyDialog extends StatefulWidget {

  @override
  _MyDialogState createState() => new _MyDialogState();

}
////////////////////////&/
class DetailScreen extends StatelessWidget {
  final String image;
  const DetailScreen(this.image, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
         // Navigator.pop(context);
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


///////

class _MyDialogState extends State<MyDialog> {
  int index=0;
  List _items = [];
  List _stock = [];
  List listaItems=[];
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
  String empresa=GetStorage().read('empresa');
  String mensaje="";
  bool btnAgregarActivo=false;
  final numberFormat = new NumberFormat.simpleCurrency();
  var stockItem;
  String zona="";
  String usuario=GetStorage().read('usuario');
  List _stockFull=[];

  Connectivity _connectivity = Connectivity();
  final itemTemp={
    "quantity": "",
    "itemCode": "",
    "itemName": "",
    "group":"",
    "whsCode": "",
    "presentation" :"",
    "price":"",
    "discountItem":"",
    "discountPorc":"",
    "iva":""

  };


  @override
  void initState(){
    super.initState();
  //sincronizarStock();
  }

  Future<void> _listarItems() async {
    final String apiUrl = 'http://wali.igbcolombia.com:8080/manager/res/app/items/'+empresa;

    final response = await http.get(Uri.parse(apiUrl));
    Map<String, dynamic> resp = jsonDecode(response.body);
    //print ("Respuesta: --------------------");
    //print(resp.toString());
    final data = resp["content"];
    //print(data.toString());
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
    //Map<String, String> stockTemp = {"id","valor"};

    final String apiUrl = 'http://wali.igbcolombia.com:8080/manager/res/app/stock-current/'+empresa+'?itemcode=0&whscode=0&slpcode='+usuario;
    bool isConnected = await checkConnectivity();
    if(isConnected==false)
    {print("Error de red, cambiando a modo local");
    if (GetStorage().read('stockFull') != null) {
      List _stockFullLocal = GetStorage().read('stockFull');
      setState(() {
        _stockFull = _stockFullLocal;
      });

    }
    }
    else {
      final response = await http.get(Uri.parse(apiUrl));
      Map<String, dynamic> resp = jsonDecode(response.body);
      // print ("REspuesta stock: --------------------");
      // print(resp.toString());
      final codigoError = resp["code"];
      if (codigoError == -1) {
        print("codigoError: $codigoError");
        print("Error de red");
      } else {
        final data = resp["content"];
        print("Stockfull a guardar");
        print(data.toString());
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

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }


    @override
  Widget build(BuildContext context) {

    if (GetStorage().read('items')==null)
    {_listarItems();}else {
      itemsGuardados=GetStorage().read('items');
    }
    if (GetStorage().read('zona')==null)
    { zona="01";}else {
      zona=GetStorage().read('zona');
    }

    if (GetStorage().read('index')==null)
    {
      index=0;
    } else {
      index=GetStorage().read('index');
    }
    var _bodegas1=[];
    var fullStock=0;


    if(itemsGuardados.length>0){
      List _stockTemp=[];

     // _listarStock(itemsGuardados[index]["itemCode"]);

      print("itemcode index");print(itemsGuardados[index]["itemCode"]);
      if (GetStorage().read('stockFull')!=null) {

        _stockFull = GetStorage().read('stockFull');
        print("stockFULL: ");print(_stockFull);
        _stockFull.forEach((j) {
          if (itemsGuardados[index]["itemCode"] == j["itemCode"]) {
            _stockTemp.add(j);
            print ("encontrado item en stock local");
          }   //else {print("no ENCONTRADO");}
        });

        setState(() {
          _stock = _stockTemp;
        });
      } else {print("stockfull en 0");}
    }

    if ( _stock.length>0) {
      _inventario = _stock[0]['stockWarehouses'];
      fullStock=_stock[0]['stockFull'];
    } else {print("_stock <= 0");}

    //print ("fullstock:  $fullStock");
    num stockSuma=0;
    int mayor=0;
    print ("Inventario: ++++++++++++++");print(_inventario.toString());
    for (var bodega in _inventario) {
      if(bodega['quantity']>0 && bodega['whsCode']==zona) {

        stockItem = bodega['whsCode'];
        fullStock=bodega['quantity'];
      } else stockItem=itemsGuardados[index]["whsCode"];

      stockSuma=stockSuma+bodega['quantity'];
    }

   String precioTxt=numberFormat.format(itemsGuardados[index]['price']);
    if (precioTxt.contains('.')) {
      int decimalIndex = precioTxt.indexOf('.');
      precioTxt=precioTxt.substring(0, decimalIndex);
    }

    return AlertDialog(
      title: Text(itemsGuardados[index]['itemName']),

      content: Text('Codigo: '+itemsGuardados[index]['itemCode']),
      actions: <Widget>[Text('Stock: '+fullStock.toString()),
        Text('Precio: '+precioTxt),

        Text('Cantidad: '),
    SizedBox(
    //height: 40,
    width: 200,
    child:        TextField(
          onChanged: (text) {


                if (text.isEmpty )
                  {btnAgregarActivo=false;}
                else {
                  if (!areAllCharactersNumbers(text)) {
                    setState(() {
                    mensaje = "La cantidad debe ser un número ";
                    textoVisible = true;
                    btnAgregarActivo = false;
                   });
                  }

                  else {

            if (int.parse(text) > fullStock)
            {


            setState(() {
                      mensaje = "Cantidad ingresada es mayor al stock disponible";
                      textoVisible = true;
                      btnAgregarActivo = false;
            });
            }
                    else {

                      setState(() {
                        mensaje = "";
                      textoVisible = false;
                      btnAgregarActivo = true;
                      });
                    }
                  }
                }
              },

          style: const TextStyle(color: Colors.black),
          controller:  cantidadController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Por favor ingrese cantidad',
            border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.0),
    ),
            contentPadding: const EdgeInsets.all(15),
            hintStyle: const TextStyle(color: Colors.black , fontSize: 10),

          ),
        )
    ),


        SizedBox(
          height: 10,
        ),

////
        Divider(),
        Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:<Widget>[

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
          onPressed: btnAgregarActivo ? () {
            setState(() {

              //// AGREGAR ITEM AL PEDIDO
              itemTemp["quantity"]=cantidadController.text;
              itemTemp["itemCode"]=itemsGuardados[index]["itemCode"];
              itemTemp["itemName"]=itemsGuardados[index]["itemName"];
              itemTemp["group"]=itemsGuardados[index]["grupo"];
              if(itemsGuardados[index]["presentation"]!=null)
                itemTemp["presentation"]=itemsGuardados[index]["presentation"];
              else itemTemp["presentation"]="";
              itemTemp["price"]=itemsGuardados[index]["price"].toString();
              itemTemp["discountItem"]=itemsGuardados[index]["discountItem"].toString();
              itemTemp["discountPorc"]=itemsGuardados[index]["discountPorc"].toString();
              itemTemp["whsCode"]=stockItem;
              itemTemp["iva"]=itemsGuardados[index]["iva"].toString();
              itemsPedido.add(itemTemp);
              print("Item a guardar clase Mydialog: ///////////////////////////");
              print(itemsPedido);

              if (GetStorage().read('itemsPedido')==null)  {
                storage.write('itemsPedido',itemsPedido);
              } else {
                print ("itemsPedido en STORAGE:  ");
                print(GetStorage().read('itemsPedido'));
                itemsPedidoLocal=GetStorage().read('itemsPedido');
                //// VALIDAR SI EL ITME SELECCIONADO YA ESTÁ,ENTONCES SE SUMA LA CANTIDAD
                int repetido=0;
                itemsPedidoLocal.forEach((j) {
                if (itemTemp["itemCode"]==j["itemCode"])
                  {int cant=0;
                    cant=int.parse(j["quantity"]!)+int.parse(itemTemp["quantity"]!);
                    j["quantity"]=cant.toString();
                    repetido=1;
                  }
                });
                if (repetido==0)
                {itemsPedidoLocal.add(itemTemp);}
                storage.write('itemsPedido',itemsPedidoLocal);
              }


              print("Items guardados clase Mydialog: //////************//////////////");
              print(GetStorage().read('itemsPedido'));
              storage.write('index', index);
            });

            Navigator.pop(context);

          } : null,
        ),
    ]),
        SizedBox(
          height: 10,
        ),
        Visibility (visible:textoVisible,
        child:
        Center(
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
  List listaItems=[];
  num subtotalDetalle=0;
  num iva=0;
  num totalDetalle=0;
  int borrar=0;
  //final numberFormat = NumberFormat.currency(locale: 'es.CO', symbol:"\$");
  final numberFormat = new NumberFormat.simpleCurrency();


  void borrarItemDetalle(String item)
  {
    itemsPedidoLocal = GetStorage().read('itemsPedido');
    itemsPedidoLocal.forEach((j) {
        if(j['itemCode']==item)
          {
            itemsPedidoLocal.remove(j);
          }
    });

  }

  void showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed: () {

          borrar=0;


        //Navigator.pop(context);

        },

    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed: () {

          borrar=1;


        //Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text("Está seguro que desea borrar item?"),
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

  @override
  Widget build(BuildContext context) {
    if (GetStorage().read('itemsPedido') == null) {
      print("No hay items ");
    } else {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
      print("si hay items ");
      listaItems = [];
      itemsPedidoLocal.forEach((j) {
        listaItems.add(j);
      });
    }


    print("Listaitems: =======================");
    print(listaItems);


    return

    SafeArea(
        child: listaItems.isEmpty   ?
        Text("\n\n\n        Sin ítems") :
        ListView.builder(
          itemCount: listaItems.length,
          itemBuilder: (context, index) {
            subtotalDetalle=double.parse(listaItems[index]['price'])*double.parse(listaItems[index]['quantity']);
            iva=(double.parse(listaItems[index]['iva'])*subtotalDetalle)/100;
            String ivaTxt=numberFormat.format(iva);
            ivaTxt=ivaTxt.substring(0,ivaTxt.length-3);
            String subtotalDetalleTxt=numberFormat.format(subtotalDetalle);
            subtotalDetalleTxt=subtotalDetalleTxt.substring(0,subtotalDetalleTxt.length-3);
            totalDetalle=subtotalDetalle+iva;
            String totalDetalleTxt=numberFormat.format(totalDetalle);
            totalDetalleTxt=totalDetalleTxt.substring(0,totalDetalleTxt.length-3);
            int  precio=int.parse(listaItems[index]['price']);
            String precioTxt=numberFormat.format(precio);
            precioTxt=precioTxt.substring(0,precioTxt.length-3);

            return Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ListTile(leading: GestureDetector(
                  child: Icon( Icons.delete, color: Colors.grey,  ),
                  onTap: () {
                   // showAlertDialog(context);

                      setState(() {
                        borrarItemDetalle(listaItems[index]['itemCode']);
                      });


                  } ,
                ),
                    title: Text(
                    listaItems[index]['itemName'] + '\n' + 'Código: ' +
                        listaItems[index]['itemCode'] + '\n' +
                        'Precio: ' + precioTxt+'\n' +
                        'Cantidad: ' + listaItems[index]['quantity']+'\n' +
                        'Subtotal: ' + subtotalDetalleTxt+'\n' +
                        'Iva: ' + ivaTxt+'\n' +
                        'Total: ' + totalDetalleTxt,
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  //subtitle: Text("Nit: "+listaItems[index]['nit']),

                ),
              ),
            );
          },
        )




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
  bool cargando = false;
  final numberFormat = new NumberFormat.simpleCurrency();
  Connectivity _connectivity = Connectivity();

  Future<http.Response> _enviarPedido(BuildContext context,
      Map<String, dynamic> pedidoFinal) {
    final String url = 'http://wali.igbcolombia.com:8080/manager/res/app/create-order';
    print("Pedido final: ///////////////////////////");
    print(GetStorage().read('pedido').toString());
    print(GetStorage().read('itemsPedido'));
    var dirEnvio = GetStorage().read('dirEnvio');

    DateTime now = DateTime.now();
    String formatter = DateFormat('mmssSSS').format(now);
    formatter=formatter.replaceAll(":", "");
    String fecha = DateFormat("yyyyMMdd").format(now);
    String fechaPedido=fecha.toString() + pedidoFinal['cardCode'].toString() + formatter.toString();

    return http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json'
      },
      body: jsonEncode(<String, dynamic>{
        'cardCode': pedidoFinal['cardCode'],
        "comments": observacionesController.text,
        "companyName": empresa,
        "numAtCard": fechaPedido,
        "shipToCode": dirEnvio,
        "payToCode": pedidoFinal['payToCode'],
        "slpCode": pedidoFinal['slpCode'].toString(),
        "discountPercent": pedidoFinal['discountPercent'].toString(),
        "docTotal": pedidoFinal['docTotal'],
        "lineNum": pedidoFinal['lineNum'],
        "detailSalesOrder": GetStorage().read('itemsPedido'),

      }
      ),
    );
  }

  Future<http.Response> _enviarPedidoTemp(BuildContext context,      Map<String, dynamic> pedidoFinal) {
    final String url = 'http://179.50.4.120:8580/igb/igb.php';
    print("Pedido final: ///////////////////////////");
    print(GetStorage().read('pedido').toString());
    //DateFormat formatter = DateFormat('mmssSSS');
    print(GetStorage().read('itemsPedido'));
    DateTime now = DateTime.now();
    //String formatter = DateFormat.Hms().format(now);
    String formatter = DateFormat('mmssSSS').format(now);
    formatter=formatter.replaceAll(":", "");
    String fecha = DateFormat("yyyyMMdd").format(now);
    String fechaPedido=fecha.toString() + pedidoFinal['cardCode'].toString() + formatter.toString();


    return http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json'
      },
      body: jsonEncode(<String, dynamic>{
        'cardCode': pedidoFinal['cardCode'],
        "comments": observacionesController.text,
        "companyName": "IGB",
        "numAtCard": fechaPedido,
        "shipToCode": pedidoFinal['shipToCode'],
        "payToCode": pedidoFinal['payToCode'],
        "slpCode": pedidoFinal['slpCode'].toString(),
        "discountPercent": pedidoFinal['discountPercent'].toString(),
        "docTotal": pedidoFinal['docTotal'],
        "lineNum": pedidoFinal['lineNum'],
        "detailSalesOrder": GetStorage().read('itemsPedido'),

      }
      ),
    );
  }

  int restarStock(String item, String bodegaB,int cantidad)
  {
    if (GetStorage().read('stockFull') != null) {
      List _stockFull = GetStorage().read('stockFull');
      for (var stock in _stockFull)
      {
        if (stock['itemCode']==item)
        {
          for (var bodega in stock['stockWarehouses'])
          {
            if (bodega['whsCode']==bodegaB)
            {
              bodega['quantity']=bodega['quantity']-cantidad;
            }
          }
        }
      }
      setState(() {
        storage.write("stockFull", _stockFull);
      });

      return 1;
    } else {return 0;}

  }

  Future<bool> checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void showAlertError(BuildContext context, String message) {
    showDialog(
      context: context,
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
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    if (GetStorage().read('pedido') != null)
    {  Map<String, dynamic> pedidoFinal = GetStorage().read('pedido');
    //var itemsPedidoLocal = <Map<String, String>>[];
    List<dynamic> itemsPedidoLocal = [];
    List itemsGuardados = [];
    int cantidadItems = 0;
    num subtotal = 0;
    int cantidad = 0;

    print("Pedido doctotal: .................................");
    print(pedidoFinal['docTotal'].toString());

    // if (pedidoFinal['docTotal'].toString().isEmpty || pedidoFinal['docTotal']=="" )
    //   {setState(() {
    //     btnPedidoActivo=false;
    //   });
    //   }
    //String itemsGuardados=GetStorage().read('items');
    if (GetStorage().read('itemsPedido') == null) {} else {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
    }

    if (GetStorage().read('items') == null) {} else {
      /////BUSCAR itemCode en lista de items para hallar el precio
      itemsGuardados = GetStorage().read('items');
      itemsPedidoLocal.forEach((j) {
        itemsGuardados.forEach((k) {
          cantidad = int.parse(j['quantity']!);
          //print (k['price']);
          if (k['itemCode'] == j['itemCode']) {
            subtotal = subtotal + k['price'] * cantidad;
          }
        });
      });
    }

    if (GetStorage().read('itemsPedido') == null) {
      cantidadItems = 0;
    }
    else {
      itemsPedidoLocal = GetStorage().read('itemsPedido');
      cantidadItems = itemsPedidoLocal.length;
    }
    double iva = 0.0;


    itemsPedidoLocal.forEach((element) {
      print(element["iva"].toString());
      var subt = double.parse(element["price"])*double.parse(element["quantity"]);
      var ivaTemp =(double.parse(element["iva"].toString())*subt.toDouble())/100;
      iva=iva+ivaTemp;

    });

    String ivaTxt = numberFormat.format(iva);
    double total = subtotal.toDouble() + iva;
    String subtotalTxt = numberFormat.format(subtotal);
    String totalTxt = numberFormat.format(total);

    if (ivaTxt.contains('.')) {
      int decimalIndex = ivaTxt.indexOf('.');
      ivaTxt = ivaTxt.substring(0, decimalIndex);
    }

    if (subtotalTxt.contains('.')) {
      int decimalIndex = subtotalTxt.indexOf('.');
      subtotalTxt = subtotalTxt.substring(0, decimalIndex);
    }
    String textoObservaciones="";
    if (pedidoFinal['comments'].toString()!=null)
      {textoObservaciones=pedidoFinal['comments'].toString();
      observacionesController.text=textoObservaciones;
      }

    // if (totalTxt.contains('.')) {
    //   int decimalIndex = totalTxt.indexOf('.');
    //   totalTxt = subtotalTxt.substring(0, decimalIndex);
    // }

    pedidoFinal['docTotal'] = total.toString();

    return SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          elevation: 10,
          child: SizedBox(
            width: 400,
            child: Padding(
                padding: EdgeInsets.all(8),

                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(pedidoFinal['nit'] + ' - ' + pedidoFinal['cardName'],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 10,
                      ),

                      Text("Cantidad de items: " + cantidadItems.toString(),
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


                    ]
                )
            ),
          ),
        ),

        SizedBox(
          height: 20,
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
              "Observaciones:", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            //height: 40,
            width: 300,
            child:
            TextField(
              onChanged: (text) {
                pedidoFinal['comments']=text;

              },
              style: const TextStyle(color: Colors.black),
              controller: observacionesController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '',
                //labelText: textoObservaciones,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.all(15),
                hintStyle: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),

        Padding(padding: EdgeInsets.symmetric(horizontal: 8),
          child:
          ElevatedButton(
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(
                Color.fromRGBO(30, 129, 235, 1))),

            onPressed: btnPedidoActivo ? () async {
              setState(() {
                btnPedidoActivo=false;
              });

              print("Direenvio:  -------------------------------");
              //print(GetStorage().read('dirEnvio'));
              if (GetStorage().read('dirEnvio')==null || GetStorage().read('dirEnvio')=="")
                {showAlertErrorDir(context,"Obligatorio seleccionar la dirección de destino");}
              else {
              bool isConnected = await checkConnectivity();
              if (isConnected == true) {
                pedidoFinal['comments'] = observacionesController.text;
                storage.write('pedido', pedidoFinal);
                setState(() {
                  cargando = true;
                });

                http.Response response = await _enviarPedido(context, pedidoFinal);


                print("Pedido enviado ***************************************");
                print(response.statusCode);
                print("\n");
                Map<String, dynamic> resultado = jsonDecode(response.body);
                print(response.body);
                print(resultado['content']);
                if (response.statusCode == 200 && resultado['content'] != "") {
                  itemsPedidoLocal = GetStorage().read('itemsPedido');
                  for (var item in itemsPedidoLocal) {
                     restarStock(item['itemCode']!, item['whsCode']!, int.parse(item['quantity']!));
                  }
                  print(
                      "Borrando pedido ==============================================================");
                    storage.remove("pedido");
                  storage.remove("itemsPedido");
                  storage.remove("dirEnvio");
                  btnPedidoActivo=true;

                  setState(() {
                    cargando = false;
                  });
                  await Future.delayed(Duration(seconds: 3));
                  SnackBar(content: Text(
                    "Pedido " + resultado['content'].toString() + " creado",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.0, fontWeight:
                    FontWeight.bold),),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 200.0),);

                  await Future.delayed(Duration(seconds: 2));
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                }
                else {
                  Get.snackbar('Error',
                      'No se pudo crear el pedido',
                      colorText: Colors.red,
                      backgroundColor: Colors.white);
                }
              } else {

                showAlertError(context,
                    "No se pudo enviar el pedido, error de red, verifique conectividad por favor");
              }
            }
            }: null,
            child: Text('Enviar pedido'),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.all(40),
          // color: Colors.blue[100],

          child: Center(
            child: !cargando
                ? const Text("")
                : const CircularProgressIndicator(),
          ),
        )
      ],
    ),
    );
  }
    else return Text("Sin ítems para pedido");
}
}