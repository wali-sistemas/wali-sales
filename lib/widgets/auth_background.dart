import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';


class AuthBackground extends StatelessWidget {
  
  final Widget child;


  const AuthBackground({
    Key? key, 
    required this.child
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        // color: Colors.red,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [

            _PurpleBox(),

            _HeaderIcon(),

            this.child,

          ],
        ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only( top: 30 ),
        child: Image.asset("./assets/logo_wali.png",width: 150,height: 150,)
        //Icon( Icons.person_pin, color: Colors.white, size: 100 ),
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
      height: size.height * 0.4,
      decoration: _purpleBackground(),
      child: Stack(
        children: [
          Positioned(child: _Bubble(), top: 90, left: 30 ),
          Positioned(child: _Bubble(), top: -40, left: -30 ),
          Positioned(child: _Bubble(), top: -50, right: -20 ),
          Positioned(child: _Bubble(), bottom: -50, left: 10 ),
          Positioned(child: _Bubble(), bottom: 120, right: 20 ),
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


      ]
    )
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
        color: Color.fromRGBO(255, 255, 255, 0.05)
      ),
    );
  }
}

