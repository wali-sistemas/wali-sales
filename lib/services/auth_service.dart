import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'identitytoolkit.googleapis.com';
  static const String _firebaseToken =
      'AIzaSyBcytoCbDUARrX8eHpcR-Bdrdq0yUmSjf8';

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final GetStorage storage2 = GetStorage();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<String?> createUser(String email, String password) async {
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };

    final Uri url = Uri.https(
      _baseUrl,
      '/v1/accounts:signUp',
      {'key': _firebaseToken},
    );

    final resp = await http.post(
      url,
      headers: _jsonHeaders,
      body: json.encode(authData),
    );

    final Map<String, dynamic> decodedResp = json.decode(resp.body);

    if (decodedResp.containsKey('idToken')) {
      await storage.write(key: 'token', value: decodedResp['idToken']);
      return null;
    }

    return decodedResp['error']?['message']?.toString();
  }

  Future<String?> login(String email, String password) async {
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };

    final Uri url = Uri.https(
      _baseUrl,
      '/v1/accounts:signInWithPassword',
      {'key': _firebaseToken},
    );

    final resp = await http.post(
      url,
      headers: _jsonHeaders,
      body: json.encode(authData),
    );

    final Map<String, dynamic> decodedResp = json.decode(resp.body);

    if (decodedResp.containsKey('idToken')) {
      await storage.write(key: 'token', value: decodedResp['idToken']);
      return null;
    }

    return decodedResp['error']?['message']?.toString();
  }

  // LOGIN IGB
  Future<String?> login2(
      String usuario, String password, String version) async {
    final String empresa = (GetStorage().read('empresa') ?? '').toString();

    final Uri url = Uri.parse(
        'http://wali.igbcolombia.com:8080/manager/res/app/login/' +
            empresa +
            '?user=' +
            usuario +
            '&pass=' +
            password);

    final response = await http.get(url);

    if (response.statusCode >= 500) {
      return "Ups, algo falló en el servidor.";
    }

    try {
      final dynamic decoded = json.decode(response.body);

      if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
        final Map<String, dynamic> data0 =
            Map<String, dynamic>.from(decoded[0]);

        await storage2.write('slpCode', data0['slpCode']);

        if (version != data0['appVersion']?.toString()) {
          return "Versión antigua. Actualiza la app.";
        }

        if (data0['slpCode']?.toString() == usuario &&
            data0['passWord']?.toString() == password) {
          return null;
        }

        return "Credenciales incorrectas.";
      }

      if (decoded is Map && decoded['code']?.toString() == '-1') {
        return "Credenciales incorrectas.";
      }
    } catch (_) {
      if (response.body.length >= 10 &&
          response.body.substring(8, 10) == "-1") {
        return "Credenciales incorrectas.";
      }
      return "Respuesta inválida del servidor.";
    }

    return "Credenciales incorrectas.";
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  Future<String> readToken() async {
    return await storage.read(key: 'token') ?? '';
  }
}
