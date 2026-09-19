import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/song.dart';
import '../../utils/crypto.dart';

/// 酷狗音乐 API
class KugouApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://complexsearch.kugou.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
      'Referer': 'https://www.kugou.com/',
    },
    validateStatus: (c) => c! < 500,
  ));

  static const String _mid = '18668100006414287490816036851955828877';
  static const String _dfid = '3ho0WR2Hvmnq0VRb17By0fqd';
  static const String _uuid = '3F0344DDB1B148379A0D875F83A5DD05';

  /// 搜索歌曲
  Future<List<Song>> search(String keyword, {int page = 1, int pagesize = 30}) async {
    final resp = await _dio.get('/v2/search/song', queryParameters: {
      'callback': 'callback',
      'keyword': keyword,
      'page': page,
      'pagesize': pagesize,
      'userid': -1,
      'clientver': 12000,
      'platform': 'WebFilter',
      'tag': 'em',
      'filter': 2,
      'iscorrection': 1,
      'privilege_filter': 0,
      'srcappid': 2919,
    });
    final data = _parse(resp.data);
    final list = data['data']?['lists'] as List? ?? [];
    return list.map((s) => Song.fromKugou(s as Map<String, dynamic>)).toList();
  }

  /// 热搜
  Future<List<String>> hotSearch() async {
    try {
      final resp = await Dio().get(
        'https://searchtip.kugou.com/getSearchTips',
        queryParameters: {
          'count': 20,
          'type': 'hotword',
          'sourcetype': 1,
          'signature': '',
          'format': 'json',
        },
      );
      final data = _parse(resp.data);
      final list = data['data']?['list'] as List? ?? [];
      return list.map((h) => h['keyword'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// 热门歌单
  Future<List<Playlist>> hotPlaylists({int page = 1, int pagesize = 30}) async {
    try {
      final resp = await Dio().get(
        'https://www.kugou.com/yy/special/homepage/getSpecialList',
        queryParameters: {
          'r': 1,
          'sort': 2,
          'page': page,
          'pagesize': pagesize,
          'appid': 1005,
          'clientver': 12000,
        },
      );
      final data = _parse(resp.data);
      final list = data['data'] as List? ?? [];
      return list
          .map((p) => Playlist(
                id: int.tryParse(p['specialid']?.toString() ?? '0') ?? 0,
                name: p['specialname'] as String? ?? '',
                coverURL: p['imgurl'] as String? ?? p['img'] as String?,
                trackCount: p['songcount'] as int? ?? 0,
                source: MusicSource.kugou,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取播放地址（Web 通道，首选）
  Future<String?> songUrl(String hash) async {
    try {
      final resp = await Dio().get(
        'https://wwwapi.kugou.com/yy/index.php',
        queryParameters: {
          'r': 'play/getdata',
          'hash': hash.toUpperCase(),
          'appid': 1014,
          'platid': 4,
          'mid': _mid,
          'dfid': _dfid,
        },
      );
      final data = _parse(resp.data);
      return data['data']?['play_url']?['url'] as String? ??
          data['data']?['play_backup_url'] as String? ??
          data['data']?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 歌词
  Future<String> lyric(String hash) async {
    try {
      final resp = await Dio().get(
        'https://m.kugou.com/app/i/krc.php',
        queryParameters: {
          'cmd': 100,
          'keyword': hash,
          'hash': hash,
          'timelength': 300000,
          'clientver': 1000,
        },
      );
      return resp.data.toString();
    } catch (_) {
      return '';
    }
  }

  /// 榜单歌曲
  Future<List<Song>> rankSongs(String rankid, {int pagesize = 30}) async {
    try {
      final resp = await Dio().get(
        'https://mobiles.kugou.com/api/v3/rank/song',
        queryParameters: {
          'rankid': rankid,
          'page': 1,
          'pagesize': pagesize,
          'plat': 0,
          'appid': 1005,
          'clientver': 12000,
        },
      );
      final data = _parse(resp.data);
      final list = data['data']?['info'] as List? ?? [];
      return list.map((s) => Song.fromKugou(s as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _parse(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    final s = data.toString();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final substr = s.substring(start, end + 1);
      try {
        return jsonDecode(substr) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}
