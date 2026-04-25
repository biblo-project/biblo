import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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
                    'Biblo Admin Screen',
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30
                    ),
                  ),

                  // START BUTTON
                  const BasicButton(route: '/start', title: 'START'),

                  // LOGIN BUTTON
                  const BasicButton(route: '/login', title: 'LOGIN'),

                  // SIGNUP BUTTON
                  const BasicButton(route: '/signup', title: 'SIGNUP'),

                  // HOME BUTTON
                  const BasicButton(route: '/home', title: 'HOME'),

                  // GAMES BUTTON
                  const BasicButton(route: '/games', title: 'GAMES'),

                  // PROFILE PICTURE UPDATION BUTTON
                  const BasicButton(route: '/profile_picture_updation', title: 'PROFILE PICTURE UPDATION')
                ]
            )
        )
    );
  }
}