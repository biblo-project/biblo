import 'dart:convert';
import 'package:biblo/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'theme.dart'; // Imports primaryColor, textColor, etc.
import 'book.dart';  // Imports your Book and BookData models
import 'services/token_service.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  BookData? _bookData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

      // Safely extract the book ID passed from the notification routing payload
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final int bookId = args?['book_id'] ?? 0;

      if (bookId != 0 && _bookData == null) {
        _fetchBookDetails(bookId);
      } else if (bookId == 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Invalid book selection ID.";
        });
      }
  }

  // Network call to load the specific book profile directly from your FastAPI database
  Future<void> _fetchBookDetails(int bookId) async {
    try {
      final String? token = await TokenService.getToken();

      /*
      // BEFORE
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/books/$bookId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
       */

      // AFTER
      final response = await ApiService.get('/books/$bookId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _bookData = BookData.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Could not pull data. Status: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network pipeline connection issue: $e";
        _isLoading = false;
      });
    }
  }

  // 🟢 Removed the parameter since _bookData is globally available in this state class
  Future<void> _toggleBookLike() async {
    if (_bookData == null) return;

    // Save original status from the local state variable
    final originalStatus = _bookData!.isLiked;

    setState(() {
      _bookData!.isLiked = !_bookData!.isLiked;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:8000/books/${_bookData!.id}/toggle-like');
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
      final response = await ApiService.post('/books/${_bookData!.id}/toggle-like', {});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        setState(() {
          _bookData!.isLiked = responseData['liked'];
        });
        print("Discovery sync complete: ${_bookData!.title} liked = ${_bookData!.isLiked}");
      } else {
        setState(() {
          _bookData!.isLiked = originalStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update list status (${response.statusCode})')),
        );
      }
    } catch (e) {
      setState(() {
        _bookData!.isLiked = originalStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error: Could not reach backend server.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Reuses your theme's base branding background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // Ensures back button contrast looks clean
        title: Text(
          "Recommendation",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 4. REUSE: Drop your unmodified Book card widget cleanly onto the page canvas
    return SafeArea(
      child: Book(
        book: _bookData!,
        onLikeTapped: _toggleBookLike,
      ),
    );
  }
}