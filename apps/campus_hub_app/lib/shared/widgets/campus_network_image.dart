import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';

class CampusNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;

  const CampusNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedUrl = ApiEndpoints.resolveUrl(imageUrl);

    if (resolvedUrl.isEmpty) {
      return _buildError(theme);
    }

    Widget imageWidget = Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: frame == null
              ? (placeholder ??
                  Container(
                    width: width,
                    height: height,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ))
              : child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildError(theme);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildError(ThemeData theme) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade500
                  : Colors.grey.shade600,
              size: (height != null && height! < 60) ? 20 : 32,
            ),
          ),
        );
  }
}
