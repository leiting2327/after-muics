import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Song> _results = [];
  List<String> _hotWords = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadHot();
  }

  Future<void> _loadHot() async {
    final player = context.read<PlayerState>();
    final words = await Future.wait([
      player.netease.hotSearch(),
      player.qq.hotSearch(),
      player.kugou.hotSearch(),
    ]);
    setState(() => _hotWords = words.expand((w) => w).toSet().toList()..take(15).toList());
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _searched = true;
    });
    final player = context.read<PlayerState>();
    try {
      final results = await Future.wait([
        player.netease.search(keyword, limit: 20),
        player.qq.search(keyword, num: 15),
        player.kugou.search(keyword, pagesize: 15),
      ]);
      setState(() {
        _results = [...results[0], ...results[1], ...results[2]];
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: '搜索歌曲、歌手、专辑',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _search,
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _search(_controller.text),
                        child: const Text('搜索',
                            style: TextStyle(
                                color: GlassTheme.accentPink, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: !_searched
                    ? _hotView()
                    : _searching
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 140),
                            itemCount: _results.length,
                            itemBuilder: (context, i) => TrackTile(
                              song: _results[i],
                              index: i,
                              onTap: () => context
                                  .read<PlayerState>()
                                  .playQueue(_results, i),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hotView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('热门搜索',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _hotWords.map((w) {
            return GestureDetector(
              onTap: () {
                _controller.text = w;
                _search(w);
              },
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 20,
                child: Text(w,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
