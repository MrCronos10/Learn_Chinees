import 'dart:io';

import 'package:learner_progress/learner_progress.dart';
import 'package:study_engine/study_engine.dart';

/// A Learner Progress store implementation the engine suite runs against.
abstract class ProgressBackend {
  String get name;

  /// The store for the current test; fresh and empty at the start of it.
  LearnerProgressStore get store;

  /// Whether progress outlives the store object (like closing the app).
  bool get persistent;

  void setUp();

  /// Simulates closing and reopening the app; returns the reopened store.
  LearnerProgressStore restart();

  void tearDown();
}

final class InMemoryBackend extends ProgressBackend {
  @override
  final name = 'in-memory';
  @override
  final persistent = false;
  @override
  late LearnerProgressStore store;

  @override
  void setUp() => store = InMemoryLearnerProgressStore();

  @override
  LearnerProgressStore restart() => store;

  @override
  void tearDown() {}
}

final class SqliteBackend extends ProgressBackend {
  @override
  final name = 'SQLite';
  @override
  final persistent = true;
  @override
  late SqliteLearnerProgressStore store;
  late Directory _dir;

  String get _path => '${_dir.path}/learner_progress.db';

  @override
  void setUp() {
    _dir = Directory.systemTemp.createTempSync('learner_progress_test');
    store = SqliteLearnerProgressStore.open(_path);
  }

  @override
  LearnerProgressStore restart() {
    store.close();
    return store = SqliteLearnerProgressStore.open(_path);
  }

  @override
  void tearDown() {
    store.close();
    _dir.deleteSync(recursive: true);
  }
}

final progressBackends = <ProgressBackend>[InMemoryBackend(), SqliteBackend()];
