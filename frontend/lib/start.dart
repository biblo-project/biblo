import 'package:biblo/basic_button.dart';
import 'package:biblo/theme.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // first text box
            Text(
              '\nWelcome to\n',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25
              ),
            ),

            // second text box
            Text(
              '\nBIBLO\n',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 65
              ),
            ),

            // third text box
            Text(
              '\nA cozy space for avid readers\n',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25
              ),
            ),

            // fourth text box
            Text(
              '\n<biblo-gif-animation>\n\n\n\n',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25
              ),
            ),

            // login button
            BasicButton(route: '/login', title: 'LOGIN'),

            // signup button
            BasicButton(route: '/signup', title: 'SIGNUP')
          ],
        )
      ),
    );
  }
}