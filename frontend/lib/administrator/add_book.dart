import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addBookToDatabase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:8000/books');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'author': _authorController.text.trim(),
          'description': _descController.text.trim(),
          'isbn': _isbnController.text.trim(),
        }),
      );

      if (!mounted) return;

      // 1. Turn off loading spinner here
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book successfully added to database!')),
        );
        _formKey.currentState!.reset();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to create record.');
      }
    } catch (e) {
      if (!mounted) return;

      // 2. Turn off loading spinner here too
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding book: $e'), backgroundColor: Colors.redAccent),
      );
    }
    // 3. Delete the entire finally block from here
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
        _authorController.text.trim().isNotEmpty &&
        _isbnController.text.trim().isNotEmpty &&
        _descController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard: Add Book',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          autovalidateMode: AutovalidateMode.always,
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Catalog New Book Entry',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Book Title *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
                    onChanged: (value) => setState(() {})
                ),
                const SizedBox(height: 16),

                // Author Input
                TextFormField(
                  controller: _authorController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Author *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter an author' : null,
                    onChanged: (value) => setState(() {})
                ),
                const SizedBox(height: 16),

                // ISBN Input
                TextFormField(
                  controller: _isbnController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'ISBN Code *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter an ISBN code' : null, // Added validator
                    onChanged: (value) => setState(() {})
                ),
                const SizedBox(height: 16),

                // Description Input
                TextFormField(
                  controller: _descController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description' : null, // Added validator
                    onChanged: (value) => setState(() {})
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  // Disables the button by passing null if loading OR if any of the 4 fields are empty
                  onPressed: (_isLoading || !_isFormValid) ? null : _addBookToDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'Save to Database',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}