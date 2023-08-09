import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/widgets/widgets.dart';

class ProfilePage extends StatelessWidget {

  GetStorage storage = GetStorage();


  @override
  Widget build(BuildContext context) {
    String? usuario=GetStorage().read('usuario');
    String? nombreAsesor=GetStorage().read('nombreAsesor');
    String? emailAsesor=GetStorage().read('emailAsesor');

    print ("Nombre Asesor: ----------------- ---------------->>>>>>>>>>>>>>>>>>>");print(nombreAsesor);
    return Scaffold(
        body: AuthBackgroundProfile(
        child: SingleChildScrollView(

          child: Column(
            children: [
              SizedBox( height: 200 ),
                CardContainer(
                  child:
          Container(
          child: Form(


            child: Column(
              children: [

                Container(
                  padding: EdgeInsets.symmetric( horizontal: 10, vertical: 10),
                  child:
                  TextFormField(
                    style: TextStyle(fontSize: 15),
                    maxLines: null,
                    readOnly: true,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                    labelText: nombreAsesor,
                    prefixIcon: Icon(Icons.person),
                    prefixIconColor: Color.fromRGBO(30, 129, 235, 1)
                    ),


                  ),
                ),
                SizedBox( height: 15 ),
                Container(
                  padding: EdgeInsets.symmetric( horizontal: 10, vertical: 10),
                  child:
                  TextFormField(
                    style: TextStyle(fontSize: 20),
                    readOnly: true,
                    autocorrect: false,

                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        // hintText: '*****',
                        labelText: usuario,
                        prefixIcon: Icon(Icons.contact_mail_outlined),
                        prefixIconColor: Color.fromRGBO(30, 129, 235, 1)
                    ),

                  ),
                ),
                SizedBox( height: 15 ),
                Center(
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric( horizontal: 10, vertical: 10),
                        child:
                        TextFormField(
                          style: TextStyle(fontSize: 20),
                          readOnly: true,
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          initialValue: "",
                          decoration: InputDecoration(
                               //hintText: 'co',
                               labelText: emailAsesor,

                              prefixIcon: Icon(Icons.email_outlined),
                              prefixIconColor: Color.fromRGBO(30, 129, 235, 1)
                          ),


                        ),


                      )
                    ],

                  ),
                ),
                SizedBox( height: 15 ),
                Image.asset("./assets/wali.jpg",width: 100,height: 100),
                SizedBox( height: 10 ),
                Text("Versión 1"),
                Text("WALI COLMBIA SAS"),
                Text("\n"),
                Text("Todos los derechos reservados"),
                Text("Documentación", style: TextStyle(color: Colors.blue),),



              ],
            ),
          ),
          ),

        ),


              SizedBox( height: 20 ),
              FloatingActionButton(
                heroTag: "btn2",
                onPressed: () {
                  //con.signOut(),
                  showAlertDialog(context);

                },
                child: Icon(Icons.power_settings_new),
                backgroundColor: Colors.red,
              ),

            ],
          ),

    ),
        )
    );
  }

  showAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: Text("NO"),
      onPressed:  () { Navigator.pop(context);},
    );
    Widget continueButton = ElevatedButton(
      child: Text("SI"),
      onPressed:  () {
        storage.remove('usuario');
        storage.remove('emailAsesor');
        storage.remove('nombreAsesor');
        storage.remove('datosClientes');
        //storage.remove('items');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
        },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Atención"),
      content: Text("Está seguro que desea salir de la aplicación?"),
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

  Widget userInfo(String title, String subtitle, IconData iconData) {
    return Container(
      margin: EdgeInsets.only(left: 30, right: 30),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.blue)),
        leading: Icon(iconData, color: Colors.blue),
      ),
    );
  }

  Widget circleImageUser() {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 30),
        width: 200,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: FadeInImage.assetNetwork(
                fit: BoxFit.cover,
                placeholder: 'assets/user_profile.png',
                image:  'http://179.50.5.95/cluster/img/person-icon.png'
            ),
          ),
        ),
      ),
    );
  }
}
