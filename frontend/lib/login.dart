import 'package:flutter/material.dart';
import 'theme.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> authenticateUser(String username_or_email, String password) async {
  // Remember: 10.0.2.2 points your Android emulator to your computer's backend
  final url = Uri.parse('http://10.0.2.2:8000/auth/login');
  final response = await http.post(
    url,
    headers: { 'Content-Type': 'application/json'},
    body: jsonEncode({
      'username_or_email': username_or_email,
      'password': password,
    }),
  );

  if (response.statusCode == 200)
  {
    // parse the incoming JSON string into a Dart Map
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    /*
    dynamic:
    A special data type that disables static type checking, allowing a variable
    to hold any type of value and change its type at runtime
     */

    // extract the token string
    final String token = responseData['access_token'];

    // warning: Don't invoke 'print' in production code.
    print("Login successful!");
    return token;
  }

  else
  {
    // warning: Don't invoke 'print' in production code.
    print("Failed to register: ${response.body}");
  }

  return null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
{
  bool isObscured=true;

  // define the controllers
  final TextEditingController _usernameOrEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // tell the controllers to trigger a rebuild whenever the user types
    _usernameOrEmailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // always clean up controllers
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool isInputValid = _usernameOrEmailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

    return Scaffold(
        backgroundColor: primaryColor,
        body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // tells column to let its children take as much space as they need

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
                    Text('\n\n'),

                    // text field to enter username or email
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _usernameOrEmailController, // attach controller
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username or email';
                          }

                          // If they typed an '@', treat it strictly as an email format check
                          if (value.contains('@')) {
                            final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                          }
                          // If no '@' is present, treat it strictly as your alphanumeric username check
                          else {
                            final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
                            if (!usernameRegex.hasMatch(value)) {
                              return 'Usernames can only contain letters and numbers';
                            }
                          }

                          return null; // Input is completely valid
                        }
                      ),
                    ),

                    // text field to enter password
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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

                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        // If input is valid, provide navigation. Otherwise, null (greys it out).
                          onPressed: isInputValid
                              ? () async {
                            // Need to show a loading spinner or log so you know it clicked
                            print('Login button tapped! Connecting to backend......');

                            // Grab the navigator instance immediately BEFORE the async gap
                            final navigator = Navigator.of(context);

                            const secureStorage = FlutterSecureStorage();

                            // Now, call your function using the actual text from your controllers
                            // we use 'await' because we have to wait for the network response
                            try {
                              final String? token = await authenticateUser(
                                  _usernameOrEmailController.text.trim(),
                                  _passwordController.text
                              );

                              // check if the widget is still alive in the layout tree
                              if(!context.mounted) return;

                              if(token != null){
                                // save the token to the device here
                                await secureStorage.write(key: 'access_token', value: token);

                                // navigate away safely
                                navigator.pushReplacementNamed('/home');
                              }

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
                            'LOGIN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                            ),
                          )
                      ),
                    ),

                    // space
                    Text('\n\n\n\n\n\n\n'),

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
              ),
            )
        )
    );
  }
}