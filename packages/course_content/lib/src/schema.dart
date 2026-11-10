/// Schema of the read-only Course Content database, shared by the builder
/// (writer) and the reader.
const createSchemaSql = '''
CREATE TABLE acknowledgements (
  id TEXT PRIMARY KEY,
  position INTEGER NOT NULL,
  name TEXT NOT NULL,
  author TEXT NOT NULL,
  license TEXT NOT NULL,
  url TEXT NOT NULL
);
CREATE TABLE words (
  id INTEGER PRIMARY KEY,
  characters TEXT NOT NULL,
  pinyin TEXT NOT NULL,
  meaning TEXT NOT NULL,
  source_id TEXT REFERENCES acknowledgements (id)
);
CREATE TABLE units (
  id TEXT PRIMARY KEY,
  position INTEGER NOT NULL,
  title TEXT NOT NULL
);
CREATE TABLE lessons (
  id TEXT PRIMARY KEY,
  unit_id TEXT NOT NULL REFERENCES units (id),
  position INTEGER NOT NULL,
  title TEXT NOT NULL
);
CREATE TABLE exercises (
  lesson_id TEXT NOT NULL REFERENCES lessons (id),
  position INTEGER NOT NULL,
  kind TEXT NOT NULL,
  word_id INTEGER NOT NULL REFERENCES words (id),
  choices TEXT NOT NULL,
  PRIMARY KEY (lesson_id, position)
);
''';

const exerciseKindMultipleChoice = 'multipleChoice';
const exerciseKindListening = 'listening';

/// Exercise kinds that study one Word and offer its meaning among choices.
const wordExerciseKinds = {exerciseKindMultipleChoice, exerciseKindListening};
