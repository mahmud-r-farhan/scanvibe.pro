import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/documents_provider.dart';
import '../../../theme/app_colors.dart';

class TextEditorScreen extends ConsumerStatefulWidget {
  const TextEditorScreen({
    super.key,
    required this.text,
    required this.documentId,
    required this.pageId,
  });

  final String text;
  final String documentId;
  final String pageId;

  @override
  ConsumerState<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends ConsumerState<TextEditorScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  bool _hasChanges = false;
  bool _isSaving = false;

  // Undo/Redo stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoRedoAction = false;

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;
  int get _charCount => _textController.text.length;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _undoStack.add(widget.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isUndoRedoAction) {
      _isUndoRedoAction = false;
      return;
    }

    final currentText = _textController.text;

    if (_undoStack.isEmpty || _undoStack.last != currentText) {
      _undoStack.add(currentText);
      _redoStack.clear();
    }

    final hasChanged = currentText != widget.text;
    if (hasChanged != _hasChanges) {
      setState(() => _hasChanges = hasChanged);
    }
  }

  void _undo() {
    if (!_canUndo) return;

    final currentText = _textController.text;
    _redoStack.add(currentText);

    final previousText = _undoStack.removeLast();

    _isUndoRedoAction = true;
    _textController.text = previousText;
    _textController.selection = TextSelection.collapsed(
      offset: previousText.length,
    );

    setState(() {
      _hasChanges = _textController.text != widget.text;
    });
  }

  void _redo() {
    if (!_canRedo) return;

    final currentText = _textController.text;
    _undoStack.add(currentText);

    final nextText = _redoStack.removeLast();

    _isUndoRedoAction = true;
    _textController.text = nextText;
    _textController.selection = TextSelection.collapsed(
      offset: nextText.length,
    );

    setState(() {
      _hasChanges = _textController.text != widget.text;
    });
  }

  Future<void> _saveChanges() async {
    final newText = _textController.text;

    if (newText == widget.text) {
      if (mounted) {
        context.pop();
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.documentId.isNotEmpty && widget.pageId.isNotEmpty) {
        await ref.read(documentsProvider.notifier).updatePageOcrStatus(
              pageId: widget.pageId,
              status: 'complete',
              extractedText: newText,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Changes saved'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop(newText);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await _saveChanges();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
            tooltip: 'Cancel',
          ),
          title: const Text(
            'Edit Text',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            // Undo
            IconButton(
              onPressed: _canUndo ? _undo : null,
              icon: const Icon(Icons.undo, size: 22),
              tooltip: 'Undo',
            ),
            // Redo
            IconButton(
              onPressed: _canRedo ? _redo : null,
              icon: const Icon(Icons.redo, size: 22),
              tooltip: 'Redo',
            ),
            const SizedBox(width: 4),
            // Save
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isSaving
                    ? null
                    : _hasChanges
                        ? _saveChanges
                        : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                  disabledForegroundColor:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildStatusBar(theme),
            Expanded(
              child: _buildEditor(theme),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasChanges ? Icons.edit_note : Icons.check_circle_outline,
            size: 16,
            color: _hasChanges
                ? AppColors.warning
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            _hasChanges ? 'Modified' : 'No changes',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _hasChanges
                  ? AppColors.warning
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$_charCount characters',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      onChanged: (_) => _onTextChanged(),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.8,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Start typing or paste text here...',
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.all(20),
        border: InputBorder.none,
        filled: false,
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding + 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Undo/Redo group
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _canUndo ? _undo : null,
                  icon: Icon(
                    Icons.undo,
                    size: 20,
                    color: _canUndo
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                  ),
                  tooltip: 'Undo',
                  visualDensity: VisualDensity.compact,
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                IconButton(
                  onPressed: _canRedo ? _redo : null,
                  icon: Icon(
                    Icons.redo,
                    size: 20,
                    color: _canRedo
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                  ),
                  tooltip: 'Redo',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Word count
          Text(
            _computeWordCount(_textController.text),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),

          const Spacer(),

          // Cancel button
          TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    if (_hasChanges) {
                      _onWillPop().then((shouldPop) {
                        if (shouldPop && context.mounted && mounted) {
                          context.pop();
                        }
                      });
                    } else {
                      if (context.mounted && mounted) {
                        context.pop();
                      }
                    }
                  },
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          // Save button
          FilledButton(
            onPressed: _isSaving
                ? null
                : _hasChanges
                    ? _saveChanges
                    : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              disabledForegroundColor:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _computeWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '0 words';
    final count = trimmed.split(RegExp(r'\s+')).length;
    return '$count ${count == 1 ? 'word' : 'words'}';
  }
}
