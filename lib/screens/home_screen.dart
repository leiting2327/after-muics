import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import 'playlist_detail_screen.dart';

/// 发现页 - Apple Music 风格
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _dailySongs = [];
  List<Playlist> _playlists = [];
  List<Song> _newSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final player = context.read<PlayerState>();
    try {
      final results = await Future.wait([
        player.netease.dailyRecommend(),
        player.netease.personalizedPlaylist(limit: 12),
        player.netease.newSongs(limit: 10),
      ]);
      setState(() {
        _dailySongs = results[0] as List<Song>;
        _playlists = results[1] as List<Playlist>;
        _newSongs = results[2] as List<Song>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: GlassTheme.accentPink,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              children: [
                // 顶部问候
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('早上好',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('来听点什么吧',
                            style: TextStyle(fontSize: 14, color: Colors.white54)),
                      ],
                    ),
                    GlassButton(
                      icon: Icons.person_outline,
                      size: 44,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 每日推荐 - 大卡片
                if (_dailySongs.isNotEmpty) ...[
                  const Text('每日推荐',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  GlassContainer(
                    onTap: () => context.read<PlayerState>().playQueue(_dailySongs),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [GlassTheme.accentPink, GlassTheme.accentPurple],
                            ),
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_dailySongs.length} 首好歌',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                              Text('根据你的口味精心推荐',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white.withOpacity(0.6))),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // 推荐歌单 - 横向滚动
                const Text('推荐歌单',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _playlists.length,
                    itemBuilder: (context, i) =>
                        _playlistCard(_playlists[i], context),
                  ),
                ),
                const SizedBox(height: 28),

                // 新歌速递
                const Text('新歌速递',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),
                ..._newSongs.take(5).map((song) => TrackTile(
                      song: song,
                      index: 0,
                      onTap: () => context.read<PlayerState>().playQueue(_newSongs, _newSongs.indexOf(song)),
                    )),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playlistCard(Playlist pl, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: pl),
        ),
      ),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: pl.coverURL != null
                  ? Image.network(pl.coverURL!,
                      width: 150, height: 150, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder())
                  : _coverPlaceholder(),
            ),
            const SizedBox(height: 8),
            Text(pl.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        width: 150,
        height: 150,
        color: Colors.grey.shade800,
        child: const Icon(Icons.album, color: Colors.white38, size: 40),
      );
}
