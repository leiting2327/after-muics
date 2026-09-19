import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_state.dart';
import '../theme/app_theme.dart';

/// Apple Music 同款全屏播放器 - 液态玻璃
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showLyric = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, _) {
        final song = state.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // 顶部栏
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 32),
                        ),
                        Column(
                          children: [
                            Text(song.sourceName,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white.withOpacity(0.6))),
                            const Text('正在播放',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                        Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.8)),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 专辑封面 - 液态玻璃旋转唱片效果
                  GestureDetector(
                    onTap: () => setState(() => _showLyric = !_showLyric),
                    child: Hero(
                      tag: 'album_cover',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: MediaQuery.of(context).size.width * 0.75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: song.coverURL != null
                              ? Image.network(
                                  song.coverURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _coverFallback(),
                                )
                              : _coverFallback(),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 歌词 / 歌名区域
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _showLyric
                        ? _lyricView(state)
                        : _songInfo(song.name, song.artists, state),
                  ),

                  const Spacer(),

                  // 进度条
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape:
                                const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: state.position.clamp(0, state.duration),
                            max: state.duration > 0 ? state.duration : 1,
                            onChanged: (v) => state.seek(v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(state.position),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54)),
                              Text(_formatTime(state.duration),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 播放控制按钮 - Apple Music 风格
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 喜欢
                        GlassButton(
                          icon: state.isLiked(song.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 48,
                          onTap: () => state.toggleLike(),
                        ),
                        // 上一首
                        GestureDetector(
                          onTap: () => state.playPrevious(),
                          child: const Icon(Icons.skip_previous_rounded,
                              size: 42, color: Colors.white),
                        ),
                        // 播放/暂停
                        GestureDetector(
                          onTap: () => state.playPause(),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [GlassTheme.accentPink, GlassTheme.accentPurple],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: GlassTheme.accentPink.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: state.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Icon(
                                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 38,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        // 下一首
                        GestureDetector(
                          onTap: () => state.playNext(),
                          child: const Icon(Icons.skip_next_rounded,
                              size: 42, color: Colors.white),
                        ),
                        // 循环
                        GlassButton(
                          icon: state.repeatMode == RepeatMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          size: 48,
                          onTap: () => state.toggleRepeat(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _coverFallback() => Container(
        color: const Color(0xFF2C2C3E),
        child: const Center(
          child: Icon(Icons.music_note, size: 80, color: Colors.white38),
        ),
      );

  Widget _songInfo(String name, String artists, PlayerState state) {
    return Container(
      key: const ValueKey('info'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artists,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lyricView(PlayerState state) {
    final lyrics = state.lyric.split('\n');
    return Container(
      key: const ValueKey('lyric'),
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ListView.builder(
        itemCount: lyrics.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            lyrics[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: i == (state.position ~/ 5)
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
              fontWeight: i == (state.position ~/ 5) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(double sec) {
    final m = (sec / 60).floor();
    final s = (sec % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
