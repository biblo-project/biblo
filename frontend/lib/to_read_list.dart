import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'book.dart'; // Holds your BookData model
import 'services/token_service.dart';
import 'search_result_book_tile.dart'; // Reusing your beautiful stateless tile widget!

class ToReadListScreen extends StatefulWidget {
  const ToReadListScreen({super.key});

  @override
  State<ToReadListScreen> createState() => _ToReadListScreenState();
}

class _ToReadListScreenState extends State<ToReadListScreen> {
  List<BookData> _readingList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchToReadList();
  }

  // Network request fetching the user's explicit list selections
  Future<void> _fetchToReadList() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/user/to-read');
      final String? token = await TokenService.getToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          _readingList = decodedData.map((json) => BookData.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load your reading list.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Network error: Could not connect to backend server.";
        _isLoading = false;
      });
    }
  }

  // Handles unliking/removing items dynamically from this view layout loop
  Future<void> _removeItemFromList(BookData book) async {
    // Save state in case we need to roll back a network failure
    final originalStatus = book.isLiked;

    // Optimistically remove from view right away for crisp performance response
    setState(() {
      _readingList.removeWhere((item) => item.id == book.id);
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

      if (!mounted) return;

      // If server rejects the toggle delete command, add it back to the viewport list
      if (response.statusCode != 200) {
        book.isLiked = originalStatus;
        _fetchToReadList(); // Refresh full sync truth state safely
      }
    } catch (e) {
      if (!mounted) return;
      _fetchToReadList(); // Rollback local list optimization structural adjustments
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Makes back button white
        title: const Text(
          "My \"To Read\" List",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildListContent(),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_readingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              "Your list is completely empty.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Books you like during discovery appear here!",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _readingList.length,
      itemBuilder: (context, index) {
        final currentBook = _readingList[index];

        // Reuses your customized long-title fix and layout alignment
        return SearchResultBookTile(
          book: currentBook,
          onLikeTapped: () => _removeItemFromList(currentBook),
        );
      },
    );
  }
}