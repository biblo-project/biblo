import 'dart:convert';
import 'package:biblo/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'book.dart'; // Contains your BookData model and custom tile widget
import 'services/token_service.dart';
import 'book_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookData> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  // The network function hitting your new PostgreSQL-backed endpoint
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Encode the query parameters safely for web transport URLs
      // final url = Uri.parse('http://10.0.2.2:8000/books/search?q=${Uri.encodeComponent(query)}');

      // using a new URL after Opensearch integration
      final url = Uri.parse('http://10.0.2.2:8000/search?q=${Uri.encodeComponent(query)}');

      final String? token = await TokenService.getToken();

      /*
      // BEFORE
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
       */

      // AFTER
      final response = await ApiService.get('/search?q=${Uri.encodeComponent(query)}');

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          _searchResults = decodedData.map((json) => BookData.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Search failed status: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error: $e";
        _isLoading = false;
      });
    }
  }

  // FIXED: Added the backend sync handler for toggling likes inside search results
  Future<void> _toggleBookLike(BookData book) async {
    final originalStatus = book.isLiked;

    // Optimistically update the UI state instantly
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          book.isLiked = responseData['liked'];
        });
        print("Search sync complete: ${book.title} liked status = ${book.isLiked}");
      } else {
        // Revert on server error
        setState(() {
          book.isLiked = originalStatus;
        });
      }
    } catch (e) {
      // Revert on network connection drop
      setState(() {
        book.isLiked = originalStatus;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
          automaticallyImplyLeading: false,
        title: const Text(
            "Discover Catalog",
            style: TextStyle(
                color: Colors.white,
              fontWeight: FontWeight.bold,
            )
        ),
      ),
      body: Column(
        children: [
          // 1. THE SEARCH INPUT CONTAINER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by title or author",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _searchResults = []; });
                  },
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                _performSearch(value); // Fires query when user taps "Search" on keyboard
              },
            ),
          ),

          // 2. THE SEARCH RESULTS DISPLAY AREA
          Expanded(
            child: _buildSearchResultsWindow(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsWindow() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text("No matches found in catalog.", style: TextStyle(color: Colors.white)));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text("Type and press enter to look up books", style: TextStyle(color: Colors.white60)));
    }

    // 3. RENDER RESULTS VIA GRID OR LIST TILES
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final currentBook = _searchResults[index];

        return BookTile(
          book: currentBook,
          onLikeTapped: () => _toggleBookLike(currentBook),
          // NEW: receives the exact value back from the details screen
          // and sets it directly instead of toggling
          onLikeChanged: (newValue) {
            setState(() {
              currentBook.isLiked = newValue;
            });
          },
        );
      },
    );
  }
}