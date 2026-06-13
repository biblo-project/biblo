import 'theme.dart';
import 'package:flutter/material.dart';
import 'book.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/token_service.dart';

class RandomSuggestionsScreen extends StatefulWidget {
  const RandomSuggestionsScreen({super.key});

  @override
  State<RandomSuggestionsScreen> createState() => _RandomSuggestionsScreenState();
}

class _RandomSuggestionsScreenState extends State<RandomSuggestionsScreen> {

  List<BookData> _books = [];
  /*
  // MOCK DATA SOURCE (Temporary placeholder until OpenSearch is hooked up)
  final List<BookData> _sampleBooks = [
    BookData(
      id: 1,
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      description: 'A story of ambition, obsession, and love in the roaring twenties.',
      isLiked: false,
    ),
    BookData(
      id: 2,
      title: '180°C: The Culinary Art',
      author: 'Chef Alan',
      description: 'Mastering the perfect temperature control for baking and searing.',
      isLiked: false,
    ),
    BookData(
      id: 3,
      title: 'Neuromancer',
      author: 'William Gibson',
      description: 'The matrix before the movie. A masterpiece cyberpunk heist novel.',
      isLiked: false,
    ),
    BookData(
      id: 4,
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      description: 'A comfortable hobbit is swept away into a dangerous adventure with dwarves.',
      isLiked: false,
    ),
    BookData(
      id: 5,
      title: 'Dracula',
      author: 'Bram Stoker',
      description: 'The classic gothic horror tale of the ancient vampire tracking new prey.',
      isLiked: false,
    ),
  ];
  */

  @override
  void initState() {
    super.initState(); // FIX: Changed 'super.key;' to 'super.initState();'
    _fetchRandomBooks();
  }
  /*
  NOTE:
  Error: The getter 'key' isn't defined...: Flutter's State class does not
  have a property named key (only Widget classes do). Changing it to initState()
  targets a valid method.
   */

  // HTTP Request fetching from your FastAPI backend
  Future<void> _fetchRandomBooks() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/books/random'); // 10.0.2.2 points to local machine from Android Emulator

      // Fetch your saved token from your storage service
      final String? token = await TokenService.getToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // This authenticates the `current_user` dependency
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          _books = decodedData.map((json) => BookData.fromJson(json)).toList();

        });
      } else {
        setState(() {
          print("Failed to load discovery feed (${response.statusCode}");

        });
      }
    } catch (e) {
      setState(() {
        print("An error occurred: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: _books.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _books.length,
              itemBuilder: (context, index) {
          
                // get specific book
                final currentBook = _books[index];
          
                // return the book widget here
                return Book(
                  book: currentBook,
                  onLikeTapped: () {
          
                    // trigger state refresh on the parent screen
                    setState(() {
                      currentBook.isLiked = !currentBook.isLiked;
                    });
          
                    // print statement to debug
                    print("${currentBook.title} liked status: ${currentBook.isLiked}");
                  },
                );
              }
          ),
        ),
    );
  }
}

