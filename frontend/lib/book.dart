import 'theme.dart';
import 'package:flutter/material.dart';

class BookData {
  final int id;
  final String title;
  final String author;
  final String description;
  bool isLiked;

  BookData({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.isLiked,
  });
}

class Book extends StatelessWidget {
  final BookData book;
  final VoidCallback onLikeTapped;

  const Book({
    super.key,
    required this.book,
    required this.onLikeTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      height: MediaQuery.sizeOf(context).height,
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TITLE IN BOLD BIGGER FONT
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 38, // Increased font size for dramatic hierarchy
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // 2. AUTHOR
          Text(
            book.author,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold
            ),
          ),

          const SizedBox(height: 16),

          // 3. IMAGE COVERS 1/2 THE SCREEN HEIGHT (flex: 1)
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                width: double.infinity, // Allows the cover to stretch naturally across the width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const Image(
                    image: AssetImage('assets/images/book-cover-temporary.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // 1. LIKE BUTTON
                  IconButton(
                    iconSize: 45,
                    // Icon toggles look based on the data boolean
                    icon: Icon(book.isLiked ? Icons.favorite : Icons.favorite_border),
                    // Color shifts from slate white to vibrant red when tapped
                    color: book.isLiked ? Colors.redAccent : Colors.white,
                    onPressed: onLikeTapped, // Triggers parent state management pipeline
                  ),

                  const SizedBox(width: 45), // Clean spacing between actions

                  // 2. SHOPPING CART BUTTON
                  IconButton(
                    iconSize: 45,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    color: Colors.white,
                    onPressed: () {

                    },
                  ),

                ],
              )
          ),

          // 4. DESCRIPTION COVERS REST OF THE SCREEN HEIGHT (flex: 1)
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  book.description,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}