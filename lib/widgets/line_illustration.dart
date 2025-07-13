import 'package:flutter/material.dart';

class LineIllustration extends StatelessWidget {
  final double height;
  final double width;
  const LineIllustration({Key? key, this.height = 120, this.width = 240})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _LineIllustrationPainter(),
    );
  }
}

class _LineIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // 畫一些線條風格的抽象插畫
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.5,
      size.width * 0.4,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.9,
      size.width * 0.8,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.4,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(path, paint);
    // 可根據需要增加更多線條
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
