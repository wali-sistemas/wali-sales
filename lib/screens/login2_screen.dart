import 'package:flutter/material.dart';
import 'package:productos_app/providers/login_form_provider.dart';
import 'package:productos_app/services/services.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:productos_app/ui/input_decorations.dart';
import 'package:productos_app/widgets/widgets.dart';
import 'package:get_storage/get_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? usuario = GetStorage().read('usuario');
  GetStorage storage = GetStorage();
  String dropdownvalue = 'Elija una empresa';
  var items = ['Elija una empresa', 'IGB', 'VARROC', 'REDPLAS'];
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Image.asset(
                'assets/arriba.jpg',
                width: 410.8,
                height: 73.4,
                fit: BoxFit.cover,
              ),
              Align(
                alignment: AlignmentDirectional(0, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 25, 0, 0),
                  child: Image.asset(
                    'assets/wali.jpg',
                    width: 130,
                    height: 130,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0.8, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                  child: Text(
                    'By WALI',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFFBFC7D0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(-0.7, 0),
                child: Text(
                  'Usuario',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFBFC7D0),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.75,
                child: TextFormField(
                  controller: email,
                  autofocus: true,
                  obscureText: false,
                  decoration: InputDecoration(
                    hintText: 'Usuario',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF5850E0),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    focusedErrorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFBFC7D0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(-0.7, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 50, 0, 0),
                  child: Text(
                    'Contraseña',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFFBFC7D0),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 75),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: TextFormField(
                    obscureText: true,
                    controller: password,
                    autofocus: true,
                    //obscureText: !_model.passwordFieldVisibility,
                    decoration: InputDecoration(
                      hintText: 'Cedula',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5850E0),
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFFBFC7D0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                  child: DropdownButton<String>(
                    value: dropdownvalue,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: items.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      storage.write("empresa", newValue);
                      setState(() {
                        dropdownvalue = newValue!;
                      });
                    },
                  ),
                ),
              ),
              MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  disabledColor: Colors.grey,
                  elevation: 0,
                  color: Colors.deepPurple,
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      child: Text(
                        'Ingresar',
                        style: TextStyle(color: Colors.white),
                      )),
                  onPressed: () async {
                    if (dropdownvalue == "Elija una empresa") {
                      var snackBar = SnackBar(
                        content: Text("Por favor elija una empresa"),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    } else {
                      FocusScope.of(context).unfocus();
                      final authService =
                          Provider.of<AuthService>(context, listen: false);

                      final String? errorMessage =
                          await authService.login2(email.text, password.text);
                      //final errorMessage = null;
                      if (errorMessage == null) {
                        storage.write("usuario", email.text);
                        Navigator.pushReplacementNamed(context, 'home');
                      } else {
                        NotificationsService.showSnackbar(errorMessage);
                      }
                    }
                  }),
              Align(
                child: Image.asset(
                  'assets/abajo.jpg',
                  width: 410.8,
                  height: 73.4,
                  fit: BoxFit.cover,
                ),
              )
            ])));
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  GetStorage storage = GetStorage();
  String dropdownvalue = 'Elija una empresa';
  String? usuario = GetStorage().read('usuario');

  @override
  Widget build(BuildContext context) {
    //print("Borrando items ==============================================================");
    storage.remove('itemsPedido');
    storage.remove('items');
    storage.remove('pedido');

    var items = ['Elija una empresa', 'IGB', 'VARROC', 'REDPLAS'];
    final loginForm = Provider.of<LoginFormProvider>(context);

    return Container(
      child: Form(
        key: loginForm.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              initialValue: usuario,
              decoration: InputDecorations.authInputDecoration(
                hintText: 'Digite usuario',
                labelText: 'Usuario',
                prefixIcon: Icons.person,
              ),
              onChanged: (value) => loginForm.email = value,
              /*validator: ( value ) {

                  //String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                 // RegExp regExp  = new RegExp(pattern);

                  return regExp.hasMatch(value ?? '')
                    ? null
                    : 'El valor ingresado no luce como un usuario';

              },*/
            ),
            SizedBox(height: 30),
            TextFormField(
              autocorrect: false,
              obscureText: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecorations.authInputDecoration(
                  hintText: '*****',
                  labelText: 'Contraseña',
                  prefixIcon: Icons.lock_outline),
              onChanged: (value) => loginForm.password = value,
              validator: (value) {
                return (value != null && value.length >= 3)
                    ? null
                    : 'La contraseña debe de ser mínimo de 3 caracteres';
              },
            ),
            SizedBox(height: 30),
            MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                disabledColor: Colors.grey,
                elevation: 0,
                color: Colors.deepPurple,
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
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

                          final String? errorMessage = await authService.login2(
                              loginForm.email, loginForm.password);
                          //final errorMessage = null;
                          if (errorMessage == null) {
                            storage.write("usuario", loginForm.email);
                            Navigator.pushReplacementNamed(context, 'home');
                          } else {
                            NotificationsService.showSnackbar(errorMessage);
                            loginForm.isLoading = false;
                          }
                        }
                      }),
            SizedBox(height: 20),
            ////  LISTA
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: dropdownvalue,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: items.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      storage.write("empresa", newValue);
                      setState(() {
                        //print("Seleccionado: ");
                        //print(newValue);
                        dropdownvalue = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),

            /// FIN LISTA
          ],
        ),
      ),
    );
  }
}
