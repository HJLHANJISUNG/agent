import 'package:flutter/material.dart';

class AuroraBackground extends StatelessWidget {
  final Widget? child;
  const AuroraBackground({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Aurora 漸變層
        Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 主色塊（更淡）
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFFFFE0B2).withOpacity(0.45), // 淡橙
          Color(0xFFF8BBD0).withOpacity(0.35), // 淡粉
          Color(0xFFBBDEFB).withOpacity(0.35), // 淡藍
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.3),
        width: size.width * 0.9,
        height: size.height * 0.5,
      ),
      paint1,
    );
    // 第二層色塊（更淡）
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFFB2FFDB).withOpacity(0.25), // 淡綠
          Color(0xFFB2EBF2).withOpacity(0.18), // 淡青
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.6),
        width: size.width * 0.7,
        height: size.height * 0.4,
      ),
      paint2,
    );
    // 第三層色塊（更淡）
    final paint3 = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFFF8BBD0).withOpacity(0.15), // 更淡粉
          Color(0xFFBBDEFB).withOpacity(0.12), // 更淡藍
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.9),
        width: size.width * 0.8,
        height: size.height * 0.3,
      ),
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
