import 'package:chat_app/Widgets/button.dart';
import 'package:chat_app/Widgets/input_fields.dart';
import 'package:chat_app/Widgets/title_text.dart';
import 'package:chat_app/method.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _Register();
}

class _Register extends State<Register> {

final TextEditingController _usernameController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
 bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading? const Center(
        child: SizedBox(
          height: 20,width: 20,
          child: CircularProgressIndicator(),
          ),
      ) 
      :SingleChildScrollView(
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
            buildTitleText(size, "Welcome", 28, FontWeight.bold),
            buildTitleText(
                size, "Sign Up To Continue", 25, FontWeight.w500, Colors.grey),
            SizedBox(height: size.height / 10),
            Center(
              child: Column(
                children: [
                  buildInputField(size, "Username", Icons.account_circle,_usernameController),
                  const SizedBox(height: 8),
                  buildInputField(size, "Email", Icons.email,_emailController),
                  const SizedBox(height: 8),
                  buildInputField(size, "Password", Icons.lock,_passwordController,
                    obscureText: true),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: (){
                      if (_usernameController.text.isNotEmpty && _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                        setState(() {
                          isLoading = true;
                        });
                        createAccount(_usernameController.text,_emailController.text,_passwordController.text).then((user){
                          if (user != null) {
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const HomePage()));
                            const AlertDialog(content :Text("Login Successful"));
                          }else{
                            const AlertDialog(content :Text("Login Failed"));
                          }
                        
                        });
                      }else {
                        const AlertDialog(content: Text("Please fill all the details."));
                      }
                    },
                    child: buildCustomButton(size, "Create Account")),
                  const SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Already have an Account?",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "Login",
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
