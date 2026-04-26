import 'theme.dart';
import 'package:flutter/material.dart';

class SelectGenresScreen extends StatefulWidget {
  const SelectGenresScreen({super.key});

  @override
  State<SelectGenresScreen> createState() => _SelectGenresScreenState();
}

class _SelectGenresScreenState extends State<SelectGenresScreen> {

  // The Data Source
  final List<String> _allGenres = [
    'Thriller', 'Romance', 'Sci-Fi', 'Horror', 'Fantasy',
    'Psychological', 'Fiction', 'Non-Fiction', 'Historical',
    'Mystery', 'Comedy', 'Drama', 'Cyberpunk', 'Noir', 'Classic'
  ];

  // The Selection Memory (The "Go Wild" Storage)
  final Set<String> _selectedGenres = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
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
                  children: _allGenres.map((genre) {
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

            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ElevatedButton(
                onPressed: _selectedGenres.isNotEmpty
                    ? () { Navigator.pushNamed(context, '/home'); }
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