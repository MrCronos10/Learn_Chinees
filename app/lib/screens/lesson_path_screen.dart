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

class _LessonPathScreenState extends State<LessonPathScreen>
    with WidgetsBindingObserver {
  late Future<List<PathLesson>> _path = widget.engine.lessonPath();
  late Future<int> _totalXp = widget.engine.totalXp();
  late Future<int> _streak = widget.engine.currentStreak();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the background, the Day may have changed (Streak, due Words).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _path = widget.engine.lessonPath();
      _totalXp = widget.engine.totalXp();
      _streak = widget.engine.currentStreak();
    });
  }

  Future<void> _open(PathLesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LessonScreen(engine: widget.engine, lessonId: lesson.id),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Stat(
                  icon: Icons.local_fire_department,
                  value: _streak,
                  unit: '-Day Streak',
                ),
                _Stat(icon: Icons.bolt, value: _totalXp, unit: ' XP'),
              ],
            ),
          ),
          Expanded(child: _lessonList()),
        ],
      ),
    );
  }

  Widget _lessonList() {
    return FutureBuilder(
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
    );
  }
}

/// One number above the Lesson path, such as total XP or the Streak.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.unit});

  final IconData icon;
  final Future<int> value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: value,
      builder: (context, snapshot) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          // Never show a made-up 0 while loading or after an error.
          Text(switch (snapshot) {
            AsyncSnapshot(hasError: true) => '?$unit',
            AsyncSnapshot(:final data?) => '$data$unit',
            _ => '…$unit',
          }),
        ],
      ),
    );
  }
}
