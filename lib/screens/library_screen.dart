import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import 'login_screen.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Playlist> _playlists = [];
  bool _loggedIn = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final player = context.read<PlayerState>();
    try {
      final info = await player.netease.accountInfo();
      if (info['profile'] != null) {
        final uid = info['profile']['userId'] as int;
        final pls = await player.netease.userPlaylists(uid);
        setState(() {
          _playlists = pls;
          _loggedIn = true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: !_loggedIn
              ? _loginPrompt()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  children: [
                    const Text('我的音乐',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 20),
                    ..._playlists.map((pl) => GlassContainer(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(playlist: pl)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: pl.coverURL != null
                                    ? Image.network(pl.coverURL!,
                                        width: 56, height: 56, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _iconBox())
                                    : _iconBox(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pl.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 15)),
                                    Text('${pl.trackCount} 首',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white54)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white38),
                            ],
                          ),
                        )),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade800,
        child: const Icon(Icons.queue_music, color: Colors.white38),
      );

  Widget _loginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [GlassTheme.accentPurple, GlassTheme.accentBlue],
              ),
            ),
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('登录后同步你的歌单',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text('扫码登录网易云 / QQ / 酷狗',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 28),
          GlassButton(
            icon: Icons.qr_code_scanner,
            size: 56,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ).then((_) => _load()),
          ),
          const SizedBox(height: 12),
          const Text('扫码登录', style: TextStyle(fontSize: 13, color: Colors.white54)),
        ],
      ),
    );
  }
}
