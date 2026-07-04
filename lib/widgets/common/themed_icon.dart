import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';

/// Displays the current theme's object icon (blossom, shell, etc.)
/// Size defaults to 48x48. Color defaults to theme accent.
class ThemedIcon extends StatelessWidget {
  const ThemedIcon({super.key, this.size = 48.0, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return SvgPicture.asset(
      theme.objectIconPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? theme.accentColor,
        BlendMode.srcIn,
      ),
    );
  }
}
