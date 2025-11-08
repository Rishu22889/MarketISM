import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility class for consistent spacing throughout the app
/// Based on 8pt baseline grid system
class Spacing {
  // Vertical spacing widgets
  static const Widget v4 = SizedBox(height: AppTheme.spacing4);
  static const Widget v8 = SizedBox(height: AppTheme.spacing8);
  static const Widget v12 = SizedBox(height: AppTheme.spacing12);
  static const Widget v16 = SizedBox(height: AppTheme.spacing16);
  static const Widget v20 = SizedBox(height: AppTheme.spacing20);
  static const Widget v24 = SizedBox(height: AppTheme.spacing24);
  static const Widget v32 = SizedBox(height: AppTheme.spacing32);
  static const Widget v40 = SizedBox(height: AppTheme.spacing40);
  static const Widget v48 = SizedBox(height: AppTheme.spacing48);
  static const Widget v64 = SizedBox(height: AppTheme.spacing64);

  // Horizontal spacing widgets
  static const Widget h4 = SizedBox(width: AppTheme.spacing4);
  static const Widget h8 = SizedBox(width: AppTheme.spacing8);
  static const Widget h12 = SizedBox(width: AppTheme.spacing12);
  static const Widget h16 = SizedBox(width: AppTheme.spacing16);
  static const Widget h20 = SizedBox(width: AppTheme.spacing20);
  static const Widget h24 = SizedBox(width: AppTheme.spacing24);
  static const Widget h32 = SizedBox(width: AppTheme.spacing32);
  static const Widget h40 = SizedBox(width: AppTheme.spacing40);
  static const Widget h48 = SizedBox(width: AppTheme.spacing48);
  static const Widget h64 = SizedBox(width: AppTheme.spacing64);

  // Edge insets
  static const EdgeInsets all4 = EdgeInsets.all(AppTheme.spacing4);
  static const EdgeInsets all8 = EdgeInsets.all(AppTheme.spacing8);
  static const EdgeInsets all12 = EdgeInsets.all(AppTheme.spacing12);
  static const EdgeInsets all16 = EdgeInsets.all(AppTheme.spacing16);
  static const EdgeInsets all20 = EdgeInsets.all(AppTheme.spacing20);
  static const EdgeInsets all24 = EdgeInsets.all(AppTheme.spacing24);
  static const EdgeInsets all32 = EdgeInsets.all(AppTheme.spacing32);

  // Horizontal padding
  static const EdgeInsets horizontal4 = EdgeInsets.symmetric(horizontal: AppTheme.spacing4);
  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(horizontal: AppTheme.spacing8);
  static const EdgeInsets horizontal12 = EdgeInsets.symmetric(horizontal: AppTheme.spacing12);
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: AppTheme.spacing16);
  static const EdgeInsets horizontal20 = EdgeInsets.symmetric(horizontal: AppTheme.spacing20);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: AppTheme.spacing24);
  static const EdgeInsets horizontal32 = EdgeInsets.symmetric(horizontal: AppTheme.spacing32);

  // Vertical padding
  static const EdgeInsets vertical4 = EdgeInsets.symmetric(vertical: AppTheme.spacing4);
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: AppTheme.spacing8);
  static const EdgeInsets vertical12 = EdgeInsets.symmetric(vertical: AppTheme.spacing12);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: AppTheme.spacing16);
  static const EdgeInsets vertical20 = EdgeInsets.symmetric(vertical: AppTheme.spacing20);
  static const EdgeInsets vertical24 = EdgeInsets.symmetric(vertical: AppTheme.spacing24);
  static const EdgeInsets vertical32 = EdgeInsets.symmetric(vertical: AppTheme.spacing32);

  // Page padding (standard page margins)
  static const EdgeInsets page = EdgeInsets.all(AppTheme.spacing16);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: AppTheme.spacing16);
  static const EdgeInsets pageVertical = EdgeInsets.symmetric(vertical: AppTheme.spacing16);

  // Card padding
  static const EdgeInsets card = EdgeInsets.all(AppTheme.spacing16);
  static const EdgeInsets cardSmall = EdgeInsets.all(AppTheme.spacing12);
  static const EdgeInsets cardLarge = EdgeInsets.all(AppTheme.spacing24);

  // List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: AppTheme.spacing16,
    vertical: AppTheme.spacing12,
  );
  static const EdgeInsets listItemDense = EdgeInsets.symmetric(
    horizontal: AppTheme.spacing16,
    vertical: AppTheme.spacing8,
  );

  // Button padding
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppTheme.spacing24,
    vertical: AppTheme.spacing12,
  );
  static const EdgeInsets buttonSmall = EdgeInsets.symmetric(
    horizontal: AppTheme.spacing16,
    vertical: AppTheme.spacing8,
  );
  static const EdgeInsets buttonLarge = EdgeInsets.symmetric(
    horizontal: AppTheme.spacing32,
    vertical: AppTheme.spacing16,
  );

  // Custom spacing methods
  static Widget vertical(double height) => SizedBox(height: height);
  static Widget horizontal(double width) => SizedBox(width: width);
  
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => EdgeInsets.only(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );

  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) => EdgeInsets.symmetric(
    horizontal: horizontal,
    vertical: vertical,
  );
}