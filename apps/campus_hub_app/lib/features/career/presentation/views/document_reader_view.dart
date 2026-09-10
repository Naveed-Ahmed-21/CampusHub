import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../domain/career_models.dart';

enum ReaderTheme {
  light,
  sepia,
  dark,
  midnight,
}

class DocumentReaderView extends ConsumerStatefulWidget {
  final VerifiedDocumentModel document;
  final int initialChapterIndex;

  const DocumentReaderView({
    super.key,
    required this.document,
    this.initialChapterIndex = 0,
  });

  static void open(
    BuildContext context, {
    required VerifiedDocumentModel document,
    int initialChapterIndex = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentReaderView(
          document: document,
          initialChapterIndex: initialChapterIndex,
        ),
      ),
    );
  }

  @override
  ConsumerState<DocumentReaderView> createState() => _DocumentReaderViewState();
}

class _DocumentReaderViewState extends ConsumerState<DocumentReaderView> {
  late int _currentChapterIndex;
  late ScrollController _scrollController;
  ReaderTheme _readerTheme = ReaderTheme.dark;
  double _fontSize = 16.0;
  double _scrollProgress = 0.0;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex.clamp(
      0,
      widget.document.chapters.isNotEmpty ? widget.document.chapters.length - 1 : 0,
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _loadSavedPreferences();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if ((progress - _scrollProgress).abs() > 0.02) {
        setState(() {
          _scrollProgress = progress;
        });
        _persistReadingProgress();
      }
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final rawTheme = await storage.getThemeMode();
      if (rawTheme != null && mounted) {
        if (rawTheme == 'sepia') _readerTheme = ReaderTheme.sepia;
        if (rawTheme == 'light') _readerTheme = ReaderTheme.light;
        if (rawTheme == 'midnight') _readerTheme = ReaderTheme.midnight;
        if (rawTheme == 'dark') _readerTheme = ReaderTheme.dark;
      }
      _persistReadingProgress();
    } catch (_) {}
  }

  Future<void> _persistReadingProgress() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final progressPercent = ((_currentChapterIndex + _scrollProgress) /
              (widget.document.chapters.isNotEmpty ? widget.document.chapters.length : 1) *
              100)
          .round();

      final payload = jsonEncode({
        'doc_id': widget.document.id,
        'doc_title': widget.document.title,
        'category': widget.document.category,
        'chapter_index': _currentChapterIndex,
        'chapter_title': _currentChapter?.title ?? '',
        'progress_percent': progressPercent,
        'accent_color': widget.document.accentColor,
        'total_chapters': widget.document.chapters.length,
        'last_read_at': DateTime.now().toIso8601String(),
      });

      await storage.saveRecentSearches(payload);
    } catch (_) {}
  }

  DocumentChapterModel? get _currentChapter {
    if (widget.document.chapters.isEmpty) return null;
    return widget.document.chapters[_currentChapterIndex];
  }

  Color get _backgroundColor {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return const Color(0xFFF8FAFC);
      case ReaderTheme.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderTheme.dark:
        return const Color(0xFF0F172A);
      case ReaderTheme.midnight:
        return const Color(0xFF000000);
    }
  }

  Color get _textColor {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return const Color(0xFF0F172A);
      case ReaderTheme.sepia:
        return const Color(0xFF3E2D17);
      case ReaderTheme.dark:
        return const Color(0xFFF1F5F9);
      case ReaderTheme.midnight:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get _cardColor {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.sepia:
        return const Color(0xFFF4E5C6);
      case ReaderTheme.dark:
        return const Color(0xFF1E293B);
      case ReaderTheme.midnight:
        return const Color(0xFF111827);
    }
  }

  Color get _borderColor {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return const Color(0xFFE2E8F0);
      case ReaderTheme.sepia:
        return const Color(0xFFE8D6B4);
      case ReaderTheme.dark:
        return const Color(0xFF334155);
      case ReaderTheme.midnight:
        return const Color(0xFF1F2937);
    }
  }

  void _switchChapter(int index) {
    if (index >= 0 && index < widget.document.chapters.length) {
      setState(() {
        _currentChapterIndex = index;
        _scrollProgress = 0.0;
      });
      _scrollController.jumpTo(0.0);
      _persistReadingProgress();
    }
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.menu_book, color: _textColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Table of Contents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.document.chapters.length} Chapters',
                    style: TextStyle(fontSize: 12, color: _textColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.document.chapters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final ch = widget.document.chapters[i];
                    final isSelected = i == _currentChapterIndex;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected
                            ? Colors.indigo
                            : _textColor.withValues(alpha: 0.1),
                        child: Text(
                          '${ch.chapterNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : _textColor,
                          ),
                        ),
                      ),
                      title: Text(
                        ch.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.indigoAccent : _textColor,
                        ),
                      ),
                      subtitle: Text(
                        '${ch.estimatedMinutes} min read • ${ch.summary}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.indigoAccent, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _switchChapter(i);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReaderAppearanceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reader Appearance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Font Size Adjuster
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Font Size', style: TextStyle(fontSize: 14, color: _textColor)),
                      Text('${_fontSize.toInt()} pt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('A-', style: TextStyle(fontSize: 13, color: _textColor)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 13.0,
                          max: 22.0,
                          divisions: 4,
                          activeColor: Colors.indigo,
                          onChanged: (val) {
                            setState(() => _fontSize = val);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      Text('A+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Color Themes
                  Text('Reading Theme', style: TextStyle(fontSize: 14, color: _textColor)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildThemeTile(ReaderTheme.light, 'Light', const Color(0xFFF8FAFC), const Color(0xFF0F172A), setSheetState),
                      _buildThemeTile(ReaderTheme.sepia, 'Sepia', const Color(0xFFFBF0D9), const Color(0xFF3E2D17), setSheetState),
                      _buildThemeTile(ReaderTheme.dark, 'Dark', const Color(0xFF0F172A), const Color(0xFFF1F5F9), setSheetState),
                      _buildThemeTile(ReaderTheme.midnight, 'Midnight', const Color(0xFF000000), const Color(0xFFE2E8F0), setSheetState),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeTile(ReaderTheme theme, String label, Color bg, Color textC, StateSetter setSheetState) {
    final isSelected = _readerTheme == theme;

    return GestureDetector(
      onTap: () {
        setState(() => _readerTheme = theme);
        setSheetState(() {});
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigoAccent : Colors.grey.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text('Aa', style: TextStyle(color: textC, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: textC, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _currentChapter;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor),
            ),
            if (chapter != null)
              Text(
                'Chapter ${chapter.chapterNumber} of ${widget.document.chapters.length}',
                style: TextStyle(fontSize: 11, color: _textColor.withValues(alpha: 0.6)),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 20),
            tooltip: 'Bookmark',
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBookmarked ? '🔖 Chapter bookmarked for offline study' : 'Bookmark removed'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_size, size: 20),
            tooltip: 'Appearance',
            onPressed: _showReaderAppearanceSheet,
          ),
          IconButton(
            icon: const Icon(Icons.list, size: 22),
            tooltip: 'Table of Contents',
            onPressed: _showTableOfContents,
          ),
          if (widget.document.canonicalUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Official Web Docs',
              onPressed: () => UrlLauncherService.openUrl(context, widget.document.canonicalUrl),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: LinearProgressIndicator(
            value: ((_currentChapterIndex + _scrollProgress) /
                    (widget.document.chapters.isNotEmpty ? widget.document.chapters.length : 1))
                .clamp(0.0, 1.0),
            backgroundColor: _borderColor.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
            minHeight: 3,
          ),
        ),
      ),
      body: chapter == null
          ? Center(
              child: Text(
                'No chapters available.',
                style: TextStyle(color: _textColor),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // Chapter Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'CHAPTER ${chapter.chapterNumber}',
                                    style: const TextStyle(
                                      color: Colors.indigoAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.timer_outlined, size: 14, color: _textColor.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  '${chapter.estimatedMinutes} min read',
                                  style: TextStyle(fontSize: 12, color: _textColor.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              chapter.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chapter.summary,
                              style: TextStyle(
                                fontSize: 13,
                                color: _textColor.withValues(alpha: 0.75),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chapter Body Content with Formatted Blocks
                      ..._buildFormattedContentBlocks(chapter.content),

                      const SizedBox(height: 32),

                      // End of Chapter Action Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chapter Complete! 🎓',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You have completed Chapter ${chapter.chapterNumber}: "${chapter.title}". Ready to advance your learning?',
                              style: TextStyle(fontSize: 12.5, color: _textColor.withValues(alpha: 0.75)),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (_currentChapterIndex > 0)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _textColor,
                                        side: BorderSide(color: _borderColor),
                                      ),
                                      icon: const Icon(Icons.arrow_back, size: 16),
                                      label: const Text('Previous'),
                                      onPressed: () => _switchChapter(_currentChapterIndex - 1),
                                    ),
                                  ),
                                if (_currentChapterIndex > 0 &&
                                    _currentChapterIndex < widget.document.chapters.length - 1)
                                  const SizedBox(width: 10),
                                if (_currentChapterIndex < widget.document.chapters.length - 1)
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                                      icon: const Icon(Icons.arrow_forward, size: 16),
                                      label: const Text('Next Chapter'),
                                      onPressed: () => _switchChapter(_currentChapterIndex + 1),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                // Bottom Quick Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    border: Border(top: BorderSide(color: _borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 22),
                        tooltip: 'Previous Chapter',
                        color: _currentChapterIndex > 0 ? _textColor : _textColor.withValues(alpha: 0.3),
                        onPressed: _currentChapterIndex > 0
                            ? () => _switchChapter(_currentChapterIndex - 1)
                            : null,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.toc, size: 18),
                        label: Text(
                          'Chapter ${chapter.chapterNumber} / ${widget.document.chapters.length}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor),
                        ),
                        onPressed: _showTableOfContents,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 22),
                        tooltip: 'Next Chapter',
                        color: _currentChapterIndex < widget.document.chapters.length - 1
                            ? _textColor
                            : _textColor.withValues(alpha: 0.3),
                        onPressed: _currentChapterIndex < widget.document.chapters.length - 1
                            ? () => _switchChapter(_currentChapterIndex + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildFormattedContentBlocks(String rawMarkdown) {
    final lines = rawMarkdown.split('\n');
    final widgets = <Widget>[];

    bool inCodeBlock = false;
    final codeLines = <String>[];
    String codeLanguage = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeLanguage = line.trim().replaceFirst('```', '');
          codeLines.clear();
        } else {
          inCodeBlock = false;
          widgets.add(_buildCodeSnippetBlock(codeLines.join('\n'), codeLanguage));
          widgets.add(const SizedBox(height: 12));
          codeLines.clear();
        }
        continue;
      }

      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      if (line.trim().startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.trim().replaceFirst('### ', ''),
            style: TextStyle(
              fontSize: _fontSize + 3,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ));
      } else if (line.trim().startsWith('#### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.trim().replaceFirst('#### ', ''),
            style: TextStyle(
              fontSize: _fontSize + 1.5,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ));
      } else if (line.trim().startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: Colors.indigoAccent, width: 4)),
          ),
          child: Text(
            line.trim().replaceFirst('> ', ''),
            style: TextStyle(
              fontSize: _fontSize - 0.5,
              fontStyle: FontStyle.italic,
              color: _textColor,
            ),
          ),
        ));
      } else if (line.trim().startsWith('- ') || line.trim().startsWith('• ')) {
        final bulletText = line.trim().substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(fontSize: _fontSize, color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  bulletText,
                  style: TextStyle(fontSize: _fontSize, color: _textColor, height: 1.45),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line,
            style: TextStyle(fontSize: _fontSize, color: _textColor, height: 1.55),
          ),
        ));
      } else {
        widgets.add(const SizedBox(height: 6));
      }
    }

    return widgets;
  }

  Widget _buildCodeSnippetBlock(String code, String language) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Icon(Icons.code, color: Colors.grey, size: 14),
              ],
            ),
          if (language.isNotEmpty) const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
