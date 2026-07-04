import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/theme/theme_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../services/iap_service.dart';
import 'settings_cubit.dart';

// ---------------------------------------------------------------------------
// Entry point — provisions cubit
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SettingsCubit(GetIt.I<SettingsRepository>())..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main view
// ---------------------------------------------------------------------------

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.backgroundTop, theme.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _SettingsAppBar(),
              Expanded(
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _SectionHeader(label: '🎵  Audio'),
                      _AudioSection(state: state),
                      const SizedBox(height: 24),
                      _SectionHeader(label: '🎨  Theme'),
                      _ThemeSection(selectedIndex: state.selectedThemeIndex),
                      const SizedBox(height: 24),
                      _SectionHeader(label: '🛒  Purchases'),
                      const _PurchasesSection(),
                      const SizedBox(height: 24),
                      _SectionHeader(label: 'ℹ️  Info'),
                      const _InfoSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _SettingsAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: theme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: theme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings card
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Audio section
// ---------------------------------------------------------------------------

class _AudioSection extends StatelessWidget {
  final SettingsState state;
  const _AudioSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final theme = context.bloomkuTheme;

    return _SettingsCard(
      child: Column(
        children: [
          _SliderRow(
            label: 'Music Volume',
            icon: Icons.music_note_rounded,
            value: state.musicVolume,
            onChanged: cubit.updateMusicVolume,
            theme: theme,
          ),
          _Divider(),
          _SliderRow(
            label: 'Sound Effects',
            icon: Icons.volume_up_rounded,
            value: state.sfxVolume,
            onChanged: cubit.updateSfxVolume,
            theme: theme,
          ),
          _Divider(),
          _SwitchRow(
            label: 'Vibration',
            icon: Icons.vibration_rounded,
            value: state.vibrationEnabled,
            onChanged: (_) {
              HapticFeedback.lightImpact();
              cubit.toggleVibration();
            },
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final dynamic theme;

  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.accentColor,
              inactiveTrackColor: theme.accentColor.withValues(alpha: 0.2),
              thumbColor: theme.accentColor,
              overlayColor: theme.accentColor.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final dynamic theme;

  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.accentColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            activeThumbColor: theme.accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.textSecondary.withValues(alpha: 0.12),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme section
// ---------------------------------------------------------------------------

class _ThemeSection extends StatelessWidget {
  final int selectedIndex;
  const _ThemeSection({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final themeCubit = context.read<ThemeCubit>();

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: BloomkuThemes.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final t = BloomkuThemes.all[i];
          final isSelected = selectedIndex == i;
          return _ThemeCard(
            themeData: t,
            isSelected: isSelected,
            onTap: () {
              settingsCubit.selectTheme(i);
              themeCubit.selectTheme(i);
            },
          )
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 250.ms)
              .slideX(begin: 0.1, end: 0, duration: 250.ms);
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeData themeData;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.themeData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [themeData.backgroundTop, themeData.backgroundBottom],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? themeData.accentColor : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.accentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeData.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  themeData.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: themeData.textPrimary,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: themeData.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Purchases section
// ---------------------------------------------------------------------------

class _PurchasesSection extends StatefulWidget {
  const _PurchasesSection();

  @override
  State<_PurchasesSection> createState() => _PurchasesSectionState();
}

class _PurchasesSectionState extends State<_PurchasesSection> {
  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final progressRepo = GetIt.I<ProgressRepository>();
    final adsRemoved = progressRepo.getProgress().adsRemoved;

    final removeAdsProduct = IapService.products[IapService.removeAdsId];
    final hintsProduct = IapService.products[IapService.hintPackId];
    final undosProduct = IapService.products[IapService.undoPackId];

    final hintsPrice = hintsProduct?.price ?? '...\$';
    final undosPrice = undosProduct?.price ?? '...\$';
    final removeAdsPrice = removeAdsProduct?.price;

    return _SettingsCard(
      child: Column(
        children: [
          // Remove Ads
          if (adsRemoved)
            _InfoRow(
              icon: Icons.check_circle_rounded,
              label: 'Ads Removed',
              iconColor: Colors.green,
              textColor: theme.textSecondary,
            )
          else
            _TapRow(
              icon: Icons.block_rounded,
              label: 'Remove Ads',
              trailing: removeAdsPrice,
              onTap: () => IapService.purchase(IapService.removeAdsId),
              theme: theme,
            ),
          _Divider(),
          // Buy Hints
          _TapRow(
            icon: Icons.lightbulb_rounded,
            label: 'Buy 10 Hints',
            trailing: hintsPrice,
            onTap: () => IapService.purchase(IapService.hintPackId),
            theme: theme,
          ),
          _Divider(),
          // Buy Undos
          _TapRow(
            icon: Icons.undo_rounded,
            label: 'Buy 10 Undos',
            trailing: undosPrice,
            onTap: () => IapService.purchase(IapService.undoPackId),
            theme: theme,
          ),
          _Divider(),
          // Restore
          _TapRow(
            icon: Icons.restore_rounded,
            label: 'Restore Purchases',
            trailing: null,
            onTap: () => IapService.restorePurchases(),
            theme: theme,
            isSubtle: true,
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final dynamic theme;
  final bool isSubtle;

  const _TapRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
    required this.theme,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSubtle ? theme.textSecondary : theme.accentColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSubtle ? theme.textSecondary : theme.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info section
// ---------------------------------------------------------------------------

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return _SettingsCard(
      child: Column(
        children: [
          _TapRow(
            icon: Icons.help_outline_rounded,
            label: 'How to Play',
            trailing: null,
            onTap: () => _showHowToPlay(context),
            theme: theme,
          ),
          _Divider(),
          _TapRow(
            icon: Icons.replay_rounded,
            label: 'Replay Tutorial',
            trailing: null,
            onTap: () => _replayTutorial(context),
            theme: theme,
          ),
          _Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Version',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _Divider(),
          _TapRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            trailing: null,
            onTap: () => _launchPrivacyPolicy(),
            theme: theme,
            isSubtle: true,
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    final theme = context.bloomkuTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HowToPlaySheet(theme: theme),
    );
  }

  void _replayTutorial(BuildContext context) {
    GetIt.I<ProgressRepository>().resetTutorialSeen();
    context.push('/tutorial');
  }

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://example.com/privacy',
    ); // replace with real URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// How to play sheet
// ---------------------------------------------------------------------------

class _HowToPlaySheet extends StatelessWidget {
  final dynamic theme;
  const _HowToPlaySheet({required this.theme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How to Play',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textPrimary,
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  _RuleItem(
                    emoji: '🌸',
                    title: 'One per row & column',
                    description:
                        'Place exactly one object in every row and every column.',
                    theme: theme,
                  ),
                  _RuleItem(
                    emoji: '🎨',
                    title: 'One per colour region',
                    description:
                        'Each coloured region must contain exactly one object.',
                    theme: theme,
                  ),
                  _RuleItem(
                    emoji: '↔️',
                    title: 'No adjacency',
                    description: 'Objects may not touch — not even diagonally.',
                    theme: theme,
                  ),
                  _RuleItem(
                    emoji: '🔥',
                    title: 'Hard & Ultra Hard',
                    description:
                        'Hard unlocks at level 15. Ultra Hard unlocks at level 31 with extra rule twists.',
                    theme: theme,
                  ),
                  _RuleItem(
                    emoji: '💡',
                    title: 'Tap and double-tap',
                    description:
                        'Tap once to toggle an × marker. Double-tap to place or remove your object. Wrong placements cost a life.',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final dynamic theme;

  const _RuleItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
