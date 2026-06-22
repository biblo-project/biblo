import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';
import 'package:biblo/services/post_login_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instantiate the notification service instance
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    // Initialize the real-time pipeline once the UI layout finishes mounting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Passing a mock user ID 42 for testing your Kafka group
      _notificationService.initialize(42);
    });
  }

  @override
  void dispose() {
    // Always close down the active connection when navigating away/logging out
    _notificationService.disconnect();
    super.dispose();
  }

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
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'So, what are we doing today?\n',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 30
                      ),
                    ),
                  ),

                  // BUTTON TO GET A RANDOM SUGGESTION
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: const BasicButton(route: '/random_suggestions', title: 'Get random suggestions'),
                  ),

                  // BUTTON TO GET A CURATED SUGGESTION
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: const BasicButton(route: '/curated_suggestions', title: 'Get curated suggestions'),
                  ),

                  // BUTTON TO UPDATE PREFERENCES
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: const BasicButton(route: '/select_genres', title: 'Update my preferences'),
                  ),

                  // SEARCH BOOKS
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: const BasicButton(route: '/search', title: 'Search'),
                  ),

                  // BUTTON TO PLAY SOME GAMES
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: const BasicButton(route: '/games', title: 'Play some games'),
                  ),

                  // BUTTON TO VIEW USER PROFILE
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: const BasicButton(route: '/user_profile', title: 'View my profile'),
                  ),

                  Text('\n\n\n\n\n\n\n\n'),

                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: TextButton(
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
                    ),
                  )

                ]
            )
        )
    );
  }
}