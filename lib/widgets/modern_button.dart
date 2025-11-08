import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';
import '../utils/animations.dart';

/// 🔘 Modern Button Widget
/// Beautiful, animated button with multiple styles and states
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isText;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? loadingWidget;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isText = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.borderRadius = ModernTheme.radiusL,
    this.padding,
    this.textStyle,
    this.loadingWidget,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    Widget buttonChild = _buildButtonContent(theme);
    
    if (widget.gradient != null && !widget.isOutlined && !widget.isText) {
      buttonChild = _buildGradientButton(buttonChild);
    } else if (widget.isOutlined) {
      buttonChild = _buildOutlinedButton(buttonChild, theme);
    } else if (widget.isText) {
      buttonChild = _buildTextButton(buttonChild, theme);
    } else {
      buttonChild = _buildElevatedButton(buttonChild, theme);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: buttonChild,
        );
      },
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    final textColor = widget.foregroundColor ?? 
      (widget.isOutlined || widget.isText 
        ? ModernTheme.primaryBlue 
        : Colors.white);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          widget.loadingWidget ?? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: ModernTheme.spacing12),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: ModernTheme.spacing8),
        ],
        Text(
          widget.text,
          style: widget.textStyle ?? TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(Widget child) {
    return Container(
      width: widget.width,
      height: widget.height ?? 56,
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: ModernTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onPressed != null && !widget.isLoading 
            ? widget.onPressed
            : null,
          child: Container(
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: ModernTheme.spacing24,
              vertical: ModernTheme.spacing16,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(Widget child, ThemeData theme) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 56,
      child: ElevatedButton(
        onPressed: widget.onPressed != null && !widget.isLoading 
          ? widget.onPressed
          : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? ModernTheme.primaryBlue,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          elevation: 4,
          shadowColor: ModernTheme.primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(
            horizontal: ModernTheme.spacing24,
            vertical: ModernTheme.spacing16,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildOutlinedButton(Widget child, ThemeData theme) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 56,
      child: OutlinedButton(
        onPressed: widget.onPressed != null && !widget.isLoading 
          ? widget.onPressed
          : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.foregroundColor ?? ModernTheme.primaryBlue,
          side: BorderSide(
            color: widget.backgroundColor ?? ModernTheme.borderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(
            horizontal: ModernTheme.spacing24,
            vertical: ModernTheme.spacing16,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextButton(Widget child, ThemeData theme) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TextButton(
        onPressed: widget.onPressed != null && !widget.isLoading 
          ? widget.onPressed
          : null,
        style: TextButton.styleFrom(
          foregroundColor: widget.foregroundColor ?? ModernTheme.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(
            horizontal: ModernTheme.spacing16,
            vertical: ModernTheme.spacing8,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 🎯 Floating Action Button with modern styling
class ModernFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool mini;
  final Gradient? gradient;

  const ModernFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
    this.mini = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget fab = FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? ModernTheme.primaryBlue,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernTheme.radiusL),
      ),
      mini: mini,
      child: Icon(icon, size: mini ? 20 : 24),
    );

    if (gradient != null) {
      return Container(
        width: mini ? 40 : size,
        height: mini ? 40 : size,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: ModernTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                size: mini ? 20 : 24,
                color: foregroundColor ?? Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return fab;
  }
}

/// 🔘 Icon Button with modern styling
class ModernIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final double iconSize;
  final bool filled;

  const ModernIconButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 48,
    this.iconSize = 24,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? ModernTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        ),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(
            icon,
            size: iconSize,
            color: foregroundColor ?? ModernTheme.primaryBlue,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: iconSize,
        color: foregroundColor ?? ModernTheme.primaryTextColor,
      ),
    );
  }
}