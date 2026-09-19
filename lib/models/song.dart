enum MusicSource { netease, qq, kugou }

class Song {
  final int id;
  final String name;
  final String artists;
  final String album;
  final String? coverURL;
  final double duration; // 秒
  final MusicSource source;
  final int fee; // 1/4=VIP
  // QQ
  final String? qqMid;
  final String? qqMediaMid;
  // 酷狗
  final String? kugouHash;
  final String? kugouAlbumAudioId;
  final String? kugouAlbumId;
  final Map<String, String>? kugouQualityHashes;

  Song({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    this.coverURL,
    required this.duration,
    required this.source,
    this.fee = 0,
    this.qqMid,
    this.qqMediaMid,
    this.kugouHash,
    this.kugouAlbumAudioId,
    this.kugouAlbumId,
    this.kugouQualityHashes,
  });

  /// 从网易云 JSON 构造
  factory Song.fromNetease(Map<String, dynamic> json) {
    final ar = (json['ar'] as List?) ?? (json['artists'] as List?) ?? [];
    final artists = ar.map((a) => a['name'] as String).join(' / ');
    final al = (json['al'] as Map?) ?? (json['album'] as Map?) ?? {};
    return Song(
      id: json['id'] as int,
      name: json['name'] as String? ?? '未知',
      artists: artists,
      album: al['name'] as String? ?? '',
      coverURL: al['picUrl'] as String?,
      duration: ((json['dt'] as int?) ?? 0) / 1000,
      source: MusicSource.netease,
      fee: json['fee'] as int? ?? 0,
    );
  }

  /// 从 QQ JSON 构造
  factory Song.fromQQ(Map<String, dynamic> json) {
    final singer = (json['singer'] as List?) ?? [];
    final artists = singer.map((s) => s['name'] as String).join(' / ');
    return Song(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? '未知',
      artists: artists,
      album: (json['album'] as List?)?.isNotEmpty == true
          ? json['album'][0]['name'] as String
          : '',
      coverURL: json['albumpic'] as String?,
      duration: ((json['interval'] as int?) ?? 0).toDouble(),
      source: MusicSource.qq,
      qqMid: json['mid'] as String?,
      qqMediaMid: json['media_mid'] as String?,
    );
  }

  /// 从酷狗 JSON 构造
  factory Song.fromKugou(Map<String, dynamic> json) {
    return Song(
      id: json['audio_id'] != null
          ? int.tryParse(json['audio_id'].toString()) ?? 0
          : json['hash'].hashCode,
      name: (json['FileName'] as String? ?? '未知'),
      artists: json['SingerName'] as String? ?? '',
      album: json['AlbumName'] as String? ?? '',
      coverURL: json['AlbumPic'] as String? ?? json['ImgUrl'] as String?,
      duration: ((json['Duration'] as num?) ?? 0).toDouble(),
      source: MusicSource.kugou,
      kugouHash: json['Hash'] as String? ?? json['hash'] as String?,
      kugouAlbumAudioId: json['AlbumID']?.toString(),
    );
  }

  String get sourceName {
    switch (source) {
      case MusicSource.netease:
        return '网易云';
      case MusicSource.qq:
        return 'QQ音乐';
      case MusicSource.kugou:
        return '酷狗';
    }
  }
}

class Playlist {
  final int id;
  final String name;
  final String? coverURL;
  final int trackCount;
  final String? creatorName;
  final MusicSource source;
  final bool isMyLike;

  Playlist({
    required this.id,
    required this.name,
    this.coverURL,
    this.trackCount = 0,
    this.creatorName,
    required this.source,
    this.isMyLike = false,
  });

  factory Playlist.fromNetease(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      coverURL: json['coverImgUrl'] as String? ?? json['picUrl'] as String?,
      trackCount: json['trackCount'] as int? ?? 0,
      creatorName: (json['creator'] as Map?)?['nickname'] as String?,
      source: MusicSource.netease,
      isMyLike: json['specialType'] == 5,
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String? coverURL;
  final MusicSource source;

  Artist({required this.id, required this.name, this.coverURL, required this.source});
}

class SongComment {
  final String content;
  final String nickname;
  final String? avatarURL;
  final int likedCount;
  final String time;
  final bool isHot;

  SongComment({
    required this.content,
    required this.nickname,
    this.avatarURL,
    this.likedCount = 0,
    required this.time,
    this.isHot = false,
  });
}
