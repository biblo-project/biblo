import 'package:biblo/services/api_service.dart';

import 'services/token_service.dart';
import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectGenresScreen extends StatefulWidget {
  const SelectGenresScreen({super.key});

  @override
  State<SelectGenresScreen> createState() => _SelectGenresScreenState();
}

class _SelectGenresScreenState extends State<SelectGenresScreen> {

  // The (Temporary) Data Source
//  final List<String> _allGenres = [
//    'Thriller', 'Romance', 'Sci-Fi', 'Horror', 'Fantasy',
//    'Psychological', 'Fiction', 'Non-Fiction', 'Historical',
//    'Mystery', 'Comedy', 'Drama', 'Cyberpunk', 'Noir', 'Classic',
//    'Political', 'Unsettling', 'Drama', 'Magic', 'Gothic', 'Tragic',
//    'Mythology', 'Biography', 'Self-Help', 'Science', 'Utopian',
//    'Dystopian', 'Heroic', 'Epic', 'Ballad', 'Sonnet', 'Folklore',
//    'Autobiography', 'Ode', 'Fable', 'Bildungsroman', 'Western',
//    'Magical Realism', 'Realism', 'Poetry', 'Speculative Fiction',
//    'Epistolary', 'Action & Adventure', 'Black Comedy', 'Anthology',
//    'Crime', 'Erotica', 'Legal', 'Medical', 'Satire', 'Sports',
//    'Superhero', 'War', 'Short stories', 'Sagas', 'Religious',
//    'LGBTQ+', 'Comic', 'Graphic', 'Cultural Heritage', 'Travelogue',
//    'Alternative'
//  ];

List<String> _allGenres = [];

@override
void initState() {
  super.initState();
  _fetchGenres(); // Trigger the fetch as soon as the screen allocates memory
}

Future<void> _fetchGenres() async {
  try {
    final url = Uri.parse('http://10.0.2.2:8000/genres/');
    final String? secureToken = await TokenService.getToken();

    /*
    // BEFORE
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $secureToken', // Authenticates the user
      },
    );
    */

    // AFTER
    final response = await ApiService.get('/genres/');

    if (!mounted) return;

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        // Extract the master list of options
        _allGenres = List<String>.from(responseData['all_genres']);

        // Clear and pre-populate your selection memory with their historical database records
        _selectedGenres.clear();
        _selectedGenres.addAll(List<String>.from(responseData['selected_genres']));
      });
    }
  } catch (e) {
    print("Error pulling dynamic genre configurations: $e");
  }
}

  // The Selection Memory (The "Go Wild" Storage)
  final Set<String> _selectedGenres = {};

// --- API CONNECTION PIPELINE ---
  Future<void> _submitGenres() async {

    try {
      // 2. RETRIEVE THE SECURE TOKEN REAL-TIME
      final String? secureToken = await TokenService.getToken();

      // Safety check: If the token doesn't exist, kick them back to login or throw an error
      if (secureToken == null) {
        if (mounted) {
          // 1. Clear the entire page stack context history and force push the login screen
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return; // Stop running the rest of the network submission function
      }

      /*
      // BEFORE
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/genres/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secureToken', // Injected safely here!
        },
        body: jsonEncode({
          'genres': _selectedGenres.toList(),
          'allow_unrestricted': true,
        }),
      );
      */

      // AFTER
      final response = await ApiService.put(
          '/genres/',
        {
          'genres': _selectedGenres.toList(),
          'allow_unrestricted': true,
        }
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushNamed(context, '/home');
        }
      } else {
        throw Exception('Server rejected genre payload: Code ${response.statusCode}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update configurations: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      // FIX 1: Wrap the entire body in a SafeArea + Column, NOT a scroll view
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Text(
                      'What do you like to read?\n',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text(
                    'Select as many as you want!\n',
                    style: TextStyle(color: textColor, fontSize: 25),
                  ),

                  // THE WRAP SECTION
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 10,    // Horizontal space between chips
                        runSpacing: 10, // Vertical space between lines
                        alignment: WrapAlignment.center,
                        children: _allGenres.isEmpty

                            ? [const Center(child: Padding(
                          padding: EdgeInsets.only(top: 40.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        ))]

                            : _allGenres.map((genre) {
                          final bool isSelected = _selectedGenres.contains(genre);

                          return FilterChip(
                            label: Text(genre),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.indigo.shade900 : primaryColor,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                              fontSize: 20,
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGenres.add(genre);
                                } else {
                                  _selectedGenres.remove(genre);
                                }
                              });
                            },
                            // Styling to match your Biblo theme
                            backgroundColor: secondaryColor,
                            selectedColor: Colors.lightBlueAccent,
                            showCheckmark: false,
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: isSelected ? secondaryColor : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Bottom Action Elements remain pinned below the scrolling zone
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed:

                      _selectedGenres.isNotEmpty
                          ? () async {
                        // Call your API method to submit genres to FastAPI
                        await _submitGenres();
                      }
                          : null, // Greys out if nothing is selected

                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: buttonTextColor,
                        disabledBackgroundColor: Colors.grey.shade800,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: const Text(
                          'SUBMIT',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      child: const Text(
                        'Skip for now?',
                        style: TextStyle(
                          color: Colors.lightBlueAccent, // Traditional link color
                          decoration: TextDecoration.underline, // Adds the underline
                          fontSize: 20,
                        ),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}