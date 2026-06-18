import 'theme.dart';
import 'package:flutter/material.dart';
import 'book.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/token_service.dart';

class CuratedSuggestionsScreen extends StatefulWidget {
  const CuratedSuggestionsScreen({super.key});

  @override
  State<CuratedSuggestionsScreen> createState() => _CuratedSuggestionsScreenState();
}

class _CuratedSuggestionsScreenState extends State<CuratedSuggestionsScreen> {

  List<BookData> _books = [];

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
      final url = Uri.parse('http://10.0.2.2:8000/books/random');
      // 10.0.2.2 points to local machine from Android Emulator

      // Fetch your saved token from your storage service
      final String? token = await TokenService.getToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          // This authenticates the `current_user` dependency
        },
      );

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

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

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

