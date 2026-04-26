import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    'So, what are we doing today?\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30
                    ),
                  ),

                  // BUTTON TO GET A RANDOM SUGGESTION
                  const BasicButton(route: '/home', title: 'Get a random suggestion'),

                  // BUTTON TO GET A CURATED SUGGESTION
                  const BasicButton(route: '/home', title: 'Get a curated suggestion'),

                  // BUTTON TO UPDATE PREFERENCES
                  const BasicButton(route: '/select_genres', title: 'Select my preferred genres'),

                  // BUTTON TO PLAY SOME GAMES
                  const BasicButton(route: '/games', title: 'Play some games'),

                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/about_me');
                    },
                    child: const Text(
                      'Learn about me!',
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