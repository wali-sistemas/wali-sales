import 'dart:io';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? url;

  const ProductImage({super.key, this.url});

  static const EdgeInsets _padding =
      EdgeInsets.only(left: 10, right: 10, top: 10);

  static const BorderRadius _topRadius = BorderRadius.only(
    topLeft: Radius.circular(45),
    topRight: Radius.circular(45),
  );

  static const AssetImage _noImage = AssetImage('assets/no-image.png');
  static const AssetImage _loading = AssetImage('assets/jar-loading.gif');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _padding,
      child: Container(
        width: double.infinity,
        height: 450,
        decoration: _boxDecoration,
        child: ClipRRect(
          borderRadius: _topRadius,
          child: Opacity(
            opacity: 0.9,
            child: _getImage(url),
          ),
        ),
      ),
    );
  }

  static final BoxDecoration _boxDecoration = BoxDecoration(
    color: Colors.black,
    borderRadius: _topRadius,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  Widget _getImage(String? picture) {
    if (picture == null || picture.isEmpty) {
      return const Image(
        image: _noImage,
        fit: BoxFit.cover,
      );
    }

    if (picture.startsWith('http')) {
      return FadeInImage(
        image: NetworkImage(picture),
        placeholder: _loading,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(picture),
      fit: BoxFit.cover,
    );
  }
}
