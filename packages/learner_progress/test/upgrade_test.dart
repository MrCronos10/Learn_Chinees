import 'dart:io';

import 'package:learner_progress/learner_progress.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('learner_progress_upgrade');
    path = '${dir.path}/learner_progress.db';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('Learner Progress saved by the v1 app survives the update', () async {
    // A database exactly as the ticket-02 app (schema v1) left it.
    sqlite3.open(path)
      ..execute(
        'CREATE TABLE passed_lessons '
        '(lesson_id TEXT PRIMARY KEY, passed_on TEXT NOT NULL)',
      )
      ..execute(
        "INSERT INTO passed_lessons VALUES ('lesson-1', '2026-11-09')",
      )
      ..userVersion = 1
      ..close();

    final store = SqliteLearnerProgressStore.open(path);
    addTearDown(store.close);

    expect(await store.passedLessonIds(), {'lesson-1'});
    expect(await store.totalXp(), 0);
  });
}
