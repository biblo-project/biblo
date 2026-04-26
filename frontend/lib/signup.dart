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

                  // LOGIN BUTTON
                 // const BasicButton(route: '/home', title: 'SIGNUP'),

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
            )
        )
    );
  }
}