import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

import 'lesson_screen.dart';

/// Home: the Lesson path.
class LessonPathScreen extends StatefulWidget {
  const LessonPathScreen({super.key, required this.engine});

  final StudyEngine engine;

  @override
  State<LessonPathScreen> createState() => _LessonPathScreenState();
}

class _LessonPathScreenState extends State<LessonPathScreen> {
  late Future<List<PathLesson>> _path = widget.engine.lessonPath();

  Future<void> _open(PathLesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LessonScreen(engine: widget.engine, lessonId: lesson.id),
      ),
    );
    if (!mounted) return;
    setState(() {
      _path = widget.engine.lessonPath();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: FutureBuilder(
        future: _path,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load Lessons: ${snapshot.error}'),
            );
          }
          final path = snapshot.data;
          if (path == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              for (final lesson in path)
                ListTile(
                  title: Text(lesson.title),
                  leading: Icon(switch (lesson.state) {
                    LessonState.locked => Icons.lock,
                    LessonState.unlocked => Icons.play_circle,
                    LessonState.passed => Icons.check_circle,
                  }),
                  enabled: lesson.state != LessonState.locked,
                  onTap: () => _open(lesson),
                ),
            ],
          );
        },
      ),
    );
  }
}
