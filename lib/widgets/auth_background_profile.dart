import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AuthBackgroundProfile extends StatelessWidget {
  final Widget child;

  const AuthBackgroundProfile({Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          _PurpleBox(),
          circleImageUser(),
          this.child,
        ],
      ),
    );
  }
}

class _PurpleBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: size.height * 0.91,
      decoration: _purpleBackground(),
      child: Stack(
        children: [
          Positioned(child: _Bubble(), top: 90, left: 30),
          Positioned(child: _Bubble(), top: -40, left: -30),
          Positioned(child: _Bubble(), top: -50, right: -20),
          Positioned(child: _Bubble(), bottom: -50, left: 10),
          Positioned(child: _Bubble(), bottom: 120, right: 20),
        ],
      ),
    );
  }

  BoxDecoration _purpleBackground() => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(56, 232, 211, 1),
            Color.fromRGBO(30, 129, 235, 1),
            Color.fromRGBO(41, 35, 92, 1)
          ],
        ),
      );
}

class _Bubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Color.fromRGBO(255, 255, 255, 0.05),
      ),
    );
  }
}

Widget circleImageUser() {
  String? urlFoto = GetStorage().read('urlFoto');
  return SafeArea(
    child: Container(
      margin: EdgeInsets.only(top: 10, left: 120),
      width: 150,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipOval(
          child: FadeInImage.assetNetwork(
            fit: BoxFit.cover,
            placeholder: 'assets/user_profile.png',
            image: urlFoto ?? 'http://179.50.5.95/cluster/img/person-icon.png',
          ),
        ),
      ),
    ),
  );
}
