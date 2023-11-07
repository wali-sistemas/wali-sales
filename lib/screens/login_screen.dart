import 'dart:math';
import 'package:flutter/material.dart';
import 'package:productos_app/providers/login_form_provider.dart';
import 'package:productos_app/services/services.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/ui/input_decorations.dart';
import 'package:productos_app/widgets/widgets.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
          body: AuthBackground(
              child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 270),
            CardContainer(
                child: Column(
              children: [
                SizedBox(height: 10),
                ChangeNotifierProvider(
                    create: (_) => LoginFormProvider(), child: _LoginForm())
              ],
            )),
            SizedBox(height: 50),
            /*TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, 'register'), 
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all( Colors.indigo.withOpacity(0.1)),
                  shape: MaterialStateProperty.all( StadiumBorder() )
                ),
                child: Text('Crear una nueva cuenta', style: TextStyle( fontSize: 18, color: Colors.black87 ),)
              ),*/
            SizedBox(height: 50),
          ],
        ),
      ))),
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
    );
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  GetStorage storage = GetStorage();
  String dropdownvalue = 'Elija una empresa';
  String? usuario = "";
  String? clave = "";
  TextEditingController usuarioController = TextEditingController();
  TextEditingController claveController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*setState(() {

    usuario=GetStorage().read('usuario');
    clave=GetStorage().read('clave');
    usuarioController.text= usuario ?? '';
    claveController.text=clave ?? '';
    });*/

    //print ("Borrando items ==============================================================");
    // storage.remove('itemsPedido');
    // storage.remove('items');
    // storage.remove('pedido');
    // storage.remove('dirEnvio');
    // storage.remove('presupuesto');

    var items = ['Elija una empresa', 'IGB', 'MOTOZONE', 'REDPLAS'];
    final loginForm = Provider.of<LoginFormProvider>(context);
    /*if (usuario != null) {
      loginForm.email = usuario!;
    } else {
      if (usuario == "") loginForm.email = "";
    }

    if (clave != null) {
      loginForm.password = clave!;
    } else {
      if (clave == "") loginForm.password = "";
    }*/

    return Container(
      child: Form(
        key: loginForm.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 45, vertical: 15),
              child: TextFormField(
                controller: usuarioController,
                autocorrect: false,

                keyboardType: TextInputType.emailAddress,
                //initialValue: usuario,
                decoration: InputDecoration(
                    hintText: 'Digite usuario',
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    prefixIconColor: Color.fromRGBO(30, 129, 235, 1)),
                onChanged: (value) => loginForm.email = value,
                /*validator: ( value ) {

                  //String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                 // RegExp regExp  = new RegExp(pattern);

                  return regExp.hasMatch(value ?? '')
                    ? null
                    : 'El valor ingresado no luce como un usuario';

              },*/
              ),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 45, vertical: 15),
              child: TextFormField(
                controller: claveController,
                //initialValue: clave,
                autocorrect: false,
                obscureText: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    hintText: '*****',
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    prefixIconColor: Color.fromRGBO(30, 129, 235, 1)),
                onChanged: (value) => loginForm.password = value,
                validator: (value) {
                  return (value != null && value.length >= 3)
                      ? null
                      : 'La contraseña debe de ser mínimo de 3 caracteres';
                },
              ),
            ),
            SizedBox(height: 15),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 45, vertical: 10),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: dropdownvalue,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: items.map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          //print("Seleccionado: ");
                          //print(newValue);
                          if (newValue == "MOTOZONE") {
                            storage.write("empresa", "VARROC");
                          } else {
                            storage.write("empresa", newValue);
                          }
                          dropdownvalue = newValue!;
                        });
                      },
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 15),
            MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                disabledColor: Colors.grey,
                elevation: 0,
                color: Color.fromRGBO(30, 129, 235, 1),
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                    child: Text(
                      loginForm.isLoading ? 'Espere' : 'Ingresar',
                      style: TextStyle(color: Colors.white),
                    )),
                onPressed: loginForm.isLoading
                    ? null
                    : () async {
                        if (dropdownvalue == "Elija una empresa") {
                          var snackBar = SnackBar(
                            content: Text("Por favor elija una empresa"),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        } else {
                          FocusScope.of(context).unfocus();
                          final authService =
                              Provider.of<AuthService>(context, listen: false);

                          loginForm.isLoading = true;
                          // if (usuario!.isNotEmpty || usuario!=null) loginForm.email!=usuario;
                          // if (clave!.isNotEmpty || clave!=null) loginForm.password!=clave;
                          //print("usuario2");
                          //print(loginForm.email);
                          //print("clave2");
                          //print(loginForm.password);
                          final String? errorMessage = await authService.login2(
                              loginForm.email, loginForm.password);
                          //si errorMessage = null el usuario ingresó usuario y clave ok
                          if (errorMessage == null) {
                            storage.write("usuario", loginForm.email);
                            storage.write("clave", loginForm.password);

                            Navigator.pushReplacementNamed(context, 'home');
                          } else {
                            //print( errorMessage );
                            NotificationsService.showSnackbar(errorMessage);
                            loginForm.isLoading = false;
                          }
                        }
                      }),

            ////  LISTA

            /// FIN LISTA
          ],
        ),
      ),
    );
  }
}
