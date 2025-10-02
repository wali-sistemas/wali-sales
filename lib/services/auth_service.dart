import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  final String _baseUrl = 'identitytoolkit.googleapis.com';
  final String _firebaseToken = 'AIzaSyBcytoCbDUARrX8eHpcR-Bdrdq0yUmSjf8';
  final storage = new FlutterSecureStorage();
  GetStorage storage2 = GetStorage();

  // Si retornamos algo, es un error, si no, todo bien!
  Future<String?> createUser(String email, String password) async {
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };

    final url =
        Uri.https(_baseUrl, '/v1/accounts:signUp', {'key': _firebaseToken});
    final resp = await http.post(url, body: json.encode(authData));
    final Map<String, dynamic> decodedResp = json.decode(resp.body);

    if (decodedResp.containsKey('idToken')) {
      // Token hay que guardarlo en un lugar seguro
      await storage.write(key: 'token', value: decodedResp['idToken']);
      // decodedResp['idToken'];
      return null;
    } else {
      return decodedResp['error']['message'];
    }
  }

  Future<String?> login(String email, String password) async {
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };

    final url = Uri.https(
        _baseUrl, '/v1/accounts:signInWithPassword', {'key': _firebaseToken});

    final resp = await http.post(url, body: json.encode(authData));
    final Map<String, dynamic> decodedResp = json.decode(resp.body);

    if (decodedResp.containsKey('idToken')) {
      // Token hay que guardarlo en un lugar seguro
      // decodedResp['idToken'];
      await storage.write(key: 'token', value: decodedResp['idToken']);
      return null;
    } else {
      return decodedResp['error']['message'];
    }
  }

  /// LOGIN IGB
  Future<String?> login2(String usuario, String password, String version) async {
    String empresa = GetStorage().read('empresa');
    final String apiUrl =
        'http://wali.igbcolombia.com:8080/manager/res/app/login/' +
            empresa +
            '?user=' +
            usuario +
            '&pass=' +
            password;
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 500) {
      return "Ups, algo falló en el servidor.";
    } else {
      if (response.body.substring(8, 10) == "-1") {
        return "Credenciales incorrectas.";
      }
      final data = json.decode(response.body);

      await storage2.write('slpCode', data[0]['slpCode']);

      if (version != data[0]['appVersion']) {
        return "Versión antigua. Actualiza la app.";
      }

      if (data[0]['slpCode'] == usuario && data[0]['passWord'] == password) {
        return null;
      } else {
        return "Credenciales incorrectas.";
      }
    }
  }

  Future logout() async {
    await storage.delete(key: 'token');
    return;
  }

  Future<String> readToken() async {
    return await storage.read(key: 'token') ?? '';
  }
}
