import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';

/// Displays the current theme's object icon (blossom, shell, etc.)
/// Size defaults to 48x48. Color defaults to theme accent.
class ThemedIcon extends StatelessWidget {
  const ThemedIcon({super.key, this.size = 48.0, this.color, this.iconPath});
  final double size;
  final Color? color;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final path = iconPath ?? theme.objectIconPaths.first;

    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          color ?? theme.accentColor,
          BlendMode.srcIn,
        ),
      );
    } else {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
  }
}
