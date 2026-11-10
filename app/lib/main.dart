import 'dart:io';

import 'package:course_content/course_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:study_engine/study_engine.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final CourseContentReader content;
  try {
    content = SqliteCourseContent.open(await _installCourseContent());
  } catch (error) {
    runApp(_StartupFailure(error));
    return;
  }
  final engine = StudyEngine(
    content: content,
    // Learner Progress is in-memory until the SQLite store lands (ticket 02).
    progress: InMemoryLearnerProgressStore(),
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
            'The Lessons could not be loaded. Please restart the app.\n\n$error',
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
Future<String> _installCourseContent() async {
  final bytes = await rootBundle.load('assets/content/course.db');
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'course_content.db'));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  return file.path;
}
