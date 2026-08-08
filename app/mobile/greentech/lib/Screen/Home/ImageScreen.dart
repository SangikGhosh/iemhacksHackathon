import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Image',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to Profile Screen
                // Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.withOpacity(0.15),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Image Screen Content",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}
