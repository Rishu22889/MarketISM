import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

/// ✨ Modern Animation Utilities for MarketISM
/// Beautiful, smooth animations that enhance user experience
class AppAnimations {
  // Animation Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Animation Curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// 🌟 Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = medium,
    double delay = 0.0,
    Curve curve = easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 📱 Slide in from bottom animation
  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = medium,
    double offset = 50.0,
    Curve curve = fastOutSlowIn,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1 - (value / offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// 🎯 Scale in animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = medium,
    double initialScale = 0.8,
    Curve curve = elasticOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: initialScale, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 📋 Staggered list animation
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration duration = medium,
    double offset = 30.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: duration.inMilliseconds + (index * 100)),
      curve: fastOutSlowIn,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// ✨ Shimmer loading animation
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor ?? ModernTheme.borderColor,
                highlightColor ?? ModernTheme.surfaceColor,
                baseColor ?? ModernTheme.borderColor,
              ],
              stops: [0.0, 0.5, 1.0],
              transform: GradientRotation(value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// 🎪 Bounce animation for buttons
  static Widget bounceOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _BounceWidget(
      child: child,
      onTap: onTap,
      scale: scale,
      duration: duration,
    );
  }

  /// 🌈 Gradient animation
  static Widget animatedGradient({
    required Widget child,
    required List<Color> colors,
    Duration duration = const Duration(seconds: 3),
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: colors.map((color) => 
                Color.lerp(color, color.withOpacity(0.8), value) ?? color
              ).toList(),
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// 🔄 Rotation animation
  static Widget rotate({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
    bool repeat = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 💫 Pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 🎭 Hero animation wrapper
  static Widget hero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }

  /// 📄 Page transition animations
  static PageRouteBuilder<T> createRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    PageTransitionType type = PageTransitionType.slideFromRight,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case PageTransitionType.slideFromRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: fastOutSlowIn,
              )),
              child: child,
            );
          case PageTransitionType.slideFromBottom:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: fastOutSlowIn,
              )),
              child: child,
            );
          case PageTransitionType.fade:
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          case PageTransitionType.scale:
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: fastOutSlowIn,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
        }
      },
    );
  }
}

/// Page transition types
enum PageTransitionType {
  slideFromRight,
  slideFromBottom,
  fade,
  scale,
}

/// Internal bounce widget
class _BounceWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration duration;

  const _BounceWidget({
    required this.child,
    required this.onTap,
    required this.scale,
    required this.duration,
  });

  @override
  _BounceWidgetState createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<_BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 🎨 Animation Extensions
extension AnimationExtensions on Widget {
  /// Quick fade in
  Widget fadeIn({Duration duration = const Duration(milliseconds: 300)}) {
    return AppAnimations.fadeIn(child: this, duration: duration);
  }

  /// Quick slide in from bottom
  Widget slideInFromBottom({Duration duration = const Duration(milliseconds: 300)}) {
    return AppAnimations.slideInFromBottom(child: this, duration: duration);
  }

  /// Quick scale in
  Widget scaleIn({Duration duration = const Duration(milliseconds: 300)}) {
    return AppAnimations.scaleIn(child: this, duration: duration);
  }

  /// Quick shimmer
  Widget shimmer() {
    return AppAnimations.shimmer(child: this);
  }

  /// Quick hero
  Widget hero(String tag) {
    return AppAnimations.hero(tag: tag, child: this);
  }
}