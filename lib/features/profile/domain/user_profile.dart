class UserProfile {
  final String username;
  final int gamesPlayed;
  final int roundsWon;
  final String favoriteMood;

  const UserProfile({
    required this.username,
    required this.gamesPlayed,
    required this.roundsWon,
    required this.favoriteMood,
  });

  UserProfile copyWith({
    String? username,
    int? gamesPlayed,
    int? roundsWon,
    String? favoriteMood,
  }) {
    return UserProfile(
      username: username ?? this.username,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      roundsWon: roundsWon ?? this.roundsWon,
      favoriteMood: favoriteMood ?? this.favoriteMood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'gamesPlayed': gamesPlayed,
      'roundsWon': roundsWon,
      'favoriteMood': favoriteMood,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String,
      gamesPlayed: json['gamesPlayed'] as int,
      roundsWon: json['roundsWon'] as int,
      favoriteMood: json['favoriteMood'] as String,
    );
  }
}
