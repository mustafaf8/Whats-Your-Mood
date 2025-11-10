import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_profile.dart';

/// Mock repository - Future'da Firebase/Firestore entegrasyonu yapılacak
Future<UserProfile> _fetchUserProfile() async {
  // Simüle edilmiş gecikme (ağ isteği gibi)
  await Future.delayed(const Duration(seconds: 1));

  // Şimdilik mock data döndürüyoruz
  // Future: Firebase/Firestore'tan gerçek veri çekilecek
  return UserProfile(
    username: 'Oyuncu',
    gamesPlayed: 36,
    roundsWon: 18,
    favoriteMood: 'Ne zaman mutlu hissediyorum?',
    avatarPath: 'lib/assets/avatar/5.png',
    bio: 'Arkadaşlarımla beraber en yaratıcı cevapları bulmayı seviyorum.',
    level: 7,
    currentStreak: 3,
    longestStreak: 9,
    completionRate: 0.72,
    recentMoods: const ['Enerjik', 'Meraklı', 'Rahat'],
    achievements: const ['Mood Master', 'Trendsetter', 'Team Player'],
    lastMoodUpdate: DateTime(2025, 11, 8),
  );
}

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return await _fetchUserProfile();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUserProfile());
  }

  void setAvatar(String path) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(avatarPath: path));
    // TODO: Persist to backend when integrated
  }

  void updateProfile({String? favoriteMood, String? bio}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        favoriteMood: favoriteMood ?? current.favoriteMood,
        bio: bio ?? current.bio,
      ),
    );
  }

  void updateBio(String bio) {
    updateProfile(bio: bio.trim());
  }

  void updateFavoriteMood(String mood) {
    updateProfile(favoriteMood: mood.trim());
  }

  void logMood(String mood) {
    final current = state.value;
    if (current == null) return;
    final updatedMoods = <String>[mood, ...current.recentMoods];
    final limitedMoods = updatedMoods.take(6).toList();
    state = AsyncValue.data(
      current.copyWith(
        recentMoods: limitedMoods,
        favoriteMood: current.favoriteMood.isEmpty
            ? mood
            : current.favoriteMood,
        lastMoodUpdate: DateTime.now(),
      ),
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  () => ProfileNotifier(),
);
