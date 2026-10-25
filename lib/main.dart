
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaserZamilApp());
}

const green = Color(0xFF073B32);
const gold = Color(0xFFE3BD69);

class Zamil {
  final String title;
  final String file;

  const Zamil(this.title, this.file);
}

const zawamil = <Zamil>[
  Zamil('الزامل الأول', 'zamil1.mp3'),
  Zamil('الزامل الثاني', 'zamil2.mp3'),
];

class KaserZamilApp extends StatelessWidget {
  const KaserZamilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'زوامل عيسى الليث',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5F2E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const ZamilHome(),
    );
  }
}

class ZamilHome extends StatefulWidget {
  const ZamilHome({super.key});

  @override
  State<ZamilHome> createState() => _ZamilHomeState();
}

class _ZamilHomeState extends State<ZamilHome> {
  final AudioPlayer player = AudioPlayer();
  final TextEditingController searchController =
      TextEditingController();

  int current = 0;
  String search = '';
  bool loading = false;
  String? loadedFile;
  String? errorMessage;
  final Set<String> favorites = {};

  Zamil get selected => zawamil[current];

  List<int> get filteredIndexes {
    return List.generate(zawamil.length, (i) => i)
        .where((i) => zawamil[i].title.contains(search))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    player.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> playTrack(int index) async {
    if (loading) return;

    setState(() {
      current = index;
      loading = true;
      errorMessage = null;
    });

    try {
      final file = 'assets/zawamil/${zawamil[index].file}';

      if (loadedFile != file) {
        await player.setAsset(file);
        loadedFile = file;
      }

      await player.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage =
              'تعذر تشغيل الملف. تأكد من إضافته إلى مجلد الأصول.';
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> togglePlay() async {
    if (loading) return;

    if (loadedFile != 'assets/zawamil/${selected.file}') {
      await playTrack(current);
      return;
    }

    if (player.playing) {
      await player.pause();
    } else {
      try {
        await player.play();
      } catch (_) {
        if (mounted) {
          setState(() {
            errorMessage = 'تعذر تشغيل التسجيل.';
          });
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> nextTrack() async {
    await playTrack((current + 1) % zawamil.length);
  }

  Future<void> previousTrack() async {
    await playTrack(
      (current - 1 + zawamil.length) % zawamil.length,
    );
  }

  String formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = player.playerState;
    final isPlaying = state.playing;
    final duration = player.duration ?? Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'زوامل عيسى الليث',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'المفضلة',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const ListTile(
                        title: Text('الزوامل المفضلة'),
                      ),
                      ...zawamil.asMap().entries
                          .where((e) =>
                              favorites.contains(e.value.file))
                          .map((e) => ListTile(
                                title: Text(e.value.title),
                                onTap: () {
                                  Navigator.pop(context);
                                  playTrack(e.key);
                                },
                              )),
                      if (favorites.isEmpty)
                        const ListTile(
                          title: Text('لم تضف زوامل للمفضلة بعد'),
                        ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    size: 76,
                    color: gold,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'مكتبة الزوامل',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selected.title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: previousTrack,
                        icon: const Icon(Icons.skip_previous),
                        color: Colors.white,
                        iconSize: 34,
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: green,
                          fixedSize: const Size(64, 64),
                        ),
                        onPressed: togglePlay,
                        icon: Icon(
                          loading
                              ? Icons.hourglass_top
                              : isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                        ),
                        iconSize: 36,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: nextTrack,
                        icon: const Icon(Icons.skip_next),
                        color: Colors.white,
                        iconSize: 34,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    initialData: Duration.zero,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final max = duration.inMilliseconds.toDouble();
                      final value = position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, max > 0 ? max : 1.0);

                      return Column(
                        children: [
                          Slider(
                            activeColor: gold,
                            inactiveColor: Colors.white30,
                            min: 0,
                            max: max > 0 ? max : 1,
                            value: value,
                            onChanged: max <= 0
                                ? null
                                : (v) => player.seek(
                                      Duration(
                                        milliseconds: v.toInt(),
                                      ),
                                    ),
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatTime(position),
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),
                              Text(
                                formatTime(duration),
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amberAccent),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن زامل...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'قائمة الزوامل',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filteredIndexes.length,
                itemBuilder: (context, position) {
                  final index = filteredIndexes[position];
                  final item = zawamil[index];
                  final active = index == current;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            active ? green : const Color(0xFFE5E8E3),
                        child: Icon(
                          active && isPlaying
                              ? Icons.volume_up
                              : Icons.music_note,
                          color: active ? gold : green,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('تشغيل من الجهاز'),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            if (!favorites.add(item.file)) {
                              favorites.remove(item.file);
                            }
                          });
                        },
                        icon: Icon(
                          favorites.contains(item.file)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favorites.contains(item.file)
                              ? Colors.red
                              : green,
                        ),
                      ),
                      onTap: () => playTrack(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}