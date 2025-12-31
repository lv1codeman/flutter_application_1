import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_1/utils/logger.dart'; // 維持你的 Log 路徑

void main() {
  runApp(const MyMusicPlayer());
}

class MyMusicPlayer extends StatelessWidget {
  const MyMusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
      home: const MusicPlayerHome(),
    );
  }
}

class MusicPlayerHome extends StatefulWidget {
  const MusicPlayerHome({super.key});

  @override
  State<MusicPlayerHome> createState() => _MusicPlayerHomeState();
}

class _MusicPlayerHomeState extends State<MusicPlayerHome> {
  List<String> _musicFiles = []; // 存放真實歌曲檔名
  String _currentSong = "未選擇歌曲"; // 當前選中的歌曲

  @override
  void initState() {
    super.initState();
    _initAndScan(); // 啟動時自動檢查權限並掃描
  }

  // 初始化：請求權限
  Future<void> _initAndScan() async {
    Log.i("正在初始化 POCO F8 Ultra 掃描器...");

    // Android 13+ 使用 Permission.audio
    if (await Permission.audio.request().isGranted) {
      _scanMusic();
    } else {
      Log.e("權限被拒絕，無法讀取音樂檔案");
      // 權限沒過時，給幾首假資料讓你測試 UI
      setState(() {
        _musicFiles = ["(假) 測試歌曲_01.mp3", "(假) 測試歌曲_02.mp3"];
      });
    }
  }

  // 核心邏輯：掃描實體檔案
  void _scanMusic() {
    // 定義幾種可能的路徑
    List<String> pathsToTest = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/Music',
    ];

    String? validPath;
    List<String> foundFiles = [];

    for (String path in pathsToTest) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        Log.i("🔍 發現有效路徑: $path");
        validPath = path;

        // 掃描該路徑下的 mp3
        final files = dir
            .listSync()
            .where((file) => file.path.toLowerCase().endsWith('.mp3'))
            .map((file) => file.path.split('/').last)
            .toList();

        if (files.isNotEmpty) {
          foundFiles = files;
          break; // 找到有歌的路徑就停下來
        }
      } else {
        Log.d("🚫 路徑不存在: $path");
      }
    }

    if (validPath != null) {
      setState(() {
        _musicFiles = foundFiles;
      });
      Log.i("✅ 掃描完成。在 $validPath 找到 ${foundFiles.length} 首歌");
    } else {
      Log.e("❌ 測試了所有路徑都找不到資料夾，請確認模擬器是否有掛載儲存空間");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POCO F8 Ultra 播放器'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _scanMusic),
        ],
      ),
      body: Column(
        children: [
          // 路徑顯示區
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            child: const Row(
              children: [
                Icon(Icons.folder_open, size: 20),
                SizedBox(width: 8),
                Text(
                  '路徑: /storage/emulated/0/Music',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // 中間：動態歌曲列表
          Expanded(
            child: _musicFiles.isEmpty
                ? const Center(child: Text("資料夾內無歌曲，請手動放入 MP3"))
                : ListView.builder(
                    itemCount: _musicFiles.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(_musicFiles[index]),
                        selected: _currentSong == _musicFiles[index],
                        onTap: () {
                          setState(() {
                            _currentSong = _musicFiles[index];
                          });
                          Log.i("已選擇歌曲: $_currentSong");
                        },
                      );
                    },
                  ),
          ),

          // 下半部：播放控制區 (把當前歌曲傳入)
          PlayerSection(currentSongName: _currentSong),
        ],
      ),
    );
  }
}

// 播放控制組件
class PlayerSection extends StatefulWidget {
  final String currentSongName; // 接收來自爸爸的資料
  const PlayerSection({super.key, required this.currentSongName});

  @override
  State<PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<PlayerSection> {
  bool isPlaying = false;
  double _sliderValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            '正在播放：${widget.currentSongName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _sliderValue,
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.shuffle),
                onPressed: () => Log.i("隨機模式"),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => Log.i("上一首"),
              ),
              IconButton(
                iconSize: 56,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.blueAccent,
                ),
                onPressed: () {
                  setState(() => isPlaying = !isPlaying);
                  Log.i(isPlaying ? "開始播放" : "暫停播放");
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => Log.i("下一首"),
              ),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: () => Log.i("重複模式"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
