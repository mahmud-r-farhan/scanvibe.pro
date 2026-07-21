import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../theme/app_colors.dart';

class TextViewerScreen extends StatefulWidget {
  const TextViewerScreen({
    super.key,
    required this.text,
    required this.title,
  });

  final String text;
  final String title;

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isSearchOpen = false;
  String _searchQuery = '';
  int _currentMatchIndex = -1;
  int _totalMatches = 0;

  int get _wordCount {
    final trimmed = widget.text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  int get _charCount => widget.text.length;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchQuery = '';
        _currentMatchIndex = -1;
        _totalMatches = 0;
        _searchController.clear();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentMatchIndex = -1;
      _totalMatches = _countMatches(query);
    });
  }

  void _navigateMatch(bool next) {
    if (_totalMatches == 0) return;

    setState(() {
      if (next) {
        _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatches;
      } else {
        _currentMatchIndex =
            (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
      }
    });
  }

  int _countMatches(String query) {
    if (query.isEmpty) return 0;
    final textLower = widget.text.toLowerCase();
    final queryLower = query.toLowerCase();
    var count = 0;
    var searchFrom = 0;

    while (true) {
      final index = textLower.indexOf(queryLower, searchFrom);
      if (index == -1) break;
      count++;
      searchFrom = index + queryLower.length;
    }

    return count;
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: widget.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Text copied to clipboard'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _shareText() {
    Share.share(widget.text, subject: widget.title);
  }

  void _editText() {
    context.push(
      '/text/edit',
      extra: {
        'text': widget.text,
        'documentId': '',
        'pageId': '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearchOpen ? Icons.search_off : Icons.search,
              color: _isSearchOpen ? AppColors.primaryLight : null,
            ),
            tooltip: _isSearchOpen ? 'Close Search' : 'Search',
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Copy All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Share'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editText();
                case 'copy':
                  _copyAll();
                case 'share':
                  _shareText();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchOpen) _buildSearchBar(theme),
          _buildStatsBar(theme),
          Expanded(
            child: widget.text.isEmpty
                ? _buildEmptyState(theme)
                : _buildTextContent(theme),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search in text...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_totalMatches > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentMatchIndex + 1}/$_totalMatches',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateMatch(true),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                GestureDetector(
                  onTap: () => _navigateMatch(false),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatChip(
            theme: theme,
            icon: Icons.text_fields,
            label: '$_charCount chars',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            theme: theme,
            icon: Icons.short_text,
            label: '$_wordCount words',
            color: theme.colorScheme.secondary,
          ),
          if (_searchQuery.isNotEmpty && _totalMatches > 0) ...[
            const SizedBox(width: 8),
            _buildStatChip(
              theme: theme,
              icon: Icons.search,
              label: '$_totalMatches matches',
              color: AppColors.info,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.article_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No text extracted',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run OCR on this document to\nextract text content',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(ThemeData theme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: SelectableText.rich(
        _buildHighlightedTextSpan(),
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  TextSpan _buildHighlightedTextSpan() {
    if (_searchQuery.isEmpty) {
      return TextSpan(text: widget.text);
    }

    final spans = <TextSpan>[];
    final textLower = widget.text.toLowerCase();
    final queryLower = _searchQuery.toLowerCase();
    var start = 0;
    var matchCount = 0;

    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        if (start < widget.text.length) {
          spans.add(TextSpan(text: widget.text.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: widget.text.substring(start, index)));
      }

      final isCurrentMatch = matchCount == _currentMatchIndex;
      spans.add(
        TextSpan(
          text: widget.text.substring(index, index + _searchQuery.length),
          style: TextStyle(
            backgroundColor: isCurrentMatch
                ? AppColors.primaryLight.withValues(alpha: 0.45)
                : AppColors.info.withValues(alpha: 0.2),
            color: isCurrentMatch ? Colors.white : null,
            fontWeight: isCurrentMatch ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );

      matchCount++;
      start = index + _searchQuery.length;
    }

    if (spans.isEmpty) {
      return TextSpan(text: widget.text);
    }

    return TextSpan(children: spans);
  }

  Widget _buildBottomBar(ThemeData theme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
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
          // Copy button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.text.isEmpty ? null : _copyAll,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Share button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.text.isEmpty ? null : _shareText,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Edit button
          Expanded(
            child: FilledButton.icon(
              onPressed: widget.text.isEmpty ? null : _editText,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                disabledForegroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
