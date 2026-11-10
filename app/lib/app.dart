import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

import 'screens/lesson_path_screen.dart';

/// The app shell. Screens only call the injected [StudyEngine].
class ChineseApp extends StatelessWidget {
  const ChineseApp({super.key, required this.engine});

  final StudyEngine engine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Chinese App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade700),
      ),
      home: LessonPathScreen(engine: engine),
    );
  }
}
