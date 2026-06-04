import 'package:flutter/material.dart';
import 'theme.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> registerUser(String username, String email, String password) async {
  // Remember: 10.0.2.2 points your Android emulator to your computer's backend
  final url = Uri.parse('http://10.0.2.2:8000/auth/signup');
  final response = await http.post(
    url,
    headers: { 'Content-Type': 'application/json'},
      body: jsonEncode({
            'email': email,
            'username': username,
            'password': password
          } ),
  );

  if (response.statusCode == 200)
  {
    // warning: Don't invoke 'print' in production code.
    print("Registration successful!");
  }

  else
  {
    // warning: Don't invoke 'print' in production code.
    print("Failed to register: ${response.body}");
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen>
{
  bool isObscured=true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // tell the controllers to trigger a rebuild whenever the user types
    _usernameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // always clean up controllers
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool isInputValid =
        _usernameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
                _passwordController.text.isNotEmpty;

    return Scaffold(
        backgroundColor: primaryColor,
        body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // Tells the column to only take up as much space as its children need

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

                      // ADD PROFILE PICTURE BUTTON
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

                      // ENTER USERNAME TEXTBOX
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          controller: _usernameController, // attach controller
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

                      // ENTER EMAIL TEXTBOX
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          controller: _emailController, // attach controller
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

                      // ENTER PASSWORD TEXTBOX
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          controller: _passwordController, // attach controller
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

                      // SIGNUP BUTTON
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: ElevatedButton(
                          // If input is valid, provide navigation.
                          // Otherwise, null (greys it out).
                            onPressed: isInputValid
                                ? () async {
                              // Need to show a loading spinner or log so you know it clicked
                              print('Signup button tapped! Connecting to backend......');

                              // Now, call your function using the actual text from your controllers
                              // we use 'await' because we have to wait for the network response
                              try {
                                await registerUser(
                                  _usernameController.text.trim(),
                                  _emailController.text.trim(),
                                  _passwordController.text
                                );
                              } catch (e) {
                                // if the network request fails entirely (e.g. backend server is off)
                                print("Network error occurred: $e");
                                // Warning: Don't invoke 'print' in production code.
                              }
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              foregroundColor: buttonTextColor,
                              // These handle the "greying out" colors automatically
                              disabledBackgroundColor: Colors.grey.shade800,
                              disabledForegroundColor: Colors.white,
                            ),
                            child: const Text(
                              'SIGNUP',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                            )
                        ),
                      ),
          
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
                ),
              )
          ),
        )
    );
  }
}