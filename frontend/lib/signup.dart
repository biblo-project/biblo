import 'package:flutter/material.dart';
import 'theme.dart';
import 'basic_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen>
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
                    'Welcome!\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 40
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    child: CircleAvatar(
                      radius: 145,
                      backgroundColor: secondaryColor,
                      child: CircleAvatar(
                        radius: 130,
                        foregroundImage: AssetImage(
                            'assets/images/biblo-signup-avatar-cropped.png'),
                        backgroundColor: secondaryColor,

                      ),
                    ),
                  ),

                  // space
                  Text('\n'),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Username',
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
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Email',
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
                  const BasicButton(route: '/home', title: 'SIGNUP'),

                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'Already have an account?',
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