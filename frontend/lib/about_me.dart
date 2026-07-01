import 'package:biblo/theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class AboutMeScreen extends StatefulWidget {
  const AboutMeScreen({super.key});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 🌟 2. Initialize the video from your raw GitHub URL (Must use the raw.githubusercontent.com domain)
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://raw.githubusercontent.com/biblo-project/biblo/main/assets/sample_video.mp4'),
    )..initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose(); // 🌟 3. Clean up controller to prevent memory leaks
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'creator@bibloapp.com',
      queryParameters: {'subject': 'Regarding Biblo Project'},
    );
    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'About Me',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'About Biblo',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage('assets/app_icon_padding.png'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Biblo is a personalized reading companion that recommends books based on user preferences, making it easier to discover, search, and manage your next read.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 20, color: Colors.black, height: 1.5),
            ),
            const SizedBox(height: 24),

            // 🌟 4. Render the GitHub video player container inside a gesture detector to toggle play/pause
            _isInitialized
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _videoController.value.isPlaying
                        ? _videoController.pause()
                        : _videoController.play();
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                    if (!_videoController.value.isPlaying)
                      const CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 30,
                        child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
                      ),
                  ],
                ),
              ),
            )
                : SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            /*
            Text(
              'About the Creator',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 20, color: Colors.black, height: 1.5),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            */
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _launchEmail,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email, color: primaryColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'biblo.team@gmail.com',
                      style: TextStyle(
                        fontSize: 20,
                        color: primaryColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}