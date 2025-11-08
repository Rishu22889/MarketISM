import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Utility class for accessibility helpers and constants
class Accessibility {
  // Minimum touch target size (44x44 dp as per Material Design guidelines)
  static const double minTouchTargetSize = 44.0;
  
  // Minimum contrast ratios
  static const double normalTextContrast = 4.5;
  static const double largeTextContrast = 3.0;
  
  /// Creates a semantic label for screen readers
  static String createLabel({
    required String text,
    String? hint,
    String? value,
    bool isButton = false,
    bool isSelected = false,
    bool isExpanded = false,
  }) {
    final buffer = StringBuffer(text);
    
    if (value != null && value.isNotEmpty) {
      buffer.write(', $value');
    }
    
    if (isButton) {
      buffer.write(', button');
    }
    
    if (isSelected) {
      buffer.write(', selected');
    }
    
    if (isExpanded) {
      buffer.write(', expanded');
    }
    
    if (hint != null && hint.isNotEmpty) {
      buffer.write(', $hint');
    }
    
    return buffer.toString();
  }
  
  /// Wraps a widget with proper semantics for accessibility
  static Widget wrapWithSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool isButton = false,
    bool isSelected = false,
    bool isExpanded = false,
    bool excludeSemantics = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: createLabel(
        text: label,
        hint: hint,
        value: value,
        isButton: isButton,
        isSelected: isSelected,
        isExpanded: isExpanded,
      ),
      button: isButton,
      selected: isSelected,
      expanded: isExpanded,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: child,
    );
  }
  
  /// Creates an accessible button with minimum touch target
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? semanticHint,
    EdgeInsets? padding,
    double minSize = minTouchTargetSize,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            padding: padding ?? const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// Announces a message to screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
  
  /// Creates accessible form field with proper labels
  static Widget accessibleFormField({
    required Widget child,
    required String label,
    String? hint,
    String? error,
    bool required = false,
  }) {
    final semanticLabel = required ? '$label, required field' : label;
    
    return Semantics(
      label: semanticLabel,
      hint: hint,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label + (required ? ' *' : ''),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Creates accessible list item with proper semantics
  static Widget accessibleListItem({
    required Widget child,
    required String label,
    String? subtitle,
    String? value,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final semanticLabel = StringBuffer(label);
    if (subtitle != null) {
      semanticLabel.write(', $subtitle');
    }
    if (value != null) {
      semanticLabel.write(', $value');
    }
    if (selected) {
      semanticLabel.write(', selected');
    }
    
    return Semantics(
      label: semanticLabel.toString(),
      button: onTap != null,
      selected: selected,
      onTap: onTap,
      child: child,
    );
  }
  
  /// Checks if device is using large text scale
  static bool isLargeTextScale(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor > 1.3;
  }
  
  /// Gets appropriate text size based on accessibility settings
  static double getAccessibleTextSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return baseSize * textScaleFactor.clamp(0.8, 2.0);
  }
  
  /// Creates focus-aware widget for keyboard navigation
  static Widget focusableWidget({
    required Widget child,
    required VoidCallback? onTap,
    String? semanticLabel,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: hasFocus
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Semantics(
              label: semanticLabel,
              button: onTap != null,
              focusable: true,
              focused: hasFocus,
              child: GestureDetector(
                onTap: onTap,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}