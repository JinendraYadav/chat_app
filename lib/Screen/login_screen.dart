import 'package:chat_app/Screen/home_screen.dart';
import 'package:chat_app/Screen/register.dart';
import 'package:chat_app/Widgets/button.dart';
import 'package:chat_app/Widgets/input_fields.dart';
import 'package:chat_app/Widgets/title_text.dart';
import 'package:chat_app/method.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading
          ? Center(
              child: SizedBox(
                height: size.height / 20,
                width: size.height / 20,
                child: const CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height / 20),
                  Container(
                    alignment: Alignment.centerLeft,
                    width: size.width / 1.2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(height: size.height / 50),
                  buildTitleText(size, "Welcome, Back", 28, FontWeight.bold),
                  buildTitleText(size, "Sign In To Continue", 25,
                      FontWeight.w500, Colors.grey),
                  SizedBox(height: size.height / 10),
                  Center(
                    child: Column(
                      children: [
                        buildInputField(
                            size, "Email", Icons.account_box, _emailController),
                        const SizedBox(height: 8),
                        buildInputField(
                            size, "Password", Icons.lock, _passwordController,
                            obscureText: true),
                        const SizedBox(height: 24),
                        GestureDetector(
                            onTap: () {
                              if (_emailController.text.isNotEmpty &&
                                  _passwordController.text.isNotEmpty) {
                                setState(() {
                                  isLoading = true;
                                });

                                logIn(_emailController.text,
                                        _passwordController.text)
                                    .then((user) {
                                  if (user != null) {
                                    const AlertDialog(
                                        content: Text("Login Successful"));
                                    setState(() {
                                      isLoading = false;
                                    });
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const HomePage()));
                                  } else {
                                    const AlertDialog(
                                        content: Text("Login Failed"));
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                });
                              } else {
                                const AlertDialog(
                                    content: Text("Login or Password Ivalid"));
                              }
                            },
                            child: buildCustomButton(size, 'Login')),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "Don't have an Account? ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: "Register",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Register(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
