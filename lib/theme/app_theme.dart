import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// 液态玻璃主题 - 苹果 iOS 26 Liquid Glass 风格
class GlassTheme {
  // 背景渐变
  static const Color bgTop = Color(0xFF0A0A0F);
  static const Color bgBottom = Color(0xFF1A1A2E);

  // 液态玻璃颜色
  static Color glassFill = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.18);
  static Color glassHighlight = Colors.white.withOpacity(0.25);

  // 强调色
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentBlue = Color(0xFF6BCBFF);
  static const Color accentPurple = Color(0xFFB084FF);
  static const Color accentGreen = Color(0xFF7BE495);
  static const Color accentOrange = Color(0xFFFFB36B);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: accentPink,
      secondary: accentBlue,
      surface: Color(0xFF1C1C2E),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.white54,
      ),
    ),
  );
}

/// 液态玻璃容器组件 - 核心 Liquid Glass 效果
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 24,
    this.padding,
    this.margin,
    this.tint,
    this.width,
    this.height,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: tint ?? Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.8,
                ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 液态玻璃按钮
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final IconData? icon;

  const GlassButton({
    super.key,
    this.child = const SizedBox(),
    this.onTap,
    this.size = 48,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
            ),
            child: icon != null
                ? Icon(icon, color: Colors.white, size: size * 0.45)
                : child,
          ),
        ),
      ),
    );
  }
}

/// 液态玻璃背景（全局渐变 + 光斑）
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D1A),
            Color(0xFF1A1A3E),
            Color(0xFF2D1B4E),
            Color(0xFF0D1B2A),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 漂浮光斑 - 模拟 Apple Music 背景氛围
          Positioned(
            top: -100,
            left: -50,
            child: _blob(200, GlassTheme.accentPurple.withOpacity(0.25)),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _blob(250, GlassTheme.accentBlue.withOpacity(0.2)),
          ),
          Positioned(
            top: 200,
            right: 50,
            child: _blob(150, GlassTheme.accentPink.withOpacity(0.18)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}
