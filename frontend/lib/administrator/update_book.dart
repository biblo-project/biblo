import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

class UpdateBookScreen extends StatefulWidget {
  const UpdateBookScreen({super.key});

  @override
  State<UpdateBookScreen> createState() => _UpdateBookScreenState();
}

class _UpdateBookScreenState extends State<UpdateBookScreen> {
  // Search State
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // Selected Book State
  Map<String, dynamic>? _selectedBook;
  bool _isUpdating = false;

  // Controllers for editing individual fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

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

  // 2. Select Book & Initialize Fields
  void _selectBook(Map<String, dynamic> book) {
    setState(() {
      _selectedBook = book;
      _titleController.text = book['title'] ?? '';
      _authorController.text = book['author'] ?? '';
      _isbnController.text = book['isbn'] ?? '';
      _descController.text = book['description'] ?? '';
    });
  }

  // 3. PUT Network Call to Save Changes
  Future<void> _updateBookDatabase() async {
    if (_selectedBook == null) return;

    setState(() {
      _isUpdating = true;
    });

    final bookId = _selectedBook!['id'];
    final url = Uri.parse('http://10.0.2.2:8000/books/admin/$bookId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'author': _authorController.text.trim(),
          'isbn': _isbnController.text.trim(),
          'description': _descController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar('Book details successfully updated!', primaryColor);
        setState(() {
          _selectedBook = null; // Reset back to search layout context
          _searchResults.clear();
          _searchController.clear();
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update record.');
      }
    } catch (e) {
      _showSnackBar('⚠️ Update failed: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // Inline Field Edit Dialog Popup Method
  void _showEditDialog(String label, TextEditingController controller, {int maxLines = 1}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter new $label',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              setState(() {}); // Re-render parent layout values
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
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
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard: Edit Book', style: TextStyle(color: Colors.white)),
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
                      hintText: 'Search book by title or author...',
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
                  ? _buildEditDetailsForm() // Shows details with pencil icons
                  : _buildSearchResultsList(), // Shows list results pool
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

  // WIDGET: Details Display Panel with Inline Pencil Modification Toggles
  Widget _buildEditDetailsForm() {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Selected Book Identity Profiles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 30),

              // Title Field Row Entry
              _buildEditableDetailRow('Title', _titleController.text, () => _showEditDialog('Title', _titleController)),
              const SizedBox(height: 16),

              // Author Field Row Entry
              _buildEditableDetailRow('Author', _authorController.text, () => _showEditDialog('Author', _authorController)),
              const SizedBox(height: 16),

              // ISBN Field Row Entry
              _buildEditableDetailRow('ISBN Code', _isbnController.text.isEmpty ? 'None set' : _isbnController.text, () => _showEditDialog('ISBN Code', _isbnController)),
              const SizedBox(height: 16),

              // Description Field Row Entry
              _buildEditableDetailRow('Description', _descController.text.isEmpty ? 'No description provided' : _descController.text, () => _showEditDialog('Description', _descController, maxLines: 4)),
              const SizedBox(height: 30),

              // Action Execution Button Save Trigger
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isUpdating ? null : _updateBookDatabase,
                child: _isUpdating
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Save System Changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REUSABLE ROW COMPONENT: Title details paired with trailing inline pencil icons
  Widget _buildEditableDetailRow(String label, String value, VoidCallback onEditPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
              onPressed: onEditPressed,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
        const Divider(color: Colors.black12, height: 20),
      ],
    );
  }
}