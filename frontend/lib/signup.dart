import 'dart:io';

import 'package:flutter/material.dart';
import 'theme.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:email_validator/email_validator.dart';
import 'package:image_picker/image_picker.dart';

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

  // variable to hold the chosen image file path
  File? _selectedImage;

  // instantiate the ImagePicker engine
  final ImagePicker _picker = ImagePicker();

  // create the function to open the native gallery app
  Future<void> _pickImageFromGallery() async {
    try {

      // triggers the OS to open the default photos/gallery app overlay
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      // if the user backs out of the gallery without picking anything, do nothing
      if (pickedFile == null) return;

      // update th state to render the fresh image inside the CircleAvatar
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

    }

    catch (e) {
      print("Error opening gallery: $e");
    }
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

                        // calls the native gallery launcher function
                        onTap: _pickImageFromGallery,

                        child: CircleAvatar(
                          radius: 145,
                          backgroundColor: secondaryColor,
                          child: CircleAvatar(
                            radius: 130,
                            foregroundImage: _selectedImage != null

                              // displays chosen image
                              ? FileImage(_selectedImage!) as ImageProvider
                              /*
                              '!' at the end is the null assertion operator to forcefully
                              cast a nullable type (File?) into a non-nullable type (File)
                               */

                              // displays default image
                              : const AssetImage(
                                'assets/images/biblo-signup-avatar-cropped.png'),
                            backgroundColor: secondaryColor,
          
                          ),
                        ),
                      ),
          
                      // space
                      Text('\n'),

                      // ENTER USERNAME TEXTBOX
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction, // <-- Validates live
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
                            errorStyle: const TextStyle(
                              fontSize: 16.0,          // Increases the text size (Default is usually 12.0)
                              fontWeight: FontWeight.w500, // Optional: Makes it slightly bolder/more readable
                            ),
                          ),
                          validator: (String? value) {

                            // check if username is blank
                            if(value==null || value.isEmpty) {
                              return "Please enter a valid username";
                            }

                            // check if username has non-alphanumeric characters
                            // Regular Expression matching only letters and numbers
                            final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
                            if (!alphanumericRegex.hasMatch(value)) {
                              return 'Only letters and numbers are allowed';
                            }

                            // Return null if the text is perfectly valid
                            return null;

                          } // end of validator
                        ),
                      ),

                      // ENTER EMAIL TEXTBOX
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction, // <-- Validates live
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
                            errorStyle: const TextStyle(
                              fontSize: 16.0,          // Increases the text size (Default is usually 12.0)
                              fontWeight: FontWeight.w500, // Optional: Makes it slightly bolder/more readable
                            ),
                          ),
                            validator: (String? value) {

                              // check if username is blank
                              if(value==null || value.isEmpty) {
                                return "Please enter a valid username";
                              }

                              // check if the email is valid
                              if (!EmailValidator.validate(value)) {
                                return 'Please enter a valid email address';
                              }

                              // Return null if the text is perfectly valid
                              return null;
                            }
                        ),
                      ),

                      // ENTER PASSWORD TEXTBOX
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction, // <-- Validates live
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
                            errorStyle: const TextStyle(
                              fontSize: 16.0,          // Increases the text size (Default is usually 12.0)
                              fontWeight: FontWeight.w500, // Optional: Makes it slightly bolder/more readable
                            ),
                          ),
                            validator: (String? value) {

                              if (value == null || value.isEmpty) {
                                return "Please enter a password";
                              }

                              if (value.length < 8) {
                                return "Password must be at least 8 characters long";
                              }

                              // 1. Check for at least one uppercase letter
                              if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                                return "Must contain at least one capital letter";
                              }

                              // 2. Check for at least one number
                              if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                                return "Must contain at least one number";
                              }

                              // 3. Check for at least one special character
                              if (!RegExp(r'(?=.*[!@#$&*~])').hasMatch(value)) {
                                return "Must contain at least one special character (!@#\$&*~)";
                              }

                              return null; // Password is perfectly valid!

                            }
                        ),
                      ),

                      // SIGNUP BUTTON
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: ElevatedButton(
                          // If input is valid, provide navigation.
                          // Otherwise, null (greys it out).
                            onPressed: isInputValid
                                ? () async {
                              // Need to show a loading spinner or log so you know it clicked
                              print('Signup button tapped! Connecting to backend......');

                              // Grab the navigator instance immediately BEFORE the async gap
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);

                              // Now, call your function using the actual text from your controllers
                              // we use 'await' because we have to wait for the network response
                              try {
                                await registerUser(
                                  _usernameController.text.trim(),
                                  _emailController.text.trim(),
                                  _passwordController.text
                                );

                                // Check if the widget is still in the tree before navigating
                                if (!mounted) return;

                                // Pop the signup screen off the stack and reveal/push the login screen
                                navigator.pushReplacementNamed('/login');

                                // Optional: Show a quick confirmation snack bar message
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Account created! Please log in.')),
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

                      Text('\n\n\n'),
          
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