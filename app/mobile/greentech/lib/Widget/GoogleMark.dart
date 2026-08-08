import 'package:flutter/material.dart';

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _viewBox = 48.0;

  static const _paths = <String, Color>{
    'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z':
        Color(0xFF4285F4),
    'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z':
        Color(0xFF34A853),
    'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24s.85 6.91 2.34 9.88l7.35-5.7z':
        Color(0xFFFBBC05),
    'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z':
        Color(0xFFEA4335),
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox, size.height / _viewBox);

    _paths.forEach((data, color) {
      canvas.drawPath(_parsePath(data), Paint()..color = color);
    });

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final _tokenPattern = RegExp(r'[MmLlHhVvCcSsZz]|-?\d*\.?\d+');

Path _parsePath(String data) {
  final path = Path();
  final tokens = _tokenPattern.allMatches(data).map((m) => m[0]!).toList();

  double x = 0, y = 0, startX = 0, startY = 0, ctrlX = 0, ctrlY = 0;
  String command = '';
  var i = 0;

  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    final token = tokens[i];
    if (RegExp(r'[A-Za-z]').hasMatch(token)) {
      command = token;
      i++;
      if (command == 'Z' || command == 'z') {
        path.close();
        x = startX;
        y = startY;
        continue;
      }
    }

    final relative = command == command.toLowerCase();
    final originX = relative ? x : 0.0;
    final originY = relative ? y : 0.0;

    switch (command.toUpperCase()) {
      case 'M':
        x = originX + next();
        y = originY + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        command = relative ? 'l' : 'L';
      case 'L':
        x = originX + next();
        y = originY + next();
        path.lineTo(x, y);
      case 'H':
        x = originX + next();
        path.lineTo(x, y);
      case 'V':
        y = originY + next();
        path.lineTo(x, y);
      case 'C':
        final x1 = originX + next();
        final y1 = originY + next();
        final x2 = originX + next();
        final y2 = originY + next();
        x = originX + next();
        y = originY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
      case 'S':
        final x1 = 2 * x - ctrlX;
        final y1 = 2 * y - ctrlY;
        final x2 = originX + next();
        final y2 = originY + next();
        x = originX + next();
        y = originY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
      default:
        i++;
    }
  }

  return path;
}
