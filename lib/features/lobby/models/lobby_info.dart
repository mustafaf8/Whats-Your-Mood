class LobbyInfo {
  final String gameId;
  final String lobbyName;
  final String hostUsername;
  final int playerCount;
  final int maxPlayers;
  final bool hasPassword;

  const LobbyInfo({
    required this.gameId,
    required this.lobbyName,
    required this.hostUsername,
    required this.playerCount,
    required this.maxPlayers,
    required this.hasPassword,
  });

  factory LobbyInfo.fromJson(String gameId, Map<String, dynamic> json) {
    return LobbyInfo(
      gameId: gameId,
      lobbyName: json['lobbyName'] as String? ?? '',
      hostUsername: json['hostUsername'] as String? ?? '',
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 6,
      hasPassword: json['hasPassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lobbyName': lobbyName,
      'hostUsername': hostUsername,
      'playerCount': playerCount,
      'maxPlayers': maxPlayers,
      'hasPassword': hasPassword,
    };
  }

  bool get isFull => playerCount >= maxPlayers;
}

