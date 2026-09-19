import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/song.dart';
import '../../utils/crypto.dart';

/// QQ 音乐 API
class QQApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://u.y.qq.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://y.qq.com/',
    },
    validateStatus: (c) => c! < 500,
  ));

  String _uin = '0';
  String _gTk = '5381';
  String _loginKey = '';
  String _guid = '';

  void setUin(String uin) {
    _uin = uin;
    _gTk = QQHash.hash5381(_loginKey).toString();
  }

  void setLoginKey(String key) {
    _loginKey = key;
    _gTk = QQHash.hash5381(key).toString();
  }

  void setGuid(String guid) => _guid = guid;

  /// musicu.fcg 统一请求
  Future<Map<String, dynamic>> _musicu(Map<String, dynamic> req) async {
    final body = {
      'comm': {'g_tk': int.parse(_gTk), 'platform': 'yqq', 'ct': 24, 'cv': 0, 'uin': _uin},
      ...req,
    };
    final resp = await _dio.post('/cgi-bin/musicu.fcg',
        data: jsonEncode(body),
        options: Options(contentType: Headers.jsonContentType));
    return _parse(resp.data);
  }

  Map<String, dynamic> _parse(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    final s = data.toString();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return jsonDecode(s.substring(start, end + 1)) as Map<String, dynamic>;
    }
    return {};
  }

  /// 搜索歌曲
  Future<List<Song>> search(String keyword, {int page = 1, int num = 30}) async {
    final r = await _musicu({
      'req_1': {
        'module': 'music.search.SearchCgiService',
        'method': 'DoSearchForQQMusicDesktop',
        'param': {
          'query': keyword,
          'num_per_page': num,
          'page_num': page,
          'search_type': 0,
          'grp': 1,
        },
      },
    });
    final list = r['req_1']?['data']?['body']?['song']?['list'] as List? ?? [];
    return list.map((s) => Song.fromQQ(s as Map<String, dynamic>)).toList();
  }

  /// 热搜
  Future<List<String>> hotSearch() async {
    try {
      final resp = await Dio().get(
        'https://c.y.qq.com/splcloud/fcgi-bin/gethotkey.fcg',
        queryParameters: {
          'format': 'json',
          'inCharset': 'utf8',
          'outCharset': 'utf-8',
        },
        options: Options(headers: {'Referer': 'https://y.qq.com/'}),
      );
      final data = _parse(resp.data);
      final list = data['data']?['hotkey'] as List? ?? [];
      return list.map((h) => h['k'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// 榜单列表
  Future<List<Map<String, dynamic>>> topLists() async {
    try {
      final resp = await Dio().get(
        'https://c.y.qq.com/v8/fcg-bin/fcg_myqq_toplist.fcg',
        queryParameters: {'format': 'json'},
        options: Options(headers: {'Referer': 'https://y.qq.com/'}),
      );
      final data = _parse(resp.data);
      final list = data['data']?['topList'] as List? ?? [];
      return list
          .where((t) =>
              ![201, 75].contains(t['id']) &&
              !(t['topTitle']?.toString().contains('MV') ?? false))
          .map((t) => {
                'id': t['topId'],
                'name': t['topTitle'],
                'cover': t['picUrl'],
              })
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// 获取播放地址
  Future<String?> songUrl(String songmid, {String quality = 'M800'}) async {
    if (_guid.isEmpty) return null;
    final filename = '$quality${songmid}${songmid}.mp3';
    final r = await _musicu({
      'req_0': {
        'module': 'vkey.GetVkeyServer',
        'method': 'CgiGetVkey',
        'param': {
          'filename': [filename],
          'guid': _guid,
          'songmid': [songmid],
          'songtype': [0],
          'uin': _uin,
          'loginflag': _uin == '0' ? 0 : 1,
          'platform': '20',
        },
      },
    });
    final info = r['req_0']?['data']?['midurlinfo'] as List? ?? [];
    if (info.isEmpty) return null;
    final purl = info[0]['purl'] as String?;
    if (purl == null || purl.isEmpty) return null;
    final sip = r['req_0']?['data']?['sip'] as List? ?? [];
    if (sip.isEmpty) return null;
    return '${sip[0]}$purl';
  }

  /// 歌词
  Future<String> lyric(String songmid) async {
    try {
      final resp = await Dio().get(
        'https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
        queryParameters: {
          'songmid': songmid,
          'format': 'json',
          'nobase64': 1,
          'g_tk': _gTk,
        },
        options: Options(headers: {'Referer': 'https://y.qq.com/'}),
      );
      final data = _parse(resp.data);
      return data['lyric'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
