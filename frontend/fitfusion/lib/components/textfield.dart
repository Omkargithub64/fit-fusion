import 'package:flutter/material.dart';

class Textfield extends StatelessWidget {
  final controller;
  final bool obsccure;
  final String hintext;
  const Textfield({
    super.key,
    required this.controller,
    required this.hintext,
    required this.obsccure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obsccure,
      controller: controller,
      decoration: InputDecoration(
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(129, 204, 255, 1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(21, 106, 163, 1)),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: hintext,
      ),
    );
  }
}
