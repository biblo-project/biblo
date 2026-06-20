import 'package:biblo/theme.dart';
import 'package:flutter/material.dart';
import 'package:biblo/basic_button.dart';

class AdministratorScreen extends StatelessWidget {
  const AdministratorScreen({super.key});

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
                    'Biblo Administrator Screen',
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30
                    ),
                  ),

                  const BasicButton(route: '/add_book', title: 'ADD'),

                  const BasicButton(route: '/delete_book', title: 'DELETE'),

                  const BasicButton(route: '/update_book', title: 'UPDATE'),

                  const BasicButton(route: '/read_book', title: 'READ'),
                ]
            )
        )
    );
  }
}