import 'package:flutter/material.dart';

void main() => runApp(const GreenRoute());

class GreenRoute extends StatelessWidget {
  const GreenRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [

            // Background picture
            Image.asset(
              'assets/image/splash_bg.png',
              fit: BoxFit.cover,
            ),

            // Logo + text
            Column(
              children: [
                const SizedBox(height: 55),

                Image.asset(
                  'assets/image/logo.png',
                  width: 190,
                ),

                const SizedBox(height: 5),

                const Text(
                  'GreenRoute',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF159447),
                  ),
                ),

                const Text(
                  'WASTE SMART  |  CITY CLEAN  |  FUTURE GREEN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14517A),
                  ),
                ),

                const Spacer(),

                const Text(
                  'Together for a\nCleaner Today, Greener Tomorrow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: 160,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFFD8E8D5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF3FAE2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ],
        ),
      ),
    );
  }
}