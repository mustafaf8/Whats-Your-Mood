import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';
import '../domain/user_profile.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => RefreshIndicator(
            onRefresh: () => ref.read(profileProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeaderSection(profile: profile, l10n: l10n),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _QuickActions(
                        l10n: l10n,
                        onEdit: () =>
                            _showEditProfileSheet(context, ref, profile, l10n),
                        onShare: () => _shareProfile(context, l10n),
                        onLogMood: () => _showLogMoodSheet(context, ref, l10n),
                      ),
                      const SizedBox(height: 16),
                      _ProfileStatsCard(profile: profile, l10n: l10n),
                      const SizedBox(height: 16),
                      _MoodHighlightsCard(profile: profile, l10n: l10n),
                      const SizedBox(height: 16),
                      _ChipSection(
                        title: l10n.recentMoods,
                        emptyLabel: l10n.noRecentMoods,
                        items: profile.recentMoods,
                        icon: Icons.emoji_emotions_outlined,
                      ),
                      const SizedBox(height: 16),
                      _ChipSection(
                        title: l10n.achievements,
                        emptyLabel: l10n.noAchievements,
                        items: profile.achievements,
                        icon: Icons.workspace_premium_outlined,
                      ),
                      const SizedBox(height: 16),
                      _BioCard(profile: profile, l10n: l10n),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ProfileErrorState(
            l10n: l10n,
            onRetry: () => ref.read(profileProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final moodController = TextEditingController(text: profile.favoriteMood);
    final bioController = TextEditingController(text: profile.bio);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileEditAction,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: moodController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.favoriteMood),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.profileBioTitle,
                  hintText: l10n.profileBioEmpty,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(profileProvider.notifier)
                          .updateProfile(
                            favoriteMood: moodController.text,
                            bio: bioController.text,
                          );
                      Navigator.of(sheetContext).pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.profileUpdated)),
                      );
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    moodController.dispose();
    bioController.dispose();
  }

  Future<void> _showLogMoodSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final moods = [
      l10n.profileMoodHappy,
      l10n.profileMoodExcited,
      l10n.profileMoodRelaxed,
      l10n.profileMoodCurious,
    ];

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileMoodSheetTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileMoodSheetSubtitle,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...moods.map(
                  (mood) => ListTile(
                    leading: const Icon(Icons.emoji_emotions_outlined),
                    title: Text(mood),
                    onTap: () {
                      ref.read(profileProvider.notifier).logMood(mood);
                      Navigator.of(sheetContext).pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.profileMoodUpdated)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareProfile(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileComingSoon)));
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection({required this.profile, required this.l10n});

  final UserProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.white.withOpacity(0.15),
                  backgroundImage: profile.avatarPath != null
                      ? AssetImage(profile.avatarPath!)
                      : null,
                  child: profile.avatarPath == null
                      ? const Icon(
                          Icons.person,
                          size: 44,
                          color: AppColors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.profileTagline,
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _HeaderChip(
                        icon: Icons.emoji_events_outlined,
                        label: '${l10n.level} ${profile.level}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.completionRate,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: profile.completionRate.clamp(0, 1).toDouble(),
                backgroundColor: AppColors.white.withOpacity(0.25),
                minHeight: 10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(profile.completionRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.l10n,
    required this.onEdit,
    required this.onShare,
    required this.onLogMood,
  });

  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onLogMood;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.profileEditAction),
            ),
            FilledButton.tonalIcon(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.profileShareAction),
            ),
            OutlinedButton.icon(
              onPressed: onLogMood,
              icon: const Icon(Icons.mood),
              label: Text(l10n.profileLogMoodAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({required this.profile, required this.l10n});

  final UserProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statistics,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _StatTile(
                        icon: Icons.sports_esports,
                        label: l10n.gamesPlayed,
                        value: profile.gamesPlayed.toString(),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _StatTile(
                        icon: Icons.emoji_events,
                        label: l10n.roundsWon,
                        value: profile.roundsWon.toString(),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _StatTile(
                        icon: Icons.local_fire_department_outlined,
                        label: l10n.currentStreak,
                        value: '${profile.currentStreak}',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _StatTile(
                        icon: Icons.timeline_outlined,
                        label: l10n.longestStreak,
                        value: '${profile.longestStreak}',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.primaryContainer.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MoodHighlightsCard extends StatelessWidget {
  const _MoodHighlightsCard({required this.profile, required this.l10n});

  final UserProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = profile.lastMoodUpdate != null
        ? DateFormat.yMMMMd(locale).format(profile.lastMoodUpdate!)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.favoriteMood,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sentiment_satisfied_alt_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    profile.favoriteMood.isEmpty
                        ? l10n.noRecentMoods
                        : profile.favoriteMood,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '${l10n.level} ${profile.level}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: profile.completionRate.clamp(0, 1).toDouble(),
              minHeight: 8,
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.completionRate}: ${(profile.completionRate * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history,
                  size: 18,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate != null
                        ? '${l10n.profileLastMoodUpdate}: $formattedDate'
                        : l10n.noRecentMoods,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.icon,
  });

  final String title;
  final String emptyLabel;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (item) =>
                          Chip(avatar: Icon(icon, size: 16), label: Text(item)),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.profile, required this.l10n});

  final UserProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileBioTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              profile.bio.isEmpty ? l10n.profileBioEmpty : profile.bio,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingProfile,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
