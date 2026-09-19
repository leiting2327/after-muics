import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_state.dart';
import '../theme/app_theme.dart';

/// 迷你播放器 - Apple Music 风格底部条
class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, _) {
        final song = state.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Positioned(
          left: 8,
          right: 8,
          bottom: 70,
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      // 封面
                      Hero(
                        tag: 'album_cover',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: song.coverURL != null
                              ? Image.network(
                                  song.coverURL!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 歌名+歌手
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${song.artists} · ${song.sourceName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 进度条
                      SizedBox(
                        width: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LinearProgressIndicator(
                              value: state.duration > 0 ? state.position / state.duration : 0,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 播放/暂停
                      GestureDetector(
                        onTap: () => state.playPause(),
                        child: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      // 下一首
                      GestureDetector(
                        onTap: () => state.playNext(),
                        child: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 歌曲列表项
class TrackTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;
  const TrackTile({
    super.key,
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.coverURL != null
            ? Image.network(
                song.coverURL!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, color: Colors.white38),
                ),
              )
            : Container(
                width: 52,
                height: 52,
                color: Colors.grey.shade800,
                child: const Icon(Icons.music_note, color: Colors.white38),
              ),
      ),
      title: Text(
        song.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        '${song.artists} · ${song.album} · ${song.sourceName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
      ),
      trailing: Icon(
        Icons.more_horiz,
        color: Colors.white.withOpacity(0.4),
      ),
    );
  }
}
