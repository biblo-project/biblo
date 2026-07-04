import 'dart:convert';
import 'package:biblo/select_genres.dart';
import 'package:biblo/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'theme.dart'; // Holds your primaryColor, textColor, etc.
import 'services/token_service.dart';
import 'to_read_list.dart'; // Import your upcoming reading list screen here
import 'avatar_selection.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _username = "Loading...";
  String _email = "Loading...";
  int _avatarId = 0; // default id is zero so display the default image
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Inside user_profile.dart (or wherever you open this screen)
  void _openAvatarSelection() async {
    // 🌟 1. Await the result from the selection screen pop action
    final String? selectedAvatarUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AvatarSelectionScreen()),
    );

    // 🌟 2. If the user successfully picked an avatar (result is not null), update the local state instantly!
    if (selectedAvatarUrl != null) {
      try {
        // Example URL: https://raw.githubusercontent.com/.../assets/avatars/5.png
        // Splitting by '/' gives us the last segment: '5.png'
        final String filename = selectedAvatarUrl.split('/').last;
        // Removing '.png' leaves us with just the clean number string: '5'
        final String idString = filename.replaceAll('.png', '');

        final int parsedId = int.parse(idString);

        setState(() {
          _avatarId = parsedId; // 🌟 Forces an immediate layout update on screen!
        });
      } catch (e) {
        print("Error parsing updated avatar image ID: $e");
      }
    }
  }

  // Network request to pull the logged-in user's profile details from FastAPI
  Future<void> _fetchUserProfile() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/user/me');
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
      final response = await ApiService.get('/user/me');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] ?? 'Unknown User';
          _email = data['email'] ?? 'No email associated';
          _avatarId = data['avatar_id'] ?? 0;
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
                // 🌟 Custom Circular Container replacing CircleAvatar
                Container(
                  width: 200, // Matches the total diameter (radius 100 * 2)
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: (_avatarId == 0)
                        ? Image.asset(
                      'assets/images/biblo-signup-avatar-cropped.png',
                      fit: BoxFit.cover,
                    )
                        : Image.network(
                      'https://raw.githubusercontent.com/biblo-project/biblo/main/assets/avatars/$_avatarId.png',
                      fit: BoxFit.cover,
                      // 🌟 Loading spinner framework
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.grey, // Clear spinner contrast on white bg
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),

                // 2. Positioned Edit Button on Bottom Right
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      _openAvatarSelection();
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: secondaryColor,
                      child: Icon(
                        Icons.edit,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
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
              const Icon(Icons.email_outlined, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
                    child: const Icon(Icons.bookmark_outline, color: Colors.white), // Fixed decorative visibility color
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "My Reading List (To Read)",
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white, height: 1),
          const SizedBox(height: 16),

          // 5. ROW-WISE NAVIGATION TO GENRES CHIPS SCREEN LINK
          InkWell(
            onTap: () {
              print("Navigating to Genres Chips Screen...");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SelectGenresScreen()),
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
                    child: const Icon(Icons.bookmark_outline, color: Colors.white), // Fixed decorative visibility color
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "My Preferences",
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white, height: 1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}