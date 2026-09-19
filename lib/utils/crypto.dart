import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// 网易云音乐 weapi / eapi 加密工具
class NetEaseCrypto {
  static const String _weapiKey = '0CoJUm6Qyw8W8jud';
  static const String _weapiIv = '0102030405060708';
  static const String _eapiKey = 'e82ckenh8dichen8';

  /// weapi RSA 公钥（hex 模数）
  static const String _rsaModulus =
      '00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b7251'
      '52b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecb'
      'd9a567c4ce49fd4f50b6973da8483935c03e9a7ce141ef18f52fe588b79b7bc90'
      '5a066a8944a3ea1f1e603216fef3f3e563fb0a702555a15fff8cfc337ade33249'
      '6e8a2cf144090b089e6bc2e2afd281cc087fea2a5f5e124c1198016fe2cf0b059'
      '4887c61a53dcb312cefadaaca8ceb01f0afe1fe593cefde7e0ce5c5cd4dc5e393'
      '0d237b8a1d4f802d34d62e05cad13b67ca9d332964af4f581083936db1ebce5b3'
      '443fe7c87b2b84a014b37f1a2b3d4e5f607b2d6e8f9a0b1c2d3e4f5061728394'
      'a5b6c7d8e9f0a1b2c3d4e5f60718293a4b5c6d7e8f9012233445566778899aabb'
      'ccddeeff00112233445566778899aabbccddeeff00112233445566778899aab';

  static const int _rsaExponent = 65537;

  /// AES-CBC PKCS5/PKCS7 加密 -> Base64
  static String _aesCbcEncrypt(String plain, String key, String iv) {
    final keyBytes = utf8.encode(key);
    final ivBytes = utf8.encode(iv);
    final padded = _pad(utf8.encode(plain), 16);
    final cbc = CBCBlockCipher(AESFastEngine())
      ..init(true, ParametersWithIV(KeyParameter(keyBytes), ivBytes));
    final out = Uint8List(padded.length);
    var offset = 0;
    while (offset < padded.length) {
      offset += cbc.processBlock(padded, offset, out, offset);
    }
    return base64Encode(out);
  }

  /// AES-ECB PKCS7 加密 -> hex
  static String _aesEcbEncrypt(String plain, String key) {
    final keyBytes = utf8.encode(key);
    final padded = _pad(utf8.encode(plain), 16);
    final ecb = ECBBlockCipher(AESFastEngine())
      ..init(true, KeyParameter(keyBytes));
    final out = Uint8List(padded.length);
    var offset = 0;
    while (offset < padded.length) {
      offset += ecb.processBlock(padded, offset, out, offset);
    }
    return _bytesToHex(out);
  }

  static Uint8List _pad(List<int> data, int blockSize) {
    final padLen = blockSize - (data.length % blockSize);
    final out = List<int>.from(data);
    out.addAll(List.filled(padLen, padLen));
    return Uint8List.fromList(out);
  }

  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexToBytes(String hex) {
    return Uint8List.fromList(List.generate(
        hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  /// RSA RAW 加密：m^e mod n -> 128 字节
  static String _rsaEncrypt(String secretKeyReversed) {
    final n = BigInt.parse(_rsaModulus, radix: 16);
    final e = BigInt.from(_rsaExponent);
    // secretKey 反转后作为明文
    final mBytes = utf8.encode(secretKeyReversed);
    // 转成大端整数
    final m = _bytesToBigInt(Uint8List.fromList(mBytes));
    final cipher = m.modPow(e, n);
    // 转成 128 字节
    final cipherBytes = _bigIntToBytes(cipher, 128);
    return _bytesToHex(cipherBytes);
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  static Uint8List _bigIntToBytes(BigInt number, int length) {
    final bytes = Uint8List(length);
    var n = number;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (n & BigInt.from(0xff)).toInt();
      n = n >> 8;
    }
    return bytes;
  }

  /// 生成 weapi 表单字段
  /// 返回 {params, encSecKey}
  static Map<String, String> weapi(Map<String, dynamic> data) {
    final text = jsonEncode(data);
    // 第一次 AES-CBC
    final enc1 = _aesCbcEncrypt(text, _weapiKey, _weapiIv);
    // 随机 16 位 secretKey
    final secretKey = _randomKey(16);
    // 第二次 AES-CBC
    final params = _aesCbcEncrypt(enc1, secretKey, _weapiIv);
    // secretKey 反转后 RSA
    final encSecKey = _rsaEncrypt(secretKey.split('').reversed.join());
    return {'params': params, 'encSecKey': encSecKey};
  }

  /// 生成 eapi 表单字段
  static String eapi(String path, Map<String, dynamic> data) {
    final text = jsonEncode(data);
    final md5Str = md5.convert(utf8.encode('nobody$path"use$text"md5forencrypt')).toString();
    final dataStr = '$path-36cd479b6b5-$text-36cd479b6b5-$md5Str';
    return _aesEcbEncrypt(dataStr, _eapiKey);
  }

  static String _randomKey(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    return List.generate(len, (i) => chars[(rnd + i * 7) % chars.length]).join();
  }
}

/// QQ 音乐 hash 工具
class QQHash {
  /// hash33 - 用于 ptqrtoken
  static int hash33(String s) {
    var e = 0;
    for (var i = 0; i < s.length; i++) {
      e += (e << 5) + s.codeUnitAt(i);
    }
    return e & 0x7FFFFFFF;
  }

  /// hash5381 - 用于 g_tk
  static int hash5381(String s) {
    var e = 5381;
    for (var i = 0; i < s.length; i++) {
      e += (e << 5) + s.codeUnitAt(i);
    }
    return e & 0x7FFFFFFF;
  }
}

/// 酷狗音乐签名工具
class KugouSign {
  static const String androidSignKey = 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA';
  static const String webSignKey = 'NVPh5oo715z5DIWAeQlhMDsWXXQV4hwt';
  static const String upstreamSignSalt = 'OIlwieks28dk2k092lksi2UIkp';

  /// android 签名: md5("{key}{body}{data}{key}")
  static String androidSignature(String body, String data) {
    final raw = '$androidSignKey$body$data$androidSignKey';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// upstream 签名: md5("{salt}{body}{data}")
  static String upstreamSignature(String body, String data) {
    final raw = '$upstreamSignSalt$body$data';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// web 签名: md5("{key}{body}")
  static String webSignature(String body) {
    final raw = '$webSignKey$body';
    return md5.convert(utf8.encode(raw)).toString();
  }
}
