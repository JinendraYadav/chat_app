import 'package:flutter/material.dart';

Widget buildCustomButton(Size size, String s) {
  return Container(
    height: size.height / 14,
    width: size.width / 1.1,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.blue,
    ),
    alignment: Alignment.center,
    child: Text(
      s,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
