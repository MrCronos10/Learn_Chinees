import 'dart:io';

import 'package:course_content/course_content.dart';

const _usage =
    'Usage: dart run course_content:extract_cedict '
    '<source.json> <full cedict.u8> <extract.u8>\n'
    'Writes the CC-CEDICT header and exactly the entries the source uses.';

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(_usage);
    exit(64);
  }
  try {
    extractCedict(
      sourcePath: args[0],
      cedictPath: args[1],
      outputPath: args[2],
    );
  } on ContentBuildException catch (e) {
    stderr.writeln('Extract failed: ${e.message}');
    exit(1);
  }
  stdout.writeln('Wrote CC-CEDICT extract: ${args[2]}');
}
