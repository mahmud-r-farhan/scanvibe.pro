import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/documents_provider.dart';
import '../../../theme/app_colors.dart';

class FolderScreen extends ConsumerStatefulWidget {
  const FolderScreen({super.key, required this.folderId});

  final String folderId;

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> {
  bool _isEditing = false;
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentsProvider);

    final folder = docsState.folders.firstWhere(
      (f) => f.id == widget.folderId,
      orElse: () => throw Exception('Folder not found'),
    );

    final folderDocs = docsState.documents
        .where((d) => d.document.folderId == widget.folderId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: _isEditing
            ? TextField(
                controller: _titleController
                  ..text = folder.name
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: folder.name.length),
                  ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    ref.read(documentsProvider.notifier).updateFolder(
                          widget.folderId,
                          name: value.trim(),
                        );
                  }
                  setState(() => _isEditing = false);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Folder name',
                ),
              )
            : Text(folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => setState(() => _isEditing = true),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _FolderSearchDelegate(folderDocs),
              );
            },
          ),
        ],
      ),
      body: folderDocs.isEmpty
          ? _EmptyFolderState(
              folderName: folder.name,
              onAddDocument: () => context.go('/scan'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: folderDocs.length,
              itemBuilder: (context, index) {
                final doc = folderDocs[index];
                return _FolderDocumentCard(
                  document: doc,
                  onTap: () => context.push('/document/${doc.document.id}'),
                  onRemove: () {
                    ref.read(documentsProvider.notifier).moveToFolder(
                          doc.document.id,
                          null,
                        );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/scan'),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Scan to Folder'),
      ),
    );
  }
}

class _FolderDocumentCard extends StatelessWidget {
  const _FolderDocumentCard({
    required this.document,
    required this.onTap,
    required this.onRemove,
  });

  final DocumentWithPages document;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = document.document;
    final pageCount = document.pages.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pageCount ${pageCount == 1 ? "page" : "pages"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.folder_off_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Remove from folder'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') onRemove();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFolderState extends StatelessWidget {
  const _EmptyFolderState({
    required this.folderName,
    required this.onAddDocument,
  });

  final String folderName;
  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'No documents in $folderName',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a document and add it to this folder',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddDocument,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Scan Document'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderSearchDelegate extends SearchDelegate<DocumentWithPages?> {
  _FolderSearchDelegate(this.documents);

  final List<DocumentWithPages> documents;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = documents
        .where((d) =>
            d.document.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return ListTile(
          title: Text(doc.document.title),
          subtitle: Text('${doc.pages.length} pages'),
          onTap: () => close(context, doc),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
