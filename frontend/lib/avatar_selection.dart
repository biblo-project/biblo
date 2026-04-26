import 'theme.dart';
import 'package:flutter/material.dart';
import 'basic_button.dart';

// this is the mirror to the controller (AvatarSelectionScreenState)
class AvatarTile extends StatelessWidget {
  final int tileId;
  final String assetImagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const AvatarTile({
    super.key,
    required this.tileId,
    required this.assetImagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap, // trigger the parent's logic
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // if the tile is selected then use a different colour for the tile
            border: Border.all(
                color: isSelected? Colors.lightBlueAccent : secondaryColor,
                width: isSelected? 10 : 5,
            ),
          ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                  assetImagePath,
                  fit: BoxFit.cover,
              ),
          ),
        ),
      ),
    );
  }
}

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => AvatarSelectionScreenState();
}

// this is the controller
class AvatarSelectionScreenState extends State<AvatarSelectionScreen>
{
  List<String> avatarAssetImageList = List.generate(16, (index) {
    // I use index + 1 because the list starts at 0, but my images start at 1
        return 'assets/images/avatars/temporary/avatar-${index + 1}.jpg';
  });

  int? selectedIndex;
  // memory of which tile is active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: primaryColor,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                //crossAxisAlignment: CrossAxisAlignment.center,
                // redundant for Column widget
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Text(
                      'Choose an avatar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 30
                      ),
                    ),
                  ),

                  Expanded(
                    child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 avatars per row
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                        ),
                        itemCount: avatarAssetImageList.length,
                        itemBuilder: (context, index) {
                          return AvatarTile(
                              tileId: index,
                              assetImagePath: avatarAssetImageList[index],
                              isSelected: (selectedIndex == index) ? true : false,
                              onTap: () {
                                setState(() {
                                  if(selectedIndex == index)
                                  {    selectedIndex = null;  }

                                  else
                                  {    selectedIndex=index;   }
                                });
                              },
                          );
                        }
                    ),
                  ),

                  // SELECT BUTTON
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: const BasicButton(route: '/home', title: 'SELECT'),
                    /*
                    As of now the button works even if nothing is selected,
                    so I will be updating that later in all the buttons
                    because those buttons will have to be replaced potentially
                     */
                  ),
                ]
            )
        )
    );
  }
}