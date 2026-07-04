import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_model.dart';
import 'theme_cubit.dart';

extension BloomkuThemeExtension on BuildContext {
  AppThemeData get bloomkuTheme => BlocProvider.of<ThemeCubit>(this, listen: true).state;
}

ThemeData bloomkuFlutterTheme(AppThemeData data) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: data.accentColor,
      brightness: data.isDark ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: data.backgroundTop,
    cardColor: data.cardColor,
  );
}
