import 'theme.dart';
import 'package:flutter/material.dart';
import 'book.dart';

class RandomSuggestionsScreen extends StatefulWidget {
  const RandomSuggestionsScreen({super.key});

  @override
  State<RandomSuggestionsScreen> createState() => _RandomSuggestionsScreenState();
}

class _RandomSuggestionsScreenState extends State<RandomSuggestionsScreen> {

  // MOCK DATA SOURCE (Temporary placeholder until OpenSearch is hooked up)
  final List<BookData> _sampleBooks = [
    BookData(
      id: 1,
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      description: 'A story of ambition, obsession, and love in the roaring twenties.',
      isLiked: false,
    ),
    BookData(
      id: 2,
      title: '180°C: The Culinary Art',
      author: 'Chef Alan',
      description: 'Mastering the perfect temperature control for baking and searing.',
      isLiked: false,
    ),
    BookData(
      id: 3,
      title: 'Neuromancer',
      author: 'William Gibson',
      description: 'The matrix before the movie. A masterpiece cyberpunk heist novel.',
      isLiked: false,
    ),
    BookData(
      id: 4,
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      description: 'A comfortable hobbit is swept away into a dangerous adventure with dwarves.',
      isLiked: false,
    ),
    BookData(
      id: 5,
      title: 'Dracula',
      author: 'Bram Stoker',
      description: 'The classic gothic horror tale of the ancient vampire tracking new prey.',
      isLiked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: 5,
              itemBuilder: (context, index) {
          
                // get specific book
                final currentBook = _sampleBooks[index];
          
                // return the book widget here
                return Book(
                  book: currentBook,
                  onLikeTapped: () {
          
                    // trigger state refresh on the parent screen
                    setState(() {
                      currentBook.isLiked = !currentBook.isLiked;
                    });
          
                    // print statement to debug
                    print("${currentBook.title} liked status: ${currentBook.isLiked}");
                  },
                );
              }
          ),
        ),
    );
  }
}

