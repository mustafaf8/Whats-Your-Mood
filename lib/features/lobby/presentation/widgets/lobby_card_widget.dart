import 'package:flutter/material.dart';
import '../../models/lobby_info.dart';

class LobbyCardWidget extends StatelessWidget {
  final LobbyInfo lobby;
  final VoidCallback? onTap;

  const LobbyCardWidget({super.key, required this.lobby, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = lobby.isFull || onTap == null;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lobby.lobbyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (lobby.hasPassword)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.lock, size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ev Sahibi: ${lobby.hostUsername}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${lobby.playerCount}/${lobby.maxPlayers} Oyuncu',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: isDisabled
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


