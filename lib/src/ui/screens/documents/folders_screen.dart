import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/scanvibe_localizations.dart';
import '../../../providers/documents_provider.dart';
import '../../../theme/app_colors.dart';

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  static const _presetColors = [
    '#0F766E', // Teal
    '#7C3AED', // Purple
    '#2563EB', // Blue
    '#DC2626', // Red
    '#F59E0B', // Amber
    '#16A34A', // Green
    '#EC4899', // Pink
    '#F97316', // Orange
    '#6366F1', // Indigo
    '#0D9488', // Teal-600
  ];

  Color _hexToColor(String hex) {
    try {
      var clean = hex.trim();
      if (clean.startsWith('#')) {
        clean = clean.substring(1);
      }
      if (clean.length == 6) {
        clean = 'FF$clean';
      } else if (clean.length != 8) {
        return const Color(0xFF0F766E);
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return const Color(0xFF0F766E);
    }
  }



  IconData _folderIcon(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'medical':
        return Icons.local_hospital_rounded;
      case 'finance':
        return Icons.account_balance_rounded;
      case 'recipe':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.flight_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  void _showCreateFolderDialog({String? editFolderId, String? editName, String? editColor}) {
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: editName ?? '');
    String selectedColor = editColor ?? _presetColors.first;
    bool isEditing = editFolderId != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEditing
                    ? (l10n.text('rename') != 'rename' ? l10n.text('rename') : 'Edit Folder')
                    : 'New Folder',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _hexToColor(selectedColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          size: 40,
                          color: _hexToColor(selectedColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name field
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Folder name',
                        prefixIcon: const Icon(Icons.folder_outlined, size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _hexToColor(selectedColor),
                            width: 1.5,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        _saveFolder(
                          ctx,
                          nameController.text.trim(),
                          selectedColor,
                          editFolderId,
                          isEditing,
                          l10n,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Color picker
                    Text(
                      'Color',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _presetColors.map((hex) {
                        final color = _hexToColor(hex);
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setDialogState(() {
                            selectedColor = hex;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.text('deleteConfirmCancel')),
                ),
                FilledButton(
                  onPressed: () {
                    _saveFolder(
                      ctx,
                      nameController.text.trim(),
                      selectedColor,
                      editFolderId,
                      isEditing,
                      l10n,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _hexToColor(selectedColor),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? l10n.text('renameSave') : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveFolder(
    BuildContext ctx,
    String name,
    String color,
    String? folderId,
    bool isEditing,
    ScanVibeLocalizations l10n,
  ) {
    if (name.isEmpty) return;

    final foldersNotifier = ref.read(documentsProvider.notifier);

    if (isEditing && folderId != null) {
      foldersNotifier.updateFolder(
        folderId,
        name: name,
        color: color,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder updated'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      foldersNotifier.createFolder(name, color: color);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder created'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    Navigator.of(ctx).pop();
  }

  void _confirmDeleteFolder(String folderId, String name) {
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.folder_delete_outlined,
          color: AppColors.error,
          size: 32,
        ),
        title: const Text('Delete folder?'),
        content: Text(
          'Documents inside "$name" will be moved to the root. This action cannot be undone.',
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
              await ref
                  .read(documentsProvider.notifier)
                  .deleteFolder(folderId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder deleted'),
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

  int _countDocsInFolder(List<DocumentWithPages> docs, String folderId) {
    return docs.where((d) => d.document.folderId == folderId).length;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentsProvider);
    final l10n = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);
    final folders = state.folders;
    final docs = state.documents;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Folders',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New folder',
            onPressed: () => _showCreateFolderDialog(),
          ),
        ],
      ),
      body: folders.isEmpty
          ? _buildEmptyState(l10n, theme)
          : RefreshIndicator(
              color: AppColors.primaryLight,
              onRefresh: () async {},
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final folderColor = _hexToColor(folder.color);
                      final docCount = _countDocsInFolder(docs, folder.id);

                      return Slidable(
                        key: ValueKey(folder.id),
                        endActionPane: ActionPane(
                          motion: const BehindMotion(),
                          extentRatio: 0.45,
                          children: [
                            SlidableAction(
                              onPressed: (_) => _showCreateFolderDialog(
                                editFolderId: folder.id,
                                editName: folder.name,
                                editColor: folder.color,
                              ),
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
                              onPressed: (_) =>
                                  _confirmDeleteFolder(folder.id, folder.name),
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
                          onTap: () =>
                              context.push('/folders/${folder.id}'),
                          onLongPress: () =>
                              _showCreateFolderDialog(
                                editFolderId: folder.id,
                                editName: folder.name,
                                editColor: folder.color,
                              ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: folderColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: folderColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: folderColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    _folderIcon(folder.icon),
                                    size: 28,
                                    color: folderColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    folder.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$docCount ${docCount == 1 ? 'doc' : 'docs'}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(ScanVibeLocalizations l10n, ThemeData theme) {
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
                    AppColors.secondaryLight.withValues(alpha: 0.15),
                    AppColors.secondaryDark.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: AppColors.secondaryLight.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No folders yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Create folders to organize your scanned documents by category or project.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateFolderDialog(),
              icon: const Icon(Icons.create_new_folder_rounded, size: 20),
              label: const Text('New Folder'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
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
        ),
      ),
    );
  }
}
