import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../enums.dart';
import 'database_provider.dart';

// Document state
class DocumentsState {
  const DocumentsState({
    this.documents = const [],
    this.folders = const [],
    this.tags = const [],
    this.searchQuery = '',
    this.sortField = SortField.dateUpdated,
    this.sortOrder = SortOrder.descending,
    this.viewMode = DocumentViewMode.grid,
    this.selectedDocumentIds = const {},
    this.isProcessing = false,
  });

  final List<DocumentWithPages> documents;
  final List<Folder> folders;
  final List<Tag> tags;
  final String searchQuery;
  final SortField sortField;
  final SortOrder sortOrder;
  final DocumentViewMode viewMode;
  final Set<String> selectedDocumentIds;
  final bool isProcessing;

  List<DocumentWithPages> get filteredDocuments {
    var result = List<DocumentWithPages>.from(documents);

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((doc) {
        return doc.document.title.toLowerCase().contains(query) ||
            doc.pages.any((p) =>
                (p.extractedText ?? '').toLowerCase().contains(query));
      }).toList();
    }

    result.sort((a, b) {
      int comparison;
      switch (sortField) {
        case SortField.dateUpdated:
          comparison = a.document.updatedAt.compareTo(b.document.updatedAt);
        case SortField.dateCreated:
          comparison = a.document.createdAt.compareTo(b.document.createdAt);
        case SortField.name:
          comparison = a.document.title.compareTo(b.document.title);
        case SortField.pageCount:
          comparison = a.pages.length.compareTo(b.pages.length);
      }
      return sortOrder == SortOrder.descending ? -comparison : comparison;
    });

    return result;
  }

  int get totalDocuments => documents.length;
  int get totalPages => documents.fold(0, (sum, doc) => sum + doc.pages.length);
  int get pendingPages => documents.fold(
      0,
      (sum, doc) =>
          sum +
          doc.pages.where((p) => p.ocrStatus == 'queued').length);

  DocumentsState copyWith({
    List<DocumentWithPages>? documents,
    List<Folder>? folders,
    List<Tag>? tags,
    String? searchQuery,
    SortField? sortField,
    SortOrder? sortOrder,
    DocumentViewMode? viewMode,
    Set<String>? selectedDocumentIds,
    bool? isProcessing,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      folders: folders ?? this.folders,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      viewMode: viewMode ?? this.viewMode,
      selectedDocumentIds: selectedDocumentIds ?? this.selectedDocumentIds,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  DocumentsNotifier(this._db) : super(const DocumentsState()) {
    _watchAll();
  }

  final AppDatabase _db;
  final _uuid = const Uuid();

  void _watchAll() {
    _db.documentsDao.watchAllDocuments().listen((documents) {
      state = state.copyWith(documents: documents);
    });
    _db.foldersDao.watchAllFolders().listen((folders) {
      state = state.copyWith(folders: folders);
    });
    _db.tagsDao.watchAllTags().listen((tags) {
      state = state.copyWith(tags: tags);
    });
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortField(SortField field) {
    state = state.copyWith(sortField: field);
  }

  void setSortOrder(SortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void setViewMode(DocumentViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void toggleSelection(String documentId) {
    final selected = Set<String>.from(state.selectedDocumentIds);
    if (selected.contains(documentId)) {
      selected.remove(documentId);
    } else {
      selected.add(documentId);
    }
    state = state.copyWith(selectedDocumentIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedDocumentIds: {});
  }

  void selectAll() {
    state = state.copyWith(
      selectedDocumentIds: state.documents.map((d) => d.document.id).toSet(),
    );
  }

  Future<String> createDocument({
    String? title,
    String? folderId,
    String scanMode = 'document',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            id: id,
            title: title ?? 'Scan ${state.totalDocuments + 1}',
            createdAt: now,
            updatedAt: now,
            folderId: Value(folderId),
            scanMode: Value(scanMode),
          ),
        );
    return id;
  }

  Future<String> addPageToDocument({
    required String documentId,
    required String imagePath,
    String filterType = 'auto_enhance',
    String? thumbnailPath,
  }) async {
    final existingPages = await (_db.select(_db.scanPages)
          ..where((p) => p.documentId.equals(documentId))
          ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
        .get();

    final pageIndex = existingPages.length;
    final id = _uuid.v4();

    await _db.into(_db.scanPages).insert(
          ScanPagesCompanion.insert(
            id: id,
            documentId: documentId,
            pageIndex: Value(pageIndex),
            imagePath: imagePath,
            thumbnailPath: Value(thumbnailPath),
            createdAt: DateTime.now(),
          ),
        );

    // Update document's updatedAt
    await (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
        .write(DocumentsCompanion(
      updatedAt: Value(DateTime.now()),
    ));

    return id;
  }

  Future<void> updateDocumentTitle(String documentId, String title) async {
    await (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
        .write(DocumentsCompanion(
      title: Value(title),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> toggleFavorite(String documentId) async {
    final doc = await (_db.select(_db.documents)
          ..where((d) => d.id.equals(documentId)))
        .getSingleOrNull();
    if (doc != null) {
      await (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
          .write(DocumentsCompanion(
        isFavorite: Value(!doc.isFavorite),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> moveToFolder(String documentId, String? folderId) async {
    await (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
        .write(DocumentsCompanion(
      folderId: Value(folderId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteDocument(String documentId) async {
    await (_db.delete(_db.scanPages)
          ..where((p) => p.documentId.equals(documentId)))
        .go();
    await (_db.delete(_db.documentTags)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
    await (_db.delete(_db.documents)
          ..where((d) => d.id.equals(documentId)))
        .go();
  }

  Future<void> deleteSelectedDocuments() async {
    for (final id in state.selectedDocumentIds) {
      await deleteDocument(id);
    }
    clearSelection();
  }

  Future<void> deletePage(String pageId) async {
    await _db.scanPagesDao.deletePage(pageId);
  }

  Future<void> updatePageOcrStatus({
    required String pageId,
    required String status,
    String? extractedText,
    double? confidence,
    String? errorMessage,
  }) async {
    await (_db.update(_db.scanPages)..where((p) => p.id.equals(pageId)))
        .write(ScanPagesCompanion(
      ocrStatus: Value(status),
      extractedText: Value(extractedText),
      confidence: Value(confidence),
      errorMessage: Value(errorMessage),
    ));
  }

  Future<void> updatePageFilter({
    required String pageId,
    required String filterType,
  }) async {
    await (_db.update(_db.scanPages)..where((p) => p.id.equals(pageId)))
        .write(ScanPagesCompanion(
      filterType: Value(filterType),
    ));
  }

  Future<void> reorderPages(String documentId, List<String> pageIds) async {
    for (var i = 0; i < pageIds.length; i++) {
      await (_db.update(_db.scanPages)..where((p) => p.id.equals(pageIds[i])))
          .write(ScanPagesCompanion(
        pageIndex: Value(i),
      ));
    }
    await (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
        .write(DocumentsCompanion(
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<String> createFolder(String name, {String? color, String? parentId}) async {
    return _db.foldersDao.createFolder(name, color: color, parentId: parentId);
  }

  Future<void> updateFolder(String id, {String? name, String? color}) async {
    await _db.foldersDao.updateFolder(id, name: name, color: color);
  }

  Future<void> deleteFolder(String id) async {
    await _db.foldersDao.deleteFolder(id);
  }
}

// Document with pages helper
class DocumentWithPages {
  final Document document;
  final List<ScanPageData> pages;

  const DocumentWithPages({required this.document, required this.pages});

  String get combinedText => pages
      .map((p) => p.extractedText ?? '')
      .where((t) => t.trim().isNotEmpty)
      .join('\n\n');

  bool get hasFailedPages =>
      pages.any((p) => p.ocrStatus == 'failed');
  bool get hasQueuedPages =>
      pages.any((p) => p.ocrStatus == 'queued');
}

// DAO extensions on AppDatabase
extension DocumentsDaoExtension on AppDatabase {
  DocumentsDao get documentsDao => DocumentsDao(this);
  FoldersDao get foldersDao => FoldersDao(this);
  TagsDao get tagsDao => TagsDao(this);
  ScanPagesDao get scanPagesDao => ScanPagesDao(this);
}

class DocumentsDao {
  final AppDatabase _db;
  DocumentsDao(this._db);

  Stream<List<DocumentWithPages>> watchAllDocuments() {
    return _db.watchAllDocumentsWithPages();
  }

  Future<DocumentWithPages?> getDocument(String id) async {
    return _db.documentById(id);
  }

  Stream<List<ScanPageData>> watchPages(String documentId) {
    return (_db.select(_db.scanPages)
          ..where((p) => p.documentId.equals(documentId))
          ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
        .watch();
  }
}

class FoldersDao {
  final AppDatabase _db;
  FoldersDao(this._db);

  Stream<List<Folder>> watchAllFolders() {
    return (_db.select(_db.folders)
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
        .watch();
  }

  Future<Folder?> getFolder(String id) async {
    return (_db.select(_db.folders)..where((f) => f.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> createFolder(String name, {String? color, String? parentId}) async {
    final id = _db._uuid.v4();
    await _db.into(_db.folders).insert(
          FoldersCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.now(),
            color: Value(color ?? '#0F766E'),
            parentId: Value(parentId),
          ),
        );
    return id;
  }

  Future<void> updateFolder(String id, {String? name, String? color}) async {
    await (_db.update(_db.folders)..where((f) => f.id.equals(id)))
        .write(FoldersCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
    ));
  }

  Future<void> deleteFolder(String id) async {
    // Move documents out of folder
    await (_db.update(_db.documents)..where((d) => d.folderId.equals(id)))
        .write(const DocumentsCompanion(folderId: Value(null)));
    await (_db.delete(_db.folders)..where((f) => f.id.equals(id))).go();
  }

  Future<int> getDocumentCount(String folderId) async {
    final list = await (_db.select(_db.documents)..where((d) => d.folderId.equals(folderId))).get();
    return list.length;
  }
}

class TagsDao {
  final AppDatabase _db;
  TagsDao(this._db);

  Stream<List<Tag>> watchAllTags() {
    return (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<String> createTag(String name, {String? color}) async {
    final id = _db._uuid.v4();
    await _db.into(_db.tags).insert(
          TagsCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.now(),
            color: Value(color ?? '#7C3AED'),
          ),
        );
    return id;
  }

  Future<void> deleteTag(String id) async {
    await (_db.delete(_db.documentTags)..where((t) => t.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addTagToDocument(String documentId, String tagId) async {
    await _db.into(_db.documentTags).insert(
          DocumentTagsCompanion.insert(
            documentId: documentId,
            tagId: tagId,
          ),
        );
  }

  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    await (_db.delete(_db.documentTags)
          ..where((t) =>
              t.documentId.equals(documentId) & t.tagId.equals(tagId)))
        .go();
  }
}

class ScanPagesDao {
  final AppDatabase _db;
  ScanPagesDao(this._db);

  Future<ScanPageData?> getPage(String id) async {
    return (_db.select(_db.scanPages)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> deletePage(String id) async {
    await (_db.delete(_db.scanPages)..where((p) => p.id.equals(id))).go();
  }
}

// Helper extension on AppDatabase for watchAllDocuments
extension AppDatabaseHelpers on AppDatabase {
  Stream<List<DocumentWithPages>> watchAllDocumentsWithPages() async* {
    final docStream = select(documents).watch();
    await for (final docs in docStream) {
      final results = <DocumentWithPages>[];
      for (final doc in docs) {
        final pages = await (select(scanPages)
              ..where((p) => p.documentId.equals(doc.id))
              ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
            .get();
        results.add(DocumentWithPages(document: doc, pages: pages));
      }
      yield results;
    }
  }

  Future<DocumentWithPages?> documentById(String id) async {
    final doc = await (select(documents)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    if (doc == null) return null;
    final pages = await (select(scanPages)
          ..where((p) => p.documentId.equals(id))
          ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
        .get();
    return DocumentWithPages(document: doc, pages: pages);
  }

  Uuid get _uuid => const Uuid();
}

// Provider definition
final documentsProvider =
    StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  final db = ref.watch(databaseProvider);
  return DocumentsNotifier(db);
});
