import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_1/utils/logger.dart'; // 確保你有這個檔案，或改回 print
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyMusicPlayer());
}

class MyMusicPlayer extends StatefulWidget {
  const MyMusicPlayer({super.key});

  @override
  State<MyMusicPlayer> createState() => _MyMusicPlayerState();
}

class _MyMusicPlayerState extends State<MyMusicPlayer> {
  // T2-1: 主題控制
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POCO Player',
      // 定義淺色主題
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      // 定義深色主題
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: MusicPlayerHome(
        onThemeToggle: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MusicPlayerHome extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  const MusicPlayerHome({
    super.key,
    required this.onThemeToggle,
    required this.currentThemeMode,
  });

  @override
  State<MusicPlayerHome> createState() => _MusicPlayerHomeState();
}

class _MusicPlayerHomeState extends State<MusicPlayerHome> {
  // --- 變數定義 ---
  List<String> _musicFiles = []; // 原始清單
  List<String> _filteredFiles = []; // 搜尋過濾後的清單
  String? _currentSong; // 當前選中歌曲

  bool _isSearching = false; // T2-2: 是否處於搜尋模式
  final TextEditingController _searchController = TextEditingController();

  final AudioPlayer _audioPlayer = AudioPlayer(); // 建立播放器
  PlayerState _playerState = PlayerState.stopped; // 追蹤播放狀態 (播放中/暫停/停止)

  @override
  void initState() {
    super.initState();
    _initAndScan();
    // 監聽搜尋輸入
    _searchController.addListener(() {
      _filterMusic(_searchController.text);
    });
  }

  // --- 權限與掃描邏輯 (T1) ---
  Future<void> _initAndScan() async {
    if (await Permission.audio.request().isGranted) {
      _scanMusic();
    } else {
      Log.e("權限被拒絕");
    }
  }

  void _scanMusic() {
    // 針對實機測試的路徑
    final dir = Directory('/storage/emulated/0/Download');
    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .where((file) => file.path.toLowerCase().endsWith('.mp3'))
          .map((file) => file.path.split('/').last)
          .toList();

      setState(() {
        _musicFiles = files;
        _filteredFiles = files; // 初始化時，過濾清單等於原始清單
      });
      Log.i("掃描完成，找到 ${files.length} 首歌");
      // 在掃描結束後加入這段：
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("已重新掃描資料夾，找到 ${files.length} 首歌曲"),
          duration: const Duration(seconds: 1), // 顯示 1 秒就好
        ),
      );
    } else {
      Log.e("找不到路徑: ${dir.path}");
    }
  }

  // --- 搜尋過濾邏輯 (T2-2) ---
  void _filterMusic(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _musicFiles;
      } else {
        _filteredFiles = _musicFiles
            .where((song) => song.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        // T2-2: 切換標題或搜尋框
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜尋音樂...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Sixer MP3Player'),
        actions: [
          // 搜尋按鈕
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          // 主題按鈕 (T2-1)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _scanMusic),
        ],
      ),
      body: Column(
        children: [
          // 路徑提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: isDark ? Colors.black26 : Colors.grey[200],
            child: Text(
              "路徑: /Download  (${_filteredFiles.length} 首)",
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // 歌曲清單
          Expanded(
            child: _filteredFiles.isEmpty
                ? const Center(child: Text("找不到歌曲"))
                : ListView.builder(
                    itemCount: _filteredFiles.length,
                    itemBuilder: (context, index) {
                      final song = _filteredFiles[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(song),
                        selected: _currentSong == song,
                        // 修改 ListTile 的 onTap
                        onTap: () async {
                          setState(() => _currentSong = song);
                          Log.i("準備播放: $song");

                          // 1. 取得完整路徑 (注意：實機路徑需要加上 Device Path)
                          String filePath =
                              '/storage/emulated/0/Download/$song';

                          // 2. 播放
                          await _audioPlayer.play(DeviceFileSource(filePath));

                          setState(() {
                            _playerState = PlayerState.playing;
                          });
                        },
                        // onTap: () {
                        //   setState(() => _currentSong = song);
                        //   Log.i("選擇歌曲: $song");
                        // },
                      );
                    },
                  ),
          ),
          // 底部控制區
          // PlayerSection(currentSongName: _currentSong),
          PlayerSection(
            currentSongName: _currentSong,
            player: _audioPlayer, // 傳入播放器實例
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose(); // 釋放播放器
    super.dispose();
  }
}

// --- 底部播放器組件 ---
class PlayerSection extends StatefulWidget {
  final String? currentSongName;
  final AudioPlayer player;

  const PlayerSection({super.key, this.currentSongName, required this.player});

  @override
  State<PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<PlayerSection> {
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero; // 歌曲總長
  Duration _position = Duration.zero; // 當前播放位置

  @override
  void initState() {
    super.initState();
    // 監聽播放器的狀態變化（例如：手動暫停或播放結束）
    widget.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    // 2. 監聽歌曲總長度
    widget.player.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    // 3. 監聽當前播放位置
    widget.player.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
    // 當歌曲完整播放結束時觸發
    widget.player.onPlayerComplete.listen((event) {
      Log.i("歌曲播放完畢！");
      // 這裡可以呼叫「下一首」的邏輯
      // _playNextSong();
    });
  }

  // 將 Duration 轉為 00:00 格式的輔助函式
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // 處理播放/暫停按鈕點擊
  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await widget.player.pause();
    } else if (_playerState == PlayerState.paused ||
        _playerState == PlayerState.completed ||
        _playerState == PlayerState.stopped) {
      // 如果有選中歌曲且目前是暫停狀態，就繼續播放
      if (widget.currentSongName != null) {
        await widget.player.resume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.currentSongName ?? "未選擇歌曲",
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // --- 進度條區塊 ---
          Slider(
            min: 0,
            max: _duration.inMilliseconds.toDouble(),
            // 使用 clamp 確保數值永遠在 0.0 到總長度之間
            value: _position.inMilliseconds.toDouble().clamp(
              0.0,
              _duration.inMilliseconds.toDouble(),
            ),
            onChanged: (value) async {
              final position = Duration(milliseconds: value.toInt());
              await widget.player.seek(position);
            },
          ),

          // 顯示時間文字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(
                    _position > _duration ? _duration : _position,
                  ),
                ), // 當前時間
                Text(_formatDuration(_duration)), // 總時間
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () {},
              ),
              IconButton(
                iconSize: 48,
                // 根據狀態切換圖示
                icon: Icon(
                  _playerState == PlayerState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                onPressed: widget.currentSongName == null
                    ? null
                    : _togglePlayPause,
              ),
              IconButton(icon: const Icon(Icons.skip_next), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
