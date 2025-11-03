import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_profile.dart';

/// Mock repository - Future'da Firebase/Firestore entegrasyonu yapılacak
Future<UserProfile> _fetchUserProfile() async {
  // Simüle edilmiş gecikme (ağ isteği gibi)
  await Future.delayed(const Duration(seconds: 1));

  // Şimdilik mock data döndürüyoruz
  // Future: Firebase/Firestore'tan gerçek veri çekilecek
  return const UserProfile(
    username: 'Oyuncu',
    gamesPlayed: 12,
    roundsWon: 45,
    favoriteMood: 'Ne zaman mutlu hissediyorum?',
    avatarPath: 'lib/assets/avatar/5.png',
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
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  () => ProfileNotifier(),
);
