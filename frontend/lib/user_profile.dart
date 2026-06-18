import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'theme.dart'; // Holds your primaryColor, textColor, etc.
import 'services/token_service.dart';
import 'to_read_list.dart'; // Import your upcoming reading list screen here

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _username = "Loading...";
  String _email = "Loading...";
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Network request to pull the logged-in user's profile details from FastAPI
  Future<void> _fetchUserProfile() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/user/me');
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
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] ?? 'Unknown User';
          _email = data['email'] ?? 'No email associated';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load profile settings.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Network error: Could not reach backend server.";
        _isLoading = false;
      });
    }
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
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // 1. PROFILE PHOTO HEADERS (CIRCULAR AVATAR ARCHITECTURE)
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 85,
                  backgroundColor: Colors.white,
                  backgroundImage: const AssetImage('assets/images/avatars/biblo-signup-avatar-cropped.png'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. USERNAME DISPLAY STRING
          Text(
            _username,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 40),
          const Divider(color: Colors.white, height: 1),
          const SizedBox(height: 24),

          // 3. ROW-WISE EMAIL CONTAINER
          Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Email Address",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white, height: 1),
          const SizedBox(height: 16),

          // 4. ROW-WISE NAVIGATION TO_READ LIST TILES LINK
          InkWell(
            onTap: () {
              print("Navigating to Reading List Screen...");
              Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const ToReadListScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bookmark_outline, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "My Reading List (To Read)",
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white, height: 1),
        ],
      ),
    );
  }
}