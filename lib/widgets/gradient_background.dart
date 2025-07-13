import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget? child;
  const GradientBackground({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFfcda9f), Color(0xFFf99178), Color(0xFF0799f9)],
        ),
      ),
      child: child,
    );
  }
}
