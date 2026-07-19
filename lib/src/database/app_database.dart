import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#0F766E'))();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withCustomName('tag_name')();
  TextColumn get color => text().withDefault(const Constant('#7C3AED'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => {{name}};
}

class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get folderId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get scanMode => text().withDefault(const Constant('document'))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ScanPages extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();
  IntColumn get pageIndex => integer().withDefault(const Constant(0))();
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get ocrStatus => text().withDefault(const Constant('queued'))();
  TextColumn get extractedText => text().nullable()();
  RealColumn get confidence => real().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get filterType => text().withDefault(const Constant('auto_enhance'))();
  TextColumn get edgePoints => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DocumentTags extends Table {
  TextColumn get documentId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {documentId, tagId};
}

@DriftDatabase(tables: [Folders, Tags, Documents, ScanPages, DocumentTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'scanvibe.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
