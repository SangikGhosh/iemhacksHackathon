import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // No back button
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Home',
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
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: Colors.black,
                size: 24,
              ),
              onPressed: () {
                // Navigator.pushNamed(context, '/notifications');
              },
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Home Screen Content",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}
