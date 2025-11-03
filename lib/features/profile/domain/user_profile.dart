class UserProfile {
  final String username;
  final int gamesPlayed;
  final int roundsWon;
  final String favoriteMood;
  final String? avatarPath;

  const UserProfile({
    required this.username,
    required this.gamesPlayed,
    required this.roundsWon,
    required this.favoriteMood,
    this.avatarPath,
  });

  UserProfile copyWith({
    String? username,
    int? gamesPlayed,
    int? roundsWon,
    String? favoriteMood,
    String? avatarPath,
  }) {
    return UserProfile(
      username: username ?? this.username,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      roundsWon: roundsWon ?? this.roundsWon,
      favoriteMood: favoriteMood ?? this.favoriteMood,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'gamesPlayed': gamesPlayed,
      'roundsWon': roundsWon,
      'favoriteMood': favoriteMood,
      'avatarPath': avatarPath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String,
      gamesPlayed: json['gamesPlayed'] as int,
      roundsWon: json['roundsWon'] as int,
      favoriteMood: json['favoriteMood'] as String,
      avatarPath: json['avatarPath'] as String?,
    );
  }
}
