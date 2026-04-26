import 'package:flutter/material.dart';
import 'theme.dart';
import 'basic_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
{
  bool isObscured=true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: primaryColor,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                //crossAxisAlignment: CrossAxisAlignment.center,
                // redundant for Column widget
                children: [
                  Text(
                    'Welcome back!\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 40
                    ),
                  ),

                  CircleAvatar(
                    foregroundImage: AssetImage(
                        'assets/images/biblo-login-avatar.gif'),
                    backgroundColor: secondaryColor,
                    radius: 130,
                  ),

                  // space
                  Text('\n'),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Username or email',
                        hintStyle: TextStyle(
                            color: Colors.grey,
                           fontSize: 18
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: secondaryColor,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      obscureText: isObscured,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 18
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isObscured = !isObscured;
                                // toggles the state
                              });
                            },
                            icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility,)
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: secondaryColor,
                      ),
                    ),
                  ),

                  // space
                  Text('\n'),

                  // LOGIN BUTTON
                  const BasicButton(route: '/login', title: 'LOGIN'),

                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'New user?',
                      style: TextStyle(
                        color: Colors.lightBlueAccent, // Traditional link color
                        decoration: TextDecoration.underline, // Adds the underline
                        fontSize: 20,
                      ),
                    ),
                  )
                ]
            )
        )
    );
  }
}