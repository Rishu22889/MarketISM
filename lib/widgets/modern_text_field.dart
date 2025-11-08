import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

/// 📝 Modern Text Field Widget
/// Beautiful, animated input field with validation and modern styling
class ModernTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final bool filled;

  const ModernTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = ModernTheme.radiusL,
    this.filled = true,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _borderColorAnimation = ColorTween(
      begin: widget.borderColor ?? ModernTheme.borderColor,
      end: widget.focusedBorderColor ?? ModernTheme.primaryBlue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Check initial text state
    _hasText = widget.controller?.text.isNotEmpty ?? false;
    if (_hasText || _isFocused) {
      _animationController.value = 1.0;
    }
    
    widget.controller?.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    widget.controller?.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChange() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (_hasText || _isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated label
        if (widget.label != null)
          AnimatedBuilder(
            animation: _labelAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _labelAnimation.value * -8),
                child: Opacity(
                  opacity: 0.3 + (_labelAnimation.value * 0.7),
                  child: Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: 14 - (_labelAnimation.value * 2),
                      fontWeight: FontWeight.w500,
                      color: _isFocused 
                        ? ModernTheme.primaryBlue 
                        : ModernTheme.secondaryTextColor,
                    ),
                  ),
                ),
              );
            },
          ),
        
        if (widget.label != null) const SizedBox(height: ModernTheme.spacing8),
        
        // Text field
        AnimatedBuilder(
          animation: _borderColorAnimation,
          builder: (context, child) {
            return TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ModernTheme.primaryTextColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                helperText: widget.helperText,
                errorText: widget.errorText,
                prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused 
                        ? ModernTheme.primaryBlue 
                        : ModernTheme.hintTextColor,
                      size: 20,
                    )
                  : null,
                suffixIcon: widget.suffixIcon,
                filled: widget.filled,
                fillColor: widget.fillColor ?? ModernTheme.surfaceColor,
                contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
                  horizontal: ModernTheme.spacing16,
                  vertical: ModernTheme.spacing16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: widget.borderColor ?? ModernTheme.borderColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: widget.borderColor ?? ModernTheme.borderColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ?? ModernTheme.primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: const BorderSide(
                    color: ModernTheme.errorRed,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: const BorderSide(
                    color: ModernTheme.errorRed,
                    width: 2,
                  ),
                ),
                hintStyle: TextStyle(
                  color: ModernTheme.hintTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                helperStyle: TextStyle(
                  color: ModernTheme.secondaryTextColor,
                  fontSize: 12,
                ),
                errorStyle: const TextStyle(
                  color: ModernTheme.errorRed,
                  fontSize: 12,
                ),
                counterStyle: TextStyle(
                  color: ModernTheme.hintTextColor,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 🔍 Search Text Field
class ModernSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final FocusNode? focusNode;

  const ModernSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<ModernSearchField> createState() => _ModernSearchFieldState();
}

class _ModernSearchFieldState extends State<ModernSearchField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ModernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
        border: Border.all(
          color: ModernTheme.borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: 16,
          color: ModernTheme.primaryTextColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Search...',
          hintStyle: TextStyle(
            color: ModernTheme.hintTextColor,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ModernTheme.hintTextColor,
            size: 20,
          ),
          suffixIcon: _hasText
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: ModernTheme.hintTextColor,
                  size: 20,
                ),
                onPressed: _clearText,
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ModernTheme.spacing16,
            vertical: ModernTheme.spacing12,
          ),
        ),
      ),
    );
  }
}

/// 📝 Multi-line Text Field
class ModernTextArea extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const ModernTextArea({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 4,
    this.maxLength,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ModernTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
    );
  }
}