import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';
import 'package:biblo/services/post_login_notification_service.dart';
import 'services/token_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = await TokenService.getUserId();
      if (userId != null) {
        _notificationService.initialize(userId);
      }
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
                      'What would you like?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 30
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

// Both buttons placed inside a Column, stretched to screen width with padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Outer screen padding for the buttons
                    child: Column(
                      children: [

                        SizedBox(
                          width: double.infinity, // Forces button to match column/screen width
                          height: 60,
                          child: const BasicButton(route: '/random_suggestions', title: 'Random suggestions'),
                        ),

                        const SizedBox(height: 12), // Clean spacing between the two buttons

                        SizedBox(
                          width: double.infinity, // Forces button to match column/screen width
                          height: 60,
                          child: const BasicButton(route: '/curated_suggestions', title: 'Curated suggestions'),
                        ),

                        const SizedBox(height: 12), // Clean spacing between the two buttons

                        // BUTTON TO PLAY SOME GAMES
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: BasicButton(route: '/games', title: 'Games'),
                        ),

                        const SizedBox(height: 12), // Clean spacing between the two buttons

                        // BUTTON TO PLAY SOME GAMES
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: BasicButton(route: '/about_me', title: 'Learn more about Biblo'),
                        )

                      ],
                    ),
                  ),

                ]
            )
        ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/search');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/user_profile'); // Manage preferences lives here now
          }
        },
        items: const [

          BottomNavigationBarItem(
            icon: Icon(
                Icons.search,
                size: 28,
              ),
            label: 'Search',
          ),

          BottomNavigationBarItem(
            icon: Icon(
                Icons.person,
                size: 28
            ),
            label: 'My Profile',
          ),

        ],
      ),
    );
  }
}