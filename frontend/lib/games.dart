import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

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
                    'So, what would you like to play?\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30
                    ),
                  ),

                  // BUTTON TO GET A RANDOM SUGGESTION
                  const BasicButton(route: '/games', title: 'Fill in the blanks'),

                  // BUTTON TO GET A CURATED SUGGESTION
                  const BasicButton(route: '/games', title: 'Identify the book from the dialogue'),

                  // BUTTON TO UPDATE PREFERENCES
                  const BasicButton(route: '/games', title: 'Match the authors with the books'),

                  // BUTTON TO PLAY SOME GAMES
                  const BasicButton(route: '/games', title: 'Battle cards'),

                ]
            )
        )
    );
  }
}