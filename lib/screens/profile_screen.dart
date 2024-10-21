import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:productos_app/screens/login_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/widgets/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatelessWidget {
  GetStorage storage = GetStorage();

  final String pdfUrl =
      'http://wali.igbcolombia.com:8080/shared/app/instructivo.pdf';

  Future<void> _downloadPDF() async {
    final response = await http.get(Uri.parse(pdfUrl));

    if (response.statusCode == 200) {
      DateTime now = DateTime.now();

      final Uint8List pdfBytes = response.bodyBytes;
      final pdfFile = File('/storage/emulated/0/Download/instructivo ' +
          DateFormat('yyyyMMdd hhmm').format(now) +
          '.pdf');
      await pdfFile.writeAsBytes(pdfBytes);
      //print("Archivo descargado");
      //print('/storage/emulated/0/Download/instructivo.pdf');
      // Lógica adicional para mostrar una notificación o manejar el archivo descargado
    } else {
      throw Exception('Error al descargar el archivo');
    }
  }

  void _launchWhatsApp() async {
    final url = 'https://wa.me/';
    //var urlEnc = Uri.encodeFull(url);
    if (await launchUrl(Uri.parse(
        'whatsapp://send?text=Hola, requiero soporte de Wali Sales acerca de:&phone=+573227656966'))) {
      await launchUrl(Uri.parse(
          'whatsapp://send?text=Hola, requiero soporte de Wali Sales acerca de:&phone=+573227656966'));
    } else {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3), // Duración de la notificación
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? usuario = GetStorage().read('usuario');
    String? nombreAsesor = GetStorage().read('nombreAsesor');
    String? emailAsesor = GetStorage().read('emailAsesor');
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthBackgroundProfile(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 200),
              CardContainer(
                child: Container(
                  child: Form(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: TextFormField(
                            style: TextStyle(fontSize: 15),
                            maxLines: null,
                            readOnly: true,
                            autocorrect: false,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: nombreAsesor,
                              prefixIcon: Icon(Icons.person),
                              prefixIconColor: Color.fromRGBO(30, 129, 235, 1),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: TextFormField(
                            style: TextStyle(fontSize: 20),
                            readOnly: true,
                            autocorrect: false,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              // hintText: '*****',
                              labelText: usuario,
                              prefixIcon: Icon(Icons.contact_mail_outlined),
                              prefixIconColor: Color.fromRGBO(30, 129, 235, 1),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                child: TextFormField(
                                  style: TextStyle(fontSize: 20),
                                  readOnly: true,
                                  autocorrect: false,
                                  keyboardType: TextInputType.emailAddress,
                                  initialValue: "",
                                  decoration: InputDecoration(
                                    //hintText: 'co',
                                    labelText: emailAsesor,
                                    prefixIcon: Icon(Icons.email_outlined),
                                    prefixIconColor:
                                        Color.fromRGBO(30, 129, 235, 1),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Image.asset("./assets/wali.jpg",
                            width: 100, height: 100),
                        SizedBox(height: 5),
                        Text("Versión 11.2"),
                        Text("WALI COLOMBIA SAS"),
                        Text("Todos los derechos reservados"),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _downloadPDF();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Archivo guardado en carpeta Descargas',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                          child: Text(
                            "Documentación",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        SizedBox(height: 15),
                        GestureDetector(
                          onTap: () async {
                            _launchWhatsApp();
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.whatsapp),
                              SizedBox(width: 10),
                              Text(
                                'Línea de atención al cliente',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "btn2",
                onPressed: () {
                  showAlertDialog(context);
                },
                child: Icon(Icons.power_settings_new),
                backgroundColor: Colors.red,
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  showAlertDialog(BuildContext context) {
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
        //storage.remove('usuario');
        storage.remove('emailAsesor');
        storage.remove('nombreAsesor');
        storage.remove('datosClientes');
        storage.remove('empresa');
        storage.remove('observaciones');
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
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.blue),
        ),
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
                image: 'http://179.50.5.95/cluster/img/person-icon.png'),
          ),
        ),
      ),
    );
  }
}
