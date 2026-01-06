import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productos_app/screens/screens.dart';
import 'package:productos_app/services/services.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  late final AuthService _authService;
  late final Future<String> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _tokenFuture = _authService.readToken();
    _redirect();
  }

  Future<void> _redirect() async {
    final token = await _tokenFuture;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => token.isEmpty ? LoginScreen() : HomePage(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}
