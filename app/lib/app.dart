import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

import 'audio/audio_player.dart';
import 'screens/lesson_path_screen.dart';

/// The app shell. Screens only call the injected [StudyEngine].
class ChineseApp extends StatelessWidget {
  const ChineseApp({super.key, required this.engine, required this.audio});

  final StudyEngine engine;
  final AudioPlayer audio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Chinese App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade700),
      ),
      home: LessonPathScreen(engine: engine, audio: audio),
    );
  }
}
