import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

class DeleteBookScreen extends StatefulWidget {
  const DeleteBookScreen({super.key});

  @override
  State<DeleteBookScreen> createState() => _DeleteBookScreenState();
}

class _DeleteBookScreenState extends State<DeleteBookScreen> {
  // Search State
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // Selected Book State
  Map<String, dynamic>? _selectedBook;
  bool _isDeleting = false;

  // 1. Search Network Call
  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _selectedBook = null; // Clear previous selection if searching again
    });

    final url = Uri.parse('http://10.0.2.2:8000/books/admin/search?q=${Uri.encodeComponent(query.trim())}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      _showSnackBar('Error searching books: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // 2. Select Book Target Layout
  void _selectBook(Map<String, dynamic> book) {
    setState(() {
      _selectedBook = book;
    });
  }

  // 3. DELETE Network Call to Purge Book
  Future<void> _deleteBookFromDatabase() async {
    if (_selectedBook == null) return;

    setState(() => _isDeleting = true);

    final bookId = _selectedBook!['id'];
    final url = Uri.parse('http://10.0.2.2:8000/books/admin/$bookId');

    try {
      final response = await http.delete(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar('Book successfully purged from system!', Colors.orangeAccent);
        setState(() {
          _selectedBook = null;
          _searchResults.clear();
          _searchController.clear();
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete record.');
      }
    } catch (e) {
      _showSnackBar('Deletion failed: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // 4. Modal Warning Dialogue Flow
  void _showDeleteConfirmationDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Permanent Deletion'),
        content: Text('Are you completely sure you want to permanently delete "$title"? This change is destructive and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(context); // Dismiss alert dialog box
              _deleteBookFromDatabase(); // Invoke actual backend API delete
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard: Delete Book', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Block Component
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search book by title or author to delete...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _searchBooks(value),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  onPressed: () => _searchBooks(_searchController.text),
                  child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DYNAMIC LAYOUT AREA
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedBook != null
                  ? _buildReviewDetailsForm() // Displays structured read-only identity overview
                  : _buildSearchResultsList(), // Shows search results pool selection list
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Renders Search Query Results Pool
  Widget _buildSearchResultsList() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty && !_isSearching) {
      return const Center(child: Text('No books found matching criteria.'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(book['title'] ?? 'Unknown Title', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('by ${book['author'] ?? 'Unknown Author'}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _selectBook(book),
          ),
        );
      },
    );
  }

  // WIDGET: Complete Read-Only Book Detail Sheet Overview Layout
  Widget _buildReviewDetailsForm() {
    // Extract values dynamically right out of state map
    final title = _selectedBook?['title'] ?? 'Unknown Title';
    final author = _selectedBook?['author'] ?? 'Unknown Author';
    final isbn = _selectedBook?['isbn'] ?? '';
    final description = _selectedBook?['description'] ?? '';

    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Review Target Catalog Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 30),

              // Presenting clean read-only informational blocks
              _buildStaticDetailRow('Title', title),
              const SizedBox(height: 16),

              _buildStaticDetailRow('Author', author),
              const SizedBox(height: 16),

              _buildStaticDetailRow('ISBN Code', isbn.isEmpty ? 'None set' : isbn),
              const SizedBox(height: 16),

              _buildStaticDetailRow('Description', description.isEmpty ? 'No description provided' : description),
              const SizedBox(height: 30),

              // Action execution button setup safely wrapped with verification trigger logic
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700, // Explicit warning coloration context
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isDeleting ? null : () => _showDeleteConfirmationDialog(title),
                child: _isDeleting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Delete Book From Catalog', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REUSABLE READ-ONLY TEXT FIELD WRAPPER COMPONENT
  Widget _buildStaticDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.3),
        ),
        const Divider(color: Colors.black12, height: 24),
      ],
    );
  }
}