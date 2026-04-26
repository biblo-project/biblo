import 'package:flutter/material.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
{
  bool isObscured=true;

  // define the controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // tell the controllers to trigger a rebuild whenever the user types
    _usernameController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // always clean up controllers
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool isInputValid = _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;

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
                      controller: _usernameController, // attach controller
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

                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: ElevatedButton(
                      // If input is valid, provide navigation. Otherwise, null (greys it out).
                        onPressed: isInputValid
                            ? () => Navigator.pushNamed(context, '/home')
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