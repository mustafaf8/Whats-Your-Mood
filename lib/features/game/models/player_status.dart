class PlayerStatus {
  final String userId;
  final String username;
  final bool hasPlayed;
  final bool isHost;

  const PlayerStatus({
    required this.userId,
    required this.username,
    required this.hasPlayed,
    this.isHost = false,
  });

  PlayerStatus copyWith({
    String? userId,
    String? username,
    bool? hasPlayed,
    bool? isHost,
  }) {
    return PlayerStatus(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      hasPlayed: hasPlayed ?? this.hasPlayed,
      isHost: isHost ?? this.isHost,
    );
  }
}

