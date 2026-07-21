import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../enums.dart';
import '../../../l10n/scanvibe_localizations.dart';
import '../../../providers/documents_provider.dart';
import '../../../theme/app_colors.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _fabAnimController;
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 80) {
      _fabAnimController.reverse();
    } else {
      _fabAnimController.forward();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchController.clear();
        ref.read(documentsProvider.notifier).setSearchQuery('');
      }
    });
  }

  void _showSortSheet() {
    final state = ref.read(documentsProvider);
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  l10n.text('sort') != 'sort' ? l10n.text('sort') : 'Sort by',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...SortField.values.map((field) {
                  final isSelected = state.sortField == field;
                  return RadioListTile<SortField>(
                    value: field,
                    groupValue: state.sortField,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(documentsProvider.notifier).setSortField(value);
                      }
                      Navigator.of(ctx).pop();
                    },
                    title: Text(
                      _sortFieldLabel(field, l10n),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    secondary: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? AppColors.primaryLight : null,
                      size: 20,
                    ),
                    activeColor: AppColors.primaryLight,
                  );
                }),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    state.sortOrder == SortOrder.descending
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  title: Text(
                    state.sortOrder == SortOrder.descending
                        ? 'Descending'
                        : 'Ascending',
                  ),
                  onTap: () {
                    final newOrder = state.sortOrder == SortOrder.descending
                        ? SortOrder.ascending
                        : SortOrder.descending;
                    ref.read(documentsProvider.notifier).setSortOrder(newOrder);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sortFieldLabel(SortField field, ScanVibeLocalizations l10n) {
    switch (field) {
      case SortField.dateUpdated:
        return l10n.text('dateUpdated') != 'dateUpdated'
            ? l10n.text('dateUpdated')
            : 'Date Updated';
      case SortField.dateCreated:
        return l10n.text('dateCreated') != 'dateCreated'
            ? l10n.text('dateCreated')
            : 'Date Created';
      case SortField.name:
        return l10n.text('name') != 'name' ? l10n.text('name') : 'Name';
      case SortField.pageCount:
        return l10n.text('pageCount') != 'pageCount'
            ? l10n.text('pageCount')
            : 'Page Count';
    }
  }

  void _confirmDeleteDialog(String documentId, String title) {
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 32,
        ),
        title: Text(l10n.text('deleteConfirmTitle')),
        content: Text(
          l10n.text('deleteConfirmBody'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.text('deleteConfirmCancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(documentsProvider.notifier).deleteDocument(documentId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.text('documentDeleted')),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.text('deleteConfirmDelete')),
          ),
        ],
      ),
    );
  }

  void _confirmBatchDelete() {
    final state = ref.read(documentsProvider);
    final count = state.selectedDocumentIds.length;
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.delete_sweep_outlined,
          color: AppColors.error,
          size: 32,
        ),
        title: Text(l10n.text('deleteConfirmTitle')),
        content: Text(
          'Delete $count ${count == 1 ? 'document' : 'documents'}? ${l10n.text('deleteConfirmBody')}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.text('deleteConfirmCancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(documentsProvider.notifier).deleteSelectedDocuments();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count documents deleted'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.text('deleteConfirmDelete')),
          ),
        ],
      ),
    );
  }

  void _renameDocument(String documentId, String currentTitle) {
    final l10n = ScanVibeLocalizations.of(context);
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.text('rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.text('renameHint'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.text('deleteConfirmCancel')),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != currentTitle) {
                ref
                    .read(documentsProvider.notifier)
                    .updateDocumentTitle(documentId, newTitle);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.text('titleUpdated')),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.text('renameSave')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentsProvider);
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);
    final isMultiSelect = state.selectedDocumentIds.isNotEmpty;
    final filteredDocs = state.filteredDocuments;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(state, l10n, theme, isMultiSelect),
      body: Column(
        children: [
          if (_isSearchOpen) _buildSearchBar(l10n, theme),
          Expanded(
            child: filteredDocs.isEmpty
                ? _buildEmptyState(l10n, theme, state.searchQuery.isNotEmpty)
                : RefreshIndicator(
                    color: AppColors.primaryLight,
                    onRefresh: () async {
                      // Refresh is handled by the stream-based provider
                    },
                    child: state.viewMode == DocumentViewMode.grid
                        ? _buildGridView(filteredDocs, state, l10n, theme)
                        : _buildListView(filteredDocs, state, l10n, theme),
                  ),
          ),
        ],
      ),
      floatingActionButton: !isMultiSelect && !_isSearchOpen
          ? ScaleTransition(
              scale: CurvedAnimation(
                parent: _fabAnimController,
                curve: Curves.easeOutBack,
              ),
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/scan'),
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.document_scanner_outlined, size: 22),
                label: Text(
                  l10n.text('newScan'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
    DocumentsState state,
    ScanVibeLocalizations l10n,
    ThemeData theme,
    bool isMultiSelect,
  ) {
    if (isMultiSelect) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              ref.read(documentsProvider.notifier).clearSelection(),
        ),
        title: Text(
          '${state.selectedDocumentIds.length} selected',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all_rounded),
            tooltip: 'Select all',
            onPressed: () =>
                ref.read(documentsProvider.notifier).selectAll(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.text('delete'),
            onPressed: _confirmBatchDelete,
          ),
        ],
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
      );
    }

    return AppBar(
      title: Text(
        l10n.text('documents'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        if (state.documents.isNotEmpty) ...[
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
            tooltip: l10n.text('searchDocuments'),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: _showSortSheet,
          ),
          IconButton(
            icon: Icon(
              state.viewMode == DocumentViewMode.grid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip: 'Toggle view',
            onPressed: () {
              final newMode = state.viewMode == DocumentViewMode.grid
                  ? DocumentViewMode.list
                  : DocumentViewMode.grid;
              ref.read(documentsProvider.notifier).setViewMode(newMode);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(ScanVibeLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.text('searchDocuments'),
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(documentsProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.primaryLight,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          ref.read(documentsProvider.notifier).setSearchQuery(value);
          setState(() {}); // Update suffix icon
        },
      ),
    );
  }

  Widget _buildEmptyState(
    ScanVibeLocalizations l10n,
    ThemeData theme,
    bool isSearch,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.15),
                    AppColors.primaryDark.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.scanner_outlined,
                size: 48,
                color: AppColors.primaryLight.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isSearch
                  ? l10n.text('noSearchResults')
                  : l10n.text('emptyTitle'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isSearch
                  ? l10n.text('emptySearchBody')
                  : l10n.text('emptyBody'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearch) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.push('/scan'),
                icon: const Icon(Icons.document_scanner_outlined, size: 20),
                label: Text(l10n.text('newScan')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
    List<DocumentWithPages> docs,
    DocumentsState state,
    ScanVibeLocalizations l10n,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final isSelected =
                state.selectedDocumentIds.contains(doc.document.id);
            return _DocumentGridCard(
              doc: doc,
              isSelected: isSelected,
              onTap: () {
                if (state.selectedDocumentIds.isNotEmpty) {
                  ref
                      .read(documentsProvider.notifier)
                      .toggleSelection(doc.document.id);
                } else {
                  context.push('/document/${doc.document.id}');
                }
              },
              onLongPress: () {
                ref
                    .read(documentsProvider.notifier)
                    .toggleSelection(doc.document.id);
              },
              onDelete: () =>
                  _confirmDeleteDialog(doc.document.id, doc.document.title),
              onRename: () =>
                  _renameDocument(doc.document.id, doc.document.title),
              onToggleFavorite: () => ref
                  .read(documentsProvider.notifier)
                  .toggleFavorite(doc.document.id),
              l10n: l10n,
              theme: theme,
            );
          },
        );
      },
    );
  }

  Widget _buildListView(
    List<DocumentWithPages> docs,
    DocumentsState state,
    ScanVibeLocalizations l10n,
    ThemeData theme,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final isSelected =
            state.selectedDocumentIds.contains(doc.document.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _DocumentListTile(
            doc: doc,
            isSelected: isSelected,
            onTap: () {
              if (state.selectedDocumentIds.isNotEmpty) {
                ref
                    .read(documentsProvider.notifier)
                    .toggleSelection(doc.document.id);
              } else {
                context.push('/document/${doc.document.id}');
              }
            },
            onLongPress: () {
              ref
                  .read(documentsProvider.notifier)
                  .toggleSelection(doc.document.id);
            },
            onDelete: () =>
                _confirmDeleteDialog(doc.document.id, doc.document.title),
            onRename: () =>
                _renameDocument(doc.document.id, doc.document.title),
            onToggleFavorite: () => ref
                .read(documentsProvider.notifier)
                .toggleFavorite(doc.document.id),
            l10n: l10n,
            theme: theme,
          ),
        );
      },
    );
  }
}

// ───────────────────── Grid Card ─────────────────────

class _DocumentGridCard extends StatelessWidget {
  const _DocumentGridCard({
    required this.doc,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onRename,
    required this.onToggleFavorite,
    required this.l10n,
    required this.theme,
  });

  final DocumentWithPages doc;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onToggleFavorite;
  final ScanVibeLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final firstPage = doc.pages.isNotEmpty ? doc.pages.first : null;
    final thumbnailPath = firstPage?.thumbnailPath ?? firstPage?.imagePath;
    final ocrProgress = _calculateOcrProgress();
    final statusColor = _statusColor();

    return Slidable(
      key: ValueKey(doc.document.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) => onRename,
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: l10n.text('rename'),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: l10n.text('delete'),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.primaryLight : Colors.black)
                    .withValues(alpha: isSelected ? 0.12 : 0.04),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: thumbnailPath != null &&
                              File(thumbnailPath).existsSync()
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: Image.file(
                                File(thumbnailPath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.description_outlined,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                    // Page count badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${doc.pages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Selection check
                    if (isSelected)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    // Favorite icon
                    if (doc.document.isFavorite)
                      Positioned(
                        top: 8,
                        left: isSelected ? 36 : 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.error,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _StatusChip(
                            status: _overallStatus(),
                            l10n: l10n,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.pageCount(doc.pages.length),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // OCR progress
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ocrProgress,
                                minHeight: 4,
                                color: statusColor,
                                backgroundColor: theme
                                    .colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(ocrProgress * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateOcrProgress() {
    if (doc.pages.isEmpty) return 0;
    final completed = doc.pages.where((p) => p.ocrStatus == 'complete').length;
    return completed / doc.pages.length;
  }

  String _overallStatus() {
    if (doc.hasFailedPages) return 'failed';
    if (doc.hasQueuedPages) return 'queued';
    if (doc.pages.every((p) => p.ocrStatus == 'complete')) return 'complete';
    return 'queued';
  }

  Color _statusColor() {
    switch (_overallStatus()) {
      case 'complete':
        return AppColors.ocrComplete;
      case 'processing':
        return AppColors.ocrProcessing;
      case 'failed':
        return AppColors.ocrFailed;
      default:
        return AppColors.ocrQueued;
    }
  }
}

// ───────────────────── List Tile ─────────────────────

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile({
    required this.doc,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onRename,
    required this.onToggleFavorite,
    required this.l10n,
    required this.theme,
  });

  final DocumentWithPages doc;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onToggleFavorite;
  final ScanVibeLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final firstPage = doc.pages.isNotEmpty ? doc.pages.first : null;
    final thumbnailPath = firstPage?.thumbnailPath ?? firstPage?.imagePath;
    final ocrProgress = _calculateOcrProgress();
    final statusColor = _statusColor();

    return Slidable(
      key: ValueKey(doc.document.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) => onRename(),
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: l10n.text('rename'),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: l10n.text('delete'),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.primaryLight : Colors.black)
                    .withValues(alpha: isSelected ? 0.1 : 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 56,
                        height: 72,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        child: thumbnailPath != null &&
                                File(thumbnailPath).existsSync()
                            ? Image.file(
                                File(thumbnailPath),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.description_outlined,
                                size: 24,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doc.document.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (doc.document.isFavorite)
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.error,
                              size: 14,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(
                            status: _overallStatus(),
                            l10n: l10n,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.pageCount(doc.pages.length),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatRelativeDate(doc.document.updatedAt, l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ocrProgress,
                          minHeight: 3,
                          color: statusColor,
                          backgroundColor: theme
                              .colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateOcrProgress() {
    if (doc.pages.isEmpty) return 0;
    final completed = doc.pages.where((p) => p.ocrStatus == 'complete').length;
    return completed / doc.pages.length;
  }

  String _overallStatus() {
    if (doc.hasFailedPages) return 'failed';
    if (doc.hasQueuedPages) return 'queued';
    if (doc.pages.every((p) => p.ocrStatus == 'complete')) return 'complete';
    return 'queued';
  }

  Color _statusColor() {
    switch (_overallStatus()) {
      case 'complete':
        return AppColors.ocrComplete;
      case 'processing':
        return AppColors.ocrProcessing;
      case 'failed':
        return AppColors.ocrFailed;
      default:
        return AppColors.ocrQueued;
    }
  }

  String _formatRelativeDate(DateTime date, ScanVibeLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return l10n.formatDate(date);
  }
}

// ───────────────────── Status Chip ─────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.l10n});

  final String status;
  final ScanVibeLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      'complete' => AppColors.ocrComplete,
      'processing' => AppColors.ocrProcessing,
      'failed' => AppColors.ocrFailed,
      _ => AppColors.ocrQueued,
    };
    final label = switch (status) {
      'complete' => l10n.text('complete'),
      'processing' => l10n.text('processing'),
      'failed' => l10n.text('failed'),
      _ => l10n.text('queued'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
