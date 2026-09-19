import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/song.dart';
import '../../utils/crypto.dart';

/// 网易云音乐 API
class NeteaseApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://music.163.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://music.163.com',
    },
    validateStatus: (code) => code! < 500,
  ));

  String _csrf = '';
  String _cookie = '';

  void setCookie(String cookie) => _cookie = cookie;
  void setCsrf(String csrf) => _csrf = csrf;

  Options get _weapiOptions => Options(
        method: 'POST',
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Cookie': _cookie},
      );

  /// weapi POST
  Future<Map<String, dynamic>> _weapiPost(String uri, Map<String, dynamic> data) async {
    data['csrf_token'] = _csrf;
    final fields = NetEaseCrypto.weapi(data);
    final resp = await _dio.post('/weapi$uri',
        data: fields, options: _weapiOptions);
    return _parse(resp.data);
  }

  /// eapi POST
  Future<Map<String, dynamic>> _eapiPost(String uri, Map<String, dynamic> data) async {
    data['e_r'] = false;
    data['header'] = {
      'osver': '16.2',
      'deviceId': '0102030405060708',
      'os': 'ios',
      'appver': '9.0.90',
      'versioncode': '5038',
      'mobilename': 'iPhone14,3',
      'buildver': '21F79',
      'resolution': '1179x2556',
      '__csrf': _csrf,
      'channel': 'App Store',
      'requestId': '${DateTime.now().millisecondsSinceEpoch}',
    };
    final params = NetEaseCrypto.eapi(uri, data);
    final resp = await _dio.post('https://interface.music.163.com/eapi$uri',
        data: {'params': params},
        options: Options(
          method: 'POST',
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Cookie': _cookie,
            'User-Agent':
                'NeteaseMusic 9.0.90/5038 (iPhone; iOS 16.2; zh_CN)',
          },
        ));
    return _parse(resp.data);
  }

  Map<String, dynamic> _parse(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    final str = data.toString();
    final start = str.indexOf('{');
    final end = str.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return jsonDecode(str.substring(start, end + 1)) as Map<String, dynamic>;
    }
    return {};
  }

  // ===== 登录 =====
  Future<String> getQrcodeKey() async {
    try {
      final r = await _eapiPost('/api/login/qrcode/unikey', {'type': 3});
      return (r['unikey'] ?? r['data']?['unikey'] ?? '') as String;
    } catch (_) {
      final r = await _weapiPost('/api/login/qrcode/unikey', {'type': 3});
      return (r['unikey'] ?? '') as String;
    }
  }

  String qrcodeUrl(String key) => 'https://music.163.com/login?codekey=$key';

  /// 800=待扫 801=待确认 802=待授权 803=成功
  Future<int> qrcodeStatus(String key) async {
    try {
      final r = await _eapiPost('/api/login/qrcode/client/login', {'key': key, 'type': 3});
      return (r['code'] as int?) ?? 800;
    } catch (_) {
      final r = await _weapiPost('/api/login/qrcode/client/login', {'key': key, 'type': 3});
      return (r['code'] as int?) ?? 800;
    }
  }

  Future<Map<String, dynamic>> accountInfo() async =>
      _weapiPost('/api/w/nuser/account/get', {});

  // ===== 音乐库 =====
  Future<List<Playlist>> userPlaylists(int uid) async {
    final r = await _weapiPost('/api/user/playlist',
        {'uid': uid, 'limit': 1000, 'offset': 0, 'includeVideo': true});
    final list = (r['playlist'] as List?) ?? [];
    return list.map((p) => Playlist.fromNetease(p as Map<String, dynamic>)).toList();
  }

  Future<List<Song>> playlistDetail(int id) async {
    final r = await _eapiPost('/api/v6/playlist/detail', {'id': id, 'n': 100000, 's': 8});
    final tracks = (r['playlist']?['tracks'] as List?) ?? [];
    return tracks.map((t) => Song.fromNetease(t as Map<String, dynamic>)).toList();
  }

  Future<String?> songUrl(int id, {String level = 'hires'}) async {
    final r = await _eapiPost('/api/song/enhance/player/url/v1', {
      'ids': '[$id]',
      'level': level,
      'encodeType': 'flac',
    });
    final data = (r['data'] as List?) ?? [];
    if (data.isEmpty) return null;
    return data[0]['url'] as String?;
  }

  Future<Map<String, String>> lyric(int id) async {
    final r = await _weapiPost('/api/song/lyric', {'id': id, 'lv': -1, 'kv': -1, 'tv': -1});
    return {
      'lrc': r['lrc']?['lyric'] as String? ?? '',
      'tlyric': r['tlyric']?['lyric'] as String? ?? '',
    };
  }

  Future<List<Song>> search(String keyword, {int limit = 30, int offset = 0}) async {
    final r = await _weapiPost('/api/cloudsearch/pc',
        {'s': keyword, 'type': 1, 'limit': limit, 'offset': offset, 'total': true});
    final songs = (r['result']?['songs'] as List?) ?? [];
    return songs.map((s) => Song.fromNetease(s as Map<String, dynamic>)).toList();
  }

  Future<List<String>> hotSearch() async {
    final r = await _weapiPost('/api/search/hot', {'type': 1111});
    final hots = (r['result']?['hots'] as List?) ?? [];
    return hots.map((h) => h['first'] as String).toList();
  }

  Future<List<Song>> dailyRecommend() async {
    try {
      final r = await _weapiPost('/api/v3/discovery/recommend/songs', {});
      final songs = (r['data']?['dailySongs'] as List?) ?? [];
      return songs.map((s) => Song.fromNetease(s as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Playlist>> personalizedPlaylist({int limit = 30}) async {
    final r = await _weapiPost('/api/personalized/playlist', {'limit': limit, 'n': limit});
    final list = (r['result'] as List?) ?? [];
    return list
        .map((p) => Playlist(
              id: p['id'] as int,
              name: p['name'] as String? ?? '',
              coverURL: p['picUrl'] as String?,
              trackCount: p['trackCount'] as int? ?? 0,
              source: MusicSource.netease,
            ))
        .toList();
  }

  Future<List<Song>> newSongs({int limit = 20}) async {
    final r = await _weapiPost('/api/personalized/newsong', {'type': 0, 'limit': limit});
    final list = (r['result'] as List?) ?? [];
    return list.map((s) {
      final song = s['song'] as Map<String, dynamic>? ?? s;
      return Song.fromNetease(song);
    }).toList();
  }

  Future<List<Playlist>> topPlaylists({int limit = 30}) async {
    final r = await _weapiPost(
        '/api/top/playlist', {'limit': limit, 'order': 'hot', 'cat': '全部', 'total': true});
    final list = (r['playlists'] as List?) ?? [];
    return list.map((p) => Playlist.fromNetease(p as Map<String, dynamic>)).toList();
  }

  Future<List<Song>> similarSongs(int songId) async {
    final r = await _weapiPost('/api/simi/song', {'songid': songId});
    final list = (r['songs'] as List?) ?? [];
    return list.map((s) => Song.fromNetease(s as Map<String, dynamic>)).toList();
  }

  Future<bool> like(int songId, bool like) async {
    try {
      final r = await _weapiPost('/api/song/like?t=${like ? 1 : 0}',
          {'trackId': songId, 'like': like});
      return (r['code'] as int?) == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<SongComment>> comments(int songId, {int limit = 20}) async {
    final r = await _weapiPost('/api/v1/resource/comments/R_SO_4_$songId',
        {'rid': songId, 'limit': limit, 'offset': 0, 'beforeTime': 0});
    final hot = (r['hotComments'] as List?) ?? [];
    final normal = (r['comments'] as List?) ?? [];
    final all = [...hot, ...normal];
    return all
        .map((c) => SongComment(
              content: c['content'] as String? ?? '',
              nickname: (c['user'] as Map?)?['nickname'] as String? ?? '',
              avatarURL: (c['user'] as Map?)?['avatarUrl'] as String?,
              likedCount: c['likedCount'] as int? ?? 0,
              time: DateTime.fromMillisecondsSinceEpoch(c['time'] as int? ?? 0)
                  .toString()
                  .substring(0, 16),
              isHot: hot.contains(c),
            ))
        .toList();
  }
}
