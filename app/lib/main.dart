import 'dart:io';

import 'package:course_content/course_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learner_progress/learner_progress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:study_engine/study_engine.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final CourseContentReader content;
  final LearnerProgressStore progress;
  try {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    content = SqliteCourseContent.open(await _installCourseContent(dir));
    // Its own database, never replaced by an update (ADR-0001).
    progress = SqliteLearnerProgressStore.open(
      p.join(dir.path, 'learner_progress.db'),
    );
  } catch (error) {
    runApp(_StartupFailure(error));
    return;
  }
  final engine = StudyEngine(
    content: content,
    progress: progress,
    clock: const SystemClock(),
  );
  runApp(ChineseApp(engine: engine));
}

/// Shown instead of a frozen launch screen if Course Content cannot load.
class _StartupFailure extends StatelessWidget {
  const _StartupFailure(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'The app could not start. Please restart the app.\n\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

/// Copies the bundled Course Content database to a file SQLite can open.
/// It is replaced wholesale on every launch, so an app update always brings
/// the new Course Content (ADR-0001).
Future<String> _installCourseContent(Directory dir) async {
  final bytes = await rootBundle.load('assets/content/course.db');
  final file = File(p.join(dir.path, 'course_content.db'));
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  return file.path;
}
