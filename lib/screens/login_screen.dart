import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTab = 0; // 0=网易云 1=QQ 2=酷狗
  String? _qrUrl;
  String? _qrKey;
  Timer? _pollTimer;
  String _status = '准备中...';
  bool _loggingIn = false;

  final List<String> _platforms = ['网易云音乐', 'QQ 音乐', '酷狗音乐'];

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLogin() async {
    setState(() {
      _loggingIn = true;
      _status = '获取二维码...';
      _qrUrl = null;
      _qrKey = null;
    });

    final player = context.read<PlayerState>();
    try {
      switch (_selectedTab) {
        case 0:
          final key = await player.netease.getQrcodeKey();
          setState(() {
            _qrKey = key;
            _qrUrl = player.netease.qrcodeUrl(key);
            _status = '请用网易云音乐 App 扫码';
          });
          _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollNetEase());
          break;
        case 1:
          setState(() {
            _status = 'QQ 音乐扫码登录\n（请在 QQ 音乐手机端扫码）';
            _loggingIn = false;
          });
          break;
        case 2:
          setState(() {
            _status = '酷狗扫码登录\n（请在酷狗音乐手机端扫码）';
            _loggingIn = false;
          });
          break;
      }
    } catch (e) {
      setState(() => _status = '登录失败: $e');
      _loggingIn = false;
    }
  }

  Future<void> _pollNetEase() async {
    if (_qrKey == null || !mounted) return;
    final player = context.read<PlayerState>();
    final code = await player.netease.qrcodeStatus(_qrKey!);
    String msg;
    switch (code) {
      case 800:
        msg = '等待扫码...';
        break;
      case 801:
        msg = '已扫码，请在手机上确认';
        break;
      case 802:
        msg = '正在授权...';
        break;
      case 803:
        msg = '登录成功！';
        _pollTimer?.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
        return;
      case 800:
      default:
        msg = '二维码已过期，请刷新';
        _pollTimer?.cancel();
        break;
    }
    setState(() => _status = msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text('登录',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 30),

                // 平台选择
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_platforms.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedTab = i;
                        _qrUrl = null;
                        _status = '';
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == i
                              ? GlassTheme.accentPink.withOpacity(0.3)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedTab == i
                                ? GlassTheme.accentPink
                                : Colors.white24,
                          ),
                        ),
                        child: Text(_platforms[i],
                            style: TextStyle(
                                color: _selectedTab == i
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),

                // 二维码区域
                if (_qrUrl != null) ...[
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              _qrUrl!,
                              style: const TextStyle(fontSize: 8, color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('扫描二维码登录',
                            style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: const Icon(Icons.qr_code_2,
                        size: 80, color: Colors.white24),
                  ),
                ],
                const SizedBox(height: 24),
                Text(_status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const Spacer(),

                // 开始登录按钮
                GlassContainer(
                  onTap: _loggingIn ? null : _startLogin,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: 30,
                  child: Center(
                    child: _loggingIn
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('获取登录二维码',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
