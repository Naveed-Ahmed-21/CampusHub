import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/api_endpoints.dart';
import '../theme/app_colors.dart';
import '../../shared/widgets/full_screen_image_viewer.dart';

/// Unified, high-performance cached avatar widget for CampusHub.
/// - Uses [CachedNetworkImage] for persistent disk & memory caching
/// - Resolves relative/backend URLs automatically
/// - Displays elegant fallback initials when no image is present
/// - Prevents pull-to-refresh image reloads & eliminates scrolling lag
class CampusAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool enableFullScreenOnTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Border? border;
  final BoxShape shape;
  final Object? heroTag;

  const CampusAvatar({
    super.key,
    this.avatarUrl,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.onTap,
    this.enableFullScreenOnTap = false,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.shape = BoxShape.circle,
    this.heroTag,
  });

  String _getInitials(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts[0][0].toUpperCase();
      final second = parts[1][0].toUpperCase();
      return '$first$second';
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(name);
    final size = radius * 2;

    final effectiveUrl = (avatarUrl ?? imageUrl)?.trim();
    final resolvedUrl = effectiveUrl != null && effectiveUrl.isNotEmpty
        ? ApiEndpoints.resolveUrl(effectiveUrl)
        : null;

    final defaultBg = backgroundColor ??
        (isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4));
    final defaultFg = textColor ??
        (isDark ? Colors.white : AppColors.primaryText);

    Widget avatarContent;

    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: defaultBg,
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: defaultFg,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.75,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: defaultBg,
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: defaultFg,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.75,
              ),
            ),
          ),
        ),
      );
    } else {
      avatarContent = Container(
        width: size,
        height: size,
        color: defaultBg,
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: defaultFg,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.75,
            ),
          ),
        ),
      );
    }

    Widget result = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarContent,
    );

    if (heroTag != null) {
      result = Hero(
        tag: heroTag!,
        child: result,
      );
    }

    if (onTap != null || (enableFullScreenOnTap && resolvedUrl != null)) {
      result = GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (enableFullScreenOnTap && resolvedUrl != null) {
            FullScreenImageViewer.open(
              context,
              images: [
                FullScreenImageData.fromUrl(
                  resolvedUrl,
                  title: name,
                  heroTag: heroTag?.toString() ?? 'avatar_$resolvedUrl',
                ),
              ],
            );
          }
        },
        child: result,
      );
    }

    return result;
  }
}
