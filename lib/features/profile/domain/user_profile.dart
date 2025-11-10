class UserProfile {
  final String username;
  final int gamesPlayed;
  final int roundsWon;
  final String favoriteMood;
  final String? avatarPath;
  final String bio;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final List<String> recentMoods;
  final List<String> achievements;
  final DateTime? lastMoodUpdate;

  const UserProfile({
    required this.username,
    required this.gamesPlayed,
    required this.roundsWon,
    required this.favoriteMood,
    this.avatarPath,
    this.bio = '',
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionRate = 0,
    this.recentMoods = const [],
    this.achievements = const [],
    this.lastMoodUpdate,
  });

  UserProfile copyWith({
    String? username,
    int? gamesPlayed,
    int? roundsWon,
    String? favoriteMood,
    String? avatarPath,
    String? bio,
    int? level,
    int? currentStreak,
    int? longestStreak,
    double? completionRate,
    List<String>? recentMoods,
    List<String>? achievements,
    DateTime? lastMoodUpdate,
  }) {
    return UserProfile(
      username: username ?? this.username,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      roundsWon: roundsWon ?? this.roundsWon,
      favoriteMood: favoriteMood ?? this.favoriteMood,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
      recentMoods: recentMoods ?? this.recentMoods,
      achievements: achievements ?? this.achievements,
      lastMoodUpdate: lastMoodUpdate ?? this.lastMoodUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'gamesPlayed': gamesPlayed,
      'roundsWon': roundsWon,
      'favoriteMood': favoriteMood,
      'avatarPath': avatarPath,
      'bio': bio,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completionRate': completionRate,
      'recentMoods': recentMoods,
      'achievements': achievements,
      'lastMoodUpdate': lastMoodUpdate?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String,
      gamesPlayed: json['gamesPlayed'] as int,
      roundsWon: json['roundsWon'] as int,
      favoriteMood: json['favoriteMood'] as String,
      avatarPath: json['avatarPath'] as String?,
      bio: json['bio'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      recentMoods:
          (json['recentMoods'] as List<dynamic>?)
              ?.map((dynamic mood) => mood as String)
              .toList() ??
          const [],
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map((dynamic achievement) => achievement as String)
              .toList() ??
          const [],
      lastMoodUpdate: json['lastMoodUpdate'] != null
          ? DateTime.tryParse(json['lastMoodUpdate'] as String)
          : null,
    );
  }
}
