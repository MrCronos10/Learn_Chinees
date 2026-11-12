import 'dart:io';

import 'package:course_content/course_content.dart';

const _usage =
    'Usage: dart run course_content:build_content '
    '<source.json> <ids.json> <output.db> '
    '[--cedict <cedict.u8>] [--tone-recordings <tone_recordings.json>]\n'
    'ids.json is the ID registry of Words and Lessons. Tone Recordings are '
    'copied into a "tones" folder next to output.db.';

const _options = {'--cedict', '--tone-recordings'};

void main(List<String> args) {
  final positional = <String>[];
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--')) {
      if (!_options.contains(arg) || i + 1 >= args.length) _fail();
      options[arg] = args[++i];
    } else {
      positional.add(arg);
    }
  }
  if (positional.length != 3) _fail();
  try {
    buildCourseContent(
      sourcePath: positional[0],
      registryPath: positional[1],
      outputPath: positional[2],
      cedictPath: options['--cedict'],
      recordingsPath: options['--tone-recordings'],
    );
  } on ContentBuildException catch (e) {
    stderr.writeln('Content build failed: ${e.message}');
    exit(1);
  }
  stdout.writeln('Built Course Content: ${positional[2]}');
}

Never _fail() {
  stderr.writeln(_usage);
  exit(64);
}
