import 'package:flutter/material.dart';

Widget buildInputField(Size size, String hintText, IconData icon,TextEditingController cont,{bool obscureText = false}) {
  return SizedBox(
    height: size.height / 15,
    width: size.width / 1.1,
    child: TextField(
      controller: cont,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      obscureText: obscureText,
    ),
  );
}
