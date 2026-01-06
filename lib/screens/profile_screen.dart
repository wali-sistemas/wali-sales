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
  ProfilePage({super.key});

  final GetStorage storage = GetStorage();

  static const String pdfUrl =
      'http://wali.igbcolombia.com:8080/shared/app/instructivo.pdf';

  Future<void> _downloadPDF(BuildContext context) async {
    final response = await http.get(Uri.parse(pdfUrl));

    if (response.statusCode == 200) {
      final DateTime now = DateTime.now();

      final Uint8List pdfBytes = response.bodyBytes;
      final File pdfFile = File(
        '/storage/emulated/0/Download/instructivo_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
      );

      await pdfFile.writeAsBytes(pdfBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo guardado en carpeta Descargas'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      throw Exception('Error al descargar el archivo');
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/+573227656966?text=${Uri.encodeComponent("Hola, requiero soporte de Wali Sales acerca de:")}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? usuario = GetStorage().read('usuario');
    final String? nombreAsesor = GetStorage().read('nombreAsesor');
    final String? emailAsesor = GetStorage().read('emailAsesor');
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthBackgroundProfile(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 200),
              CardContainer(
                child: Form(
                  child: Column(
                    children: [
                      _readOnlyField(
                        label: nombreAsesor,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 15),
                      _readOnlyField(
                        label: usuario,
                        icon: Icons.contact_mail_outlined,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 15),
                      _readOnlyField(
                        label: emailAsesor,
                        icon: Icons.email_outlined,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 15),
                      Image.asset(
                        'assets/wali.jpg',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 5),
                      const Text('Versión 12.3'),
                      const Text('WALI COLOMBIA SAS'),
                      const Text('Todos los derechos reservados'),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _downloadPDF(context),
                        child: const Text(
                          'Documentación',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _launchWhatsApp,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            FaIcon(FontAwesomeIcons.whatsapp),
                            SizedBox(width: 10),
                            Text(
                              'Línea de atención al cliente',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'btn2',
                backgroundColor: Colors.red,
                onPressed: () {
                  _showAlertDialog(context);
                },
                child: const Icon(Icons.power_settings_new),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _readOnlyField({
    String? label,
    required IconData icon,
    double fontSize = 15,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: TextFormField(
        readOnly: true,
        maxLines: null,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          prefixIconColor: const Color.fromRGBO(30, 129, 235, 1),
        ),
      ),
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Text('Atención!'),
            ],
          ),
          content: const Text(
            '¿Está seguro que desea salir de la aplicación?',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () {
                storage.remove('emailAsesor');
                storage.remove('nombreAsesor');
                storage.remove('datosClientes');
                storage.remove('empresa');
                storage.remove('observaciones');
                storage.remove('chat_history');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('SI'),
            ),
          ],
        );
      },
    );
  }
}
