import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/modern_theme.dart';

class CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    // If URL is invalid or empty, show error widget immediately
    if (widget.imageUrl.isEmpty || !ImageService.isValidImageUrl(widget.imageUrl)) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: _hasError
            ? _buildErrorWidget()
            : Stack(
                children: [
                  // Loading placeholder
                  if (_isLoading) _buildPlaceholder(),
                  
                  // Actual image
                  Image.network(
                    widget.imageUrl,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        // Image loaded successfully
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        });
                        return child;
                      }
                      
                      // Still loading
                      return _buildPlaceholder();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Image load error: $error');
                      debugPrint('❌ Failed URL: ${widget.imageUrl}');
                      
                      // Error loading image - try fallback
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _hasError = true;
                            _isLoading = false;
                          });
                        }
                      });
                      return _buildErrorWidget();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModernTheme.primaryBlue.withOpacity(0.1),
            ModernTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.withOpacity(0.1),
            Colors.grey.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: (widget.width != null && widget.width! < 100) ? 24 : 40,
            color: Colors.grey[400],
          ),
          if (widget.width == null || widget.width! >= 100) ...[
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Specialized widget for item images with consistent styling
class ItemImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;

  const ItemImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
        ),
        
        // Badge overlay
        if (showBadge && badgeText != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? ModernTheme.primaryBlue).withOpacity(0.9),
                borderRadius: BorderRadius.circular(ModernTheme.radiusS),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}