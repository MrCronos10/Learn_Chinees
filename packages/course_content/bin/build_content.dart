import 'dart:io';

import 'package:course_content/course_content.dart';

const _usage =
    'Usage: dart run course_content:build_content '
    '<source.json> <word_ids.json> <output.db> [tone_recordings.json]\n'
    'Tone Recordings are copied into a "tones" folder next to output.db.';

void main(List<String> args) {
  if (args.length != 3 && args.length != 4) {
    stderr.writeln(_usage);
    exit(64);
  }
  try {
    buildCourseContent(
      sourcePath: args[0],
      registryPath: args[1],
      outputPath: args[2],
      recordingsPath: args.length == 4 ? args[3] : null,
    );
  } on ContentBuildException catch (e) {
    stderr.writeln('Content build failed: ${e.message}');
    exit(1);
  }
  stdout.writeln('Built Course Content: ${args[2]}');
}
