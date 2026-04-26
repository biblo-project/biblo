import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';

class ProfilePictureUpdationScreen extends StatelessWidget {
  const ProfilePictureUpdationScreen({super.key});

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
                    'How would you like to proceed?\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30
                    ),
                  ),

                  // user chooses to select an avatar
                  const BasicButton(route: '/avatar_selection', title: 'Select an avatar'),

                  // user chooses to upload a picture
                  const BasicButton(route: '/home', title: 'Upload a picture'),

                  // user chooses to skip this process
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    child: const Text(
                      '\nSkip for now?',
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