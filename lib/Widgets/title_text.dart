import 'package:flutter/material.dart';

Widget buildTitleText(
    Size size, String text, double fontSize, FontWeight fontWeight,
    [Color color = Colors.black]) {
  return SizedBox(
    width: size.width / 1.3,
    child: Text(
      text,
      style:
          TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    ),
  );
}
