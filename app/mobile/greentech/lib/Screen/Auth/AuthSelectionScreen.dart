import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Learnify',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                context.go('/login-student');
              },
              child: const Text('Student Login'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                context.go('/register-student');
              },
              child: const Text('Student Register'),
            ),
          ],
        ),
      ),
    );
  }
}
