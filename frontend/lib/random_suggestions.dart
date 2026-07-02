import 'theme.dart';
import 'package:flutter/material.dart';
import 'book.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/token_service.dart';
import 'package:biblo/services/api_service.dart';

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

      /*
      // BEFORE
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // This authenticates the `current_user` dependency
        },
      );
       */

      // AFTER
      final response = await ApiService.get('/books/random');

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);

        // GUARD: Ensure the screen widget is still in the view tree before setting state
        if (!mounted) return;

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

  // NEW METHOD: Hits your backend endpoint to write/delete rows in the reading_lists table
  Future<void> _toggleBookLike(BookData book) async {
    final originalStatus = book.isLiked;

    setState(() {
      book.isLiked = !book.isLiked;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:8000/books/${book.id}/toggle-like');
      final String? token = await TokenService.getToken();

      /*
      // BEFORE
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
       */
      
      // AFTER
      final response = await ApiService.post('/books/${book.id}/toggle-like', {});

      // GUARD 1: If the user navigated away during the HTTP request, stop execution quietly
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Match the state exactly with whatever the database finalized
        setState(() {
          book.isLiked = responseData['liked'];
        });
        print("Discovery sync complete: ${book.title} liked = ${book.isLiked}");
      } else {
        // Revert UI change if the backend fails (e.g., return code 404, 500)
        setState(() {
          book.isLiked = originalStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update list status (${response.statusCode})')),
        );
      }
    } catch (e) {
      // Revert UI change if a network timeout/disconnection occurs
      setState(() {
        book.isLiked = originalStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: Could not reach backend server.')),
      );
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
                    _toggleBookLike(currentBook);
                  },
                );
              }
          ),
        ),
    );
  }
}

