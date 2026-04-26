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
              '\nWelcome to',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25
              ),
            ),

            // second text box
            Text(
              'BIBLO',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 40
              ),
            ),

            // third text box
            Text(
              'A cozy space for avid readers',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25
              ),
            ),

            // gif
            Image.asset(
                'assets/images/biblo-gif.gif',
                alignment: Alignment.center,
                scale: 1.8,
            ),

            // space
            Text('\n'),

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