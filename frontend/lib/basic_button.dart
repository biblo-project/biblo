import 'theme.dart';
import 'package:flutter/material.dart';

class BasicButton extends StatelessWidget {

  // final = value is assigned once, never reassigned
  final String route;
  final String title;

  /*
  When all properties of a widget are final, the widget's value
  is completely fixed at creation time and will never change.
  Dart can then create it at compile time instead of runtime —
  meaning it's built before the app even runs.

  The const keyword on the constructor is how you tell Dart:
  "all the values in this widget are fixed, you can build
  this ahead of time."
   */
  const BasicButton({
    super.key,
    required this.route,
    required this.title
  });

  @override
  Widget build(BuildContext context) {
    return  ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(secondaryColor)
        ),
        child: Text(
          title,
          style: TextStyle(
              color: buttonTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 20
          ),
        )
    );
  }
}
