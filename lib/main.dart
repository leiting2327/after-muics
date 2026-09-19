import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/player_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/player_screen.dart';
import 'widgets/mini_player.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerState(),
      child: const BeansMusicApp(),
    ),
  );
}

class BeansMusicApp extends StatelessWidget {
  const BeansMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'After Music',
      debugShowCheckedModeBanner: false,
      theme: GlassTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          // 迷你播放器
          MiniPlayer(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            ),
          ),
          // 底部导航 - 液态玻璃 TabBar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(0, Icons.my_library_music_rounded, '听歌'),
                      _navItem(1, Icons.search_rounded, '搜索'),
                      _navItem(2, Icons.library_music_rounded, '我的'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? GlassTheme.accentPink : Colors.white.withOpacity(0.5),
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? GlassTheme.accentPink : Colors.white.withOpacity(0.5),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}
