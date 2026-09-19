import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../utils/crypto.dart';
import 'api/netease_api.dart';
import 'api/qq_api.dart';
import 'api/kugou_api.dart';

enum RepeatMode { off, all, one }

class PlayerState extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final NeteaseApi _netease = NeteaseApi();
  final QQApi _qq = QQApi();
  final KugouApi _kugou = KugouApi();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _position = 0;
  double _duration = 0;
  RepeatMode _repeatMode = RepeatMode.off;
  String _lyric = '';
  String _translateLyric = '';
  final Set<int> _likedIds = {};

  // Getters
  AudioPlayer get player => _player;
  List<Song> get queue => List.unmodifiable(_queue);
  Song? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get position => _position;
  double get duration => _duration;
  RepeatMode get repeatMode => _repeatMode;
  String get lyric => _lyric;
  String get translateLyric => _translateLyric;
  bool isLiked(int id) => _likedIds.contains(id);
  NeteaseApi get netease => _netease;
  QQApi get qq => _qq;
  KugouApi get kugou => _kugou;

  PlayerState() {
    _init();
  }

  void _init() {
    _player.positionStream.listen((pos) {
      _position = pos.inSeconds.toDouble();
      notifyListeners();
    });
    _player.durationStream.listen((dur) {
      _duration = dur?.inSeconds.toDouble() ?? 0;
      notifyListeners();
    });
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onSongComplete();
      }
      notifyListeners();
    });
  }

  void _onSongComplete() {
    if (_repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (_repeatMode == RepeatMode.all || _currentIndex < _queue.length - 1) {
      playNext();
    }
  }

  /// 播放队列
  Future<void> playQueue(List<Song> songs, [int startIndex = 0]) async {
    _queue = songs;
    _currentIndex = startIndex;
    await _loadCurrent();
  }

  /// 添加到队列
  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  Future<void> _loadCurrent() async {
    if (currentSong == null) return;
    _isLoading = true;
    notifyListeners();

    final song = currentSong!;
    String? url;
    try {
      switch (song.source) {
        case MusicSource.netease:
          url = await _netease.songUrl(song.id);
          final l = await _netease.lyric(song.id);
          _lyric = l['lrc'] ?? '';
          _translateLyric = l['tlyric'] ?? '';
          break;
        case MusicSource.qq:
          if (song.qqMid != null) {
            url = await _qq.songUrl(song.qqMid!);
            _lyric = await _qq.lyric(song.qqMid!);
          }
          break;
        case MusicSource.kugou:
          if (song.kugouHash != null) {
            url = await _kugou.songUrl(song.kugouHash!);
            _lyric = await _kugou.lyric(song.kugouHash!);
          }
          break;
      }
    } catch (e) {
      debugPrint('播放失败: $e');
    }

    if (url != null && url.isNotEmpty) {
      try {
        await _player.setUrl(url);
        _player.play();
      } catch (e) {
        debugPrint('设置音频失败: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await _loadCurrent();
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await _loadCurrent();
  }

  void seek(double seconds) {
    _player.seek(Duration(seconds: seconds.toInt()));
  }

  void toggleRepeat() {
    _repeatMode = RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  Future<void> toggleLike() async {
    if (currentSong == null) return;
    final id = currentSong!.id;
    if (_likedIds.contains(id)) {
      _likedIds.remove(id);
    } else {
      _likedIds.add(id);
      if (currentSong!.source == MusicSource.netease) {
        await _netease.like(id, true);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
