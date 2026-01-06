import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AuthBackgroundProfile extends StatelessWidget {
  final Widget child;

  const AuthBackgroundProfile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const _PurpleBox(),
          const SafeArea(child: _CircleImageUserContent()),
          child,
        ],
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
      height: size.height * 0.91,
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

class _CircleImageUserContent extends StatelessWidget {
  const _CircleImageUserContent();

  static const String _fallbackImage =
      'http://179.50.5.95/cluster/img/person-icon.png';

  static final GetStorage _storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    final String? urlFoto = _storage.read('urlFoto');

    return Container(
      margin: const EdgeInsets.only(top: 10, left: 120),
      width: 150,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipOval(
          child: FadeInImage.assetNetwork(
            fit: BoxFit.cover,
            placeholder: 'assets/user_profile.png',
            image: urlFoto ?? _fallbackImage,
          ),
        ),
      ),
    );
  }
}
