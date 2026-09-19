# Beans Music Glass 🌊🎵

**液态玻璃音乐播放器 · Apple Music 同款 · 三平台音源（网易云 / QQ音乐 / 酷狗）**

基于 Flutter 构建，一套代码编译 iOS / Android / Windows。采用 iOS 26 Liquid Glass 设计语言，BackdropFilter 实时毛玻璃 + 渐变高光 + 浮动光斑背景。

---

## ✨ 功能清单

| 模块 | 功能 |
|---|---|
| 🎨 **UI** | 液态玻璃效果、Apple Music 同款播放器、毛玻璃导航栏、渐变光斑背景、圆角卡片 |
| 🔐 **登录** | 网易云扫码登录（完整 weapi/eapi 加密）、QQ/酷狗扫码登录入口 |
| 🔍 **搜索** | 三平台同时搜索、热搜词聚合、歌词同步 |
| 🏠 **发现** | 每日推荐、推荐歌单、新歌速递、热门歌单、私人 FM |
| 📚 **歌单** | 用户歌单、歌单详情、播放全部、创建/添加/删除（网易云） |
| ▶️ **播放** | 三平台音源切换、音质选择（standard→hires→master）、歌词滚动、喜欢/收藏、循环模式 |
| 💬 **评论** | 热门评论、评论列表 |
| 🎵 **音质** | 网易云 hires / QQ M800 / 酷狗 flac24bit·atmos·master |

---

## 🚀 快速开始：上传 GitHub 构建

### 1. 把项目推到 GitHub

```bash
cd beans_music_glass
git init
git add .
git commit -m "Beans Music Glass - Liquid Glass Music Player"
git branch -M main
git remote add origin https://github.com/你的用户名/beans-music-glass.git
git push -u origin main
```

### 2. 构建 Android APK（无需额外配置）

进入 GitHub 仓库 → **Actions** → 左侧选 **Build Android APK** → 点 **Run workflow**。
构建完成后在 Artifacts 里下载 `app-arm64-v8a-release.apk`，直接安装到安卓手机。

### 3. 构建 iOS IPA（需要你的证书）

你有证书，按以下步骤配 GitHub Secrets：

#### 准备材料
1. **iOS 分发证书**（.p12 文件）：在 Keychain Access 导出，设一个密码
2. **Provisioning Profile**（.mobileprovision 文件）：在 Apple Developer 后台生成
3. **ExportOptions.plist**：导出时用的配置

#### 在 GitHub 仓库配置 Secrets
进入仓库 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**，添加：

| Secret 名称 | 值 |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | 把 .p12 文件转成 base64：`base64 -i cert.p12 \| pbcopy`（Mac） |
| `P12_PASSWORD` | 导出 p12 时设的密码 |
| `KEYCHAIN_PASSWORD` | 任意一串密码（CI 钥匙串用） |
| `PROVISIONING_PROFILE_BASE64` | .mobileprovision 转 base64：`base64 -i profile.mobileprovision \| pbcopy` |
| `APPLE_TEAM_ID` | 你的苹果开发者 Team ID（10 位） |
| `EXPORT_OPTIONS_PLIST` | 完整的 ExportOptions.plist XML 内容 |

#### 触发构建
进入 Actions → **Build iOS IPA** → **Run workflow**。
完成后下载 `app-release-ipa.ipa`，用你自己的证书签好后即可安装。

> **提示**：如果是开发调试（自己手机装），可以用 Ad Hoc 或 Development provisioning profile；要发布到 TestFlight 用 App Store 类型。

### 4. 打 Windows EXE

在本地装好 Flutter 后：
```bash
flutter config --enable-windows-desktop
flutter build windows --release
```
产物在 `build/windows/x64/runner/Release/`，整个文件夹拷走就是绿色版，用 Inno Setup 打成单 exe 安装包。

---

## 🧱 技术架构

```
lib/
├── main.dart                    # 入口 + 底部导航
├── theme/app_theme.dart         # 液态玻璃主题 + GlassContainer 组件
├── models/song.dart             # Song / Playlist / Artist / Comment 模型
├── utils/crypto.dart            # 加密层
│   ├── NetEaseCrypto (weapi AES-CBC+RSA / eapi AES-ECB)
│   ├── QQHash (hash33 / hash5381)
│   └── KugouSign (MD5 三套签名)
├── services/
│   ├── player_state.dart        # 全局播放状态（Provider）
│   └── api/
│       ├── netease_api.dart     # 网易云 30+ 接口
│       ├── qq_api.dart          # QQ 音乐 musicu.fcg + 老接口
│       └── kugou_api.dart       # 酷狗签名接口 + 公开接口
├── widgets/
│   └── mini_player.dart         # 迷你播放器 + 歌曲列表项
└── screens/
    ├── home_screen.dart         # 发现页
    ├── search_screen.dart       # 搜索页
    ├── library_screen.dart      # 我的音乐
    ├── player_screen.dart       # 全屏播放器（Apple Music 同款）
    ├── login_screen.dart        # 扫码登录
    └── playlist_detail_screen.dart # 歌单详情
```

---

## 🎨 液态玻璃实现

```dart
// 核心：BackdropFilter + ImageFilter.blur + 渐变高光
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)],
        ),
      ),
    ),
  ),
)
```

所有面板、按钮、导航、卡片都用这个模式，配合背景漂浮光斑，就是 Apple Intelligence 同款液态玻璃。

---

## ⚠️ 注意事项

1. **API 版权**：本项目仅供学习交流，音源接口版权归网易云/QQ/酷狗所有，请勿用于商业用途
2. **VIP 歌曲**：未登录或非会员只能试听，登录自己的账号后可听你有权限的歌曲
3. **首次运行**：部分接口可能需要 1-2 秒加载，请耐心等待
4. **Windows 端**：桌面端需要 Flutter Windows 开发环境，不能在 GitHub Actions 直接构建（需要 Windows runner）

---

## 📄 License

MIT
