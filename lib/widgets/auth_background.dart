import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const _PurpleBox(),
          const _HeaderIcon(),
          child,
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 50),
        child: Image.asset(
          'assets/logo_wali.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}

class _PurpleBox extends StatelessWidget {
  const _PurpleBox();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: DecoratedBox(
        decoration: _purpleBackground,
        child: const Stack(
          children: [
            Positioned(top: 90, left: 30, child: _Bubble()),
            Positioned(top: -40, left: -30, child: _Bubble()),
            Positioned(top: -50, right: -20, child: _Bubble()),
            Positioned(bottom: -50, left: 10, child: _Bubble()),
            Positioned(bottom: 120, right: 20, child: _Bubble()),
          ],
        ),
      ),
    );
  }

  static const BoxDecoration _purpleBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color.fromRGBO(56, 232, 211, 1),
        Color.fromRGBO(30, 129, 235, 1),
        Color.fromRGBO(41, 35, 92, 1),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 100,
      height: 100,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(100)),
          color: Color.fromRGBO(255, 255, 255, 0.05),
        ),
      ),
    );
  }
}
