import 'package:flutter/material.dart';
import 'book.dart';
import 'theme.dart';
import 'package:url_launcher/url_launcher.dart';

class BookTile extends StatelessWidget {
  final BookData book;
  final VoidCallback onLikeTapped;
  final Function(bool)? onLikeChanged; // nullable — only used when coming back from details screen

  const BookTile({
    super.key,
    required this.book,
    required this.onLikeTapped,
    this.onLikeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final bool? updatedIsLiked = await Navigator.pushNamed(
            context,
            '/book_details',
            arguments: {'book_id': book.id},
          ) as bool?;

          // If the details screen returned a value and it differs from current state,
          // update the tile's state directly using the exact value, not a toggle
          if (updatedIsLiked != null && onLikeChanged != null) {
            onLikeChanged!(updatedIsLiked);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image(
                image: NetworkImage(
                  'https://raw.githubusercontent.com/biblo-project/biblo/main/assets/book_covers/${book.id}.jpg',
                ),
                width: 55,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    book.author,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Column(
              children: [
                IconButton(
                  iconSize: 28,
                  icon: Icon(book.isLiked ? Icons.favorite : Icons.favorite_border),
                  color: book.isLiked ? Colors.redAccent : Colors.white,
                  onPressed: onLikeTapped,
                ),
                IconButton(
                  onPressed: () async {
                    final query = Uri.encodeComponent('buy "${book.title}" by ${book.author}');
                    final url = Uri.parse('https://www.google.com/search?q=$query');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.shopping_cart),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}