import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final bool isDark;

  const AppLogo({
    Key? key,
    this.height = 40,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/dt7_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -10,
                top: -10,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Stack(
                    children: [
                      Positioned(left: 0, top: 0, child: Container(width: 4, height: 4, color: const Color(0xFFFF5000))),
                      Positioned(left: 5, top: 0, child: Container(width: 4, height: 4, color: const Color(0xFFFF5000))),
                      Positioned(left: 0, top: 5, child: Container(width: 4, height: 4, color: const Color(0xFFFF5000))),
                      Positioned(left: 6, top: 6, child: Container(width: 6, height: 6, color: const Color(0xFFFF5000))),
                    ],
                  ),
                ),
              ),
              Text(
                'DT7.',
                style: TextStyle(
                  fontSize: height * 0.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF5000),
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AGENCY',
            style: TextStyle(
              fontSize: height * 0.16,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.5,
              color: isDark ? Colors.white70 : const Color(0xFF262626),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
