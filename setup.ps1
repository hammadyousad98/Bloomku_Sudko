$target = "e:\Work\Personal Project (Shooter)\sudko\bloomku"
cd $target

$dirs = @(
  "lib/core/constants",
  "lib/core/theme",
  "lib/router",
  "lib/utils",
  "lib/data/objectbox",
  "lib/data/models",
  "lib/data/repositories",
  "lib/features/splash",
  "lib/features/tutorial",
  "lib/features/main_menu",
  "lib/features/level_select",
  "lib/features/game/cubit",
  "lib/features/game/widgets",
  "lib/features/daily_rewards",
  "lib/features/daily_challenges",
  "lib/features/settings",
  "lib/services",
  "lib/widgets/common",
  "lib/widgets/ads",
  "assets/icons",
  "assets/audio/music",
  "assets/audio/sfx",
  "assets/lottie",
  "assets/fonts"
)

foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$files = @(
  "lib/core/constants/app_constants.dart",
  "lib/core/constants/ad_constants.dart",
  "lib/core/theme/app_theme.dart",
  "lib/core/theme/theme_model.dart",
  "lib/core/theme/theme_cubit.dart",
  "lib/router/app_router.dart",
  "lib/utils/puzzle_generator.dart",
  "lib/utils/extensions.dart",
  "lib/data/objectbox/objectbox.dart",
  "lib/data/models/player_progress.dart",
  "lib/data/models/daily_reward_state.dart",
  "lib/data/models/settings_model.dart",
  "lib/data/repositories/progress_repository.dart",
  "lib/data/repositories/reward_repository.dart",
  "lib/data/repositories/settings_repository.dart",
  "lib/features/splash/splash_screen.dart",
  "lib/features/tutorial/tutorial_cubit.dart",
  "lib/features/tutorial/tutorial_screen.dart",
  "lib/features/main_menu/main_menu_cubit.dart",
  "lib/features/main_menu/main_menu_screen.dart",
  "lib/features/level_select/level_select_cubit.dart",
  "lib/features/level_select/level_select_screen.dart",
  "lib/features/game/cubit/game_cubit.dart",
  "lib/features/game/cubit/game_state.dart",
  "lib/features/game/widgets/puzzle_grid.dart",
  "lib/features/game/widgets/grid_tile.dart",
  "lib/features/game/widgets/rules_panel.dart",
  "lib/features/game/widgets/difficulty_bar.dart",
  "lib/features/game/widgets/top_bar.dart",
  "lib/features/game/widgets/progress_row.dart",
  "lib/features/game/widgets/bottom_buttons.dart",
  "lib/features/game/game_screen.dart",
  "lib/features/daily_rewards/daily_reward_cubit.dart",
  "lib/features/daily_rewards/daily_reward_screen.dart",
  "lib/features/daily_challenges/daily_challenges_screen.dart",
  "lib/features/settings/settings_cubit.dart",
  "lib/features/settings/settings_screen.dart",
  "lib/services/ad_service.dart",
  "lib/services/iap_service.dart",
  "lib/services/audio_service.dart",
  "lib/widgets/common/bloomku_button.dart",
  "lib/widgets/common/bloomku_dialog.dart",
  "lib/widgets/common/themed_icon.dart",
  "lib/widgets/ads/banner_ad_widget.dart"
)

foreach ($file in $files) {
  New-Item -ItemType File -Force -Path $file | Out-Null
}

$blossom = '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="20" fill="#E8829A" /></svg>'
Set-Content -Path "assets/icons/blossom.svg" -Value $blossom

$shell = '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="20" fill="#4ABBC4" /></svg>'
Set-Content -Path "assets/icons/shell.svg" -Value $shell

$mushroom = '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="20" fill="#5A8A52" /></svg>'
Set-Content -Path "assets/icons/mushroom.svg" -Value $mushroom

$star = '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="20" fill="#C8A84B" /></svg>'
Set-Content -Path "assets/icons/star.svg" -Value $star

$sunflower = '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="20" fill="#E8824A" /></svg>'
Set-Content -Path "assets/icons/sunflower.svg" -Value $sunflower
