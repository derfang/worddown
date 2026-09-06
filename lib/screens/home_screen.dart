import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import 'word_view_screen.dart';
import 'settings_screen.dart';
import 'review_screen.dart';
import 'word_list_screen.dart';
import '../services/progress_service.dart';
import '../services/sync_service.dart';
import 'learning_session_screen.dart';
import 'sync_status_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum WordFilter { all, unlearned, learning, known }
enum WordSort { defaultSort, alphabetical, alphabeticalReverse, byRank }

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCurriculum;
  List<DictWord> _curriculumWords = [];
  bool _isLoading = false;
  TextEditingController? _searchController;
  FocusNode? _searchFocusNode;
  
  WordFilter _curriculumFilter = WordFilter.all;
  WordSort _curriculumSort = WordSort.defaultSort;

  @override
  void initState() {
    super.initState();
    // FirebaseService.signInAnonymously();
    SyncService().lastSynced.addListener(_onSyncComplete);
  }

  void _onSyncComplete() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SyncService().lastSynced.removeListener(_onSyncComplete);
    _searchController?.dispose();
    _searchFocusNode?.dispose();
    super.dispose();
  }

  void _openWord(int wordId, {String? wordText}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WordViewScreen(wordId: wordId, wordText: wordText)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadCurriculum(String? name) async {
    if (name == null) return;
    setState(() {
      _selectedCurriculum = name;
      _isLoading = true;
    });
    
    final words = await DatabaseService.getCurriculum(name);
    
    setState(() {
      _curriculumWords = words;
      _isLoading = false;
    });
  }

  List<DictWord> get _filteredAndSortedCurriculumWords {
    final progress = ProgressService();
    var filtered = _curriculumWords.where((w) {
      if (_curriculumFilter == WordFilter.all) return true;
      
      final isKnown = progress.knownWordIds.contains(w.id);
      final isLearning = progress.isInLearningQueue(w.id) || progress.getProgress(w.id) != null;
      
      if (_curriculumFilter == WordFilter.known) return isKnown;
      if (_curriculumFilter == WordFilter.learning) return isLearning;
      if (_curriculumFilter == WordFilter.unlearned) return !isKnown && !isLearning;
      return true;
    }).toList();
    
    if (_curriculumSort == WordSort.alphabetical) {
      filtered.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    } else if (_curriculumSort == WordSort.alphabeticalReverse) {
      filtered.sort((a, b) => b.text.toLowerCase().compareTo(a.text.toLowerCase()));
    } else if (_curriculumSort == WordSort.byRank) {
      filtered.sort((a, b) {
        final rankA = DatabaseService.getWordRank(a.id) ?? 999999;
        final rankB = DatabaseService.getWordRank(b.id) ?? 999999;
        return rankA.compareTo(rankB);
      });
    }
    
    return filtered;
  }

  Widget _buildFilterChip(String label, WordFilter filter, ThemeData theme) {
    final isSelected = _curriculumFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _curriculumFilter = filter;
            });
          }
        },
        selectedColor: theme.colorScheme.primary,
        backgroundColor: Colors.white.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, WordSort sort, ThemeData theme) {
    final isSelected = _curriculumSort == sort;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _curriculumSort = sort;
            });
          }
        },
        selectedColor: theme.colorScheme.secondary,
        backgroundColor: Colors.white.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('WordDown', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cloud Sync Diagnostics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SyncStatusScreen()),
              );
            },
            icon: ValueListenableBuilder<bool>(
              valueListenable: SyncService().isSyncing,
              builder: (context, isSyncing, child) {
                if (isSyncing) {
                  return SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  );
                }
                return ValueListenableBuilder<DateTime?>(
                  valueListenable: SyncService().lastSynced,
                  builder: (context, lastSynced, child) {
                    if (lastSynced == null) {
                      return Icon(Icons.cloud_queue, size: 22, color: Colors.white60);
                    }
                    return Icon(Icons.cloud_done, size: 22, color: Colors.greenAccent);
                  },
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              Color(0xFF1E1B4B), // Deep indigo
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  'Explore',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Search for any English word or browse a curriculum.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 32),

                // Review Banner
                Builder(
                  builder: (context) {
                    final dueCount = ProgressService().dueWords.length;
                    if (dueCount == 0) return SizedBox.shrink();
                    return Container(
                      margin: EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.primaryColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_filled, color: theme.primaryColor, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Time to review!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('You have $dueCount words due for practice.', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewScreen())).then((_) {
                                setState(() {}); // Refresh on return
                              });
                            },
                            child: Text('Review Now'),
                          )
                        ],
                      ),
                    );
                  },
                ),

                // Learning Session Banner
                Builder(
                  builder: (context) {
                    final learnCount = ProgressService().queuedWordsToLearn.length;
                    if (learnCount == 0) return SizedBox.shrink();
                    return Container(
                      margin: EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.queue_play_next, color: Colors.cyan, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('New words to learn!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('You have $learnCount words in your queue.', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => LearningSessionScreen())).then((_) {
                                setState(() {}); // Refresh on return
                              });
                            },
                            child: Text('Learn Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  },
                ),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      )
                    ]
                  ),
                  child: Autocomplete<DictWord>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return DatabaseService.searchWords(textEditingValue.text);
                    },
                    displayStringForOption: (DictWord option) => option.text,
                    onSelected: (DictWord selection) {
                      _openWord(selection.id, wordText: selection.text);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      _searchController = controller;
                      _searchFocusNode = focusNode;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search for an English word...',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8.0,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 250,
                              maxWidth: MediaQuery.of(context).size.width - 48,
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white12, height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                final isKnown = ProgressService().knownWordIds.contains(option.id);
                                final isLearning = ProgressService().isInLearningQueue(option.id) || ProgressService().getProgress(option.id) != null;
                                final wordColor = isKnown ? Colors.greenAccent : (isLearning ? Colors.cyanAccent : Colors.white);
                                final rank = DatabaseService.getWordRank(option.id);
                                final rankText = rank != null ? '#$rank' : '';
                                return ListTile(
                                  title: Text(option.text, style: TextStyle(fontWeight: FontWeight.w600, color: wordColor)),
                                  subtitle: Text(
                                    option.meaning,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                  trailing: Text(rankText, style: TextStyle(color: Colors.white30, fontSize: 12)),
                                  onTap: () {
                                    _openWord(option.id, wordText: option.text);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'My Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                _buildProgressTabs(theme),
                SizedBox(height: 24),

                Text(
                  'Curriculums',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                // Curriculum Dropdown
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurriculum,
                      hint: Text('Browse Curriculum', style: TextStyle(color: Colors.white70)),
                      isExpanded: true,
                      dropdownColor: theme.colorScheme.surface,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                      items: DatabaseService.availableCurriculums.map((String name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            name.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.1),
                          ),
                        );
                      }).toList(),
                      onChanged: _loadCurriculum,
                    ),
                  ),
                ),
                if (_selectedCurriculum != null && !_isLoading && _curriculumWords.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', WordFilter.all, theme),
                            _buildFilterChip('Unlearned', WordFilter.unlearned, theme),
                            _buildFilterChip('Learning', WordFilter.learning, theme),
                            _buildFilterChip('Known', WordFilter.known, theme),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: [
                              _buildSortChip('Default Sort', WordSort.defaultSort, theme),
                              _buildSortChip('A-Z', WordSort.alphabetical, theme),
                              _buildSortChip('Z-A', WordSort.alphabeticalReverse, theme),
                              _buildSortChip('By Rank', WordSort.byRank, theme),
                            ],
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 24),
              ],
            ),
          ),
                // Curriculum List
                _isLoading 
                    ? SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)))
                    : _curriculumWords.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_mosaic, size: 64, color: Colors.white24),
                                  SizedBox(height: 16),
                                  Text(
                                    'Select a curriculum to start learning.',
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          )
                        )
                      : _filteredAndSortedCurriculumWords.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No words match this filter.',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            )
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                              final word = _filteredAndSortedCurriculumWords[index];
                              final progress = ProgressService().getProgress(word.id);
                              final isKnown = ProgressService().knownWordIds.contains(word.id);
                              final isLearning = ProgressService().isInLearningQueue(word.id) || progress != null;
                            final wordColor = isKnown ? Colors.greenAccent : (isLearning ? Colors.cyanAccent : Colors.white);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    )
                                  ],
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  title: Text(
                                    word.text,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: wordColor,
                                    )
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      word.meaning,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white70, height: 1.3),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.add_circle_outline, color: theme.primaryColor),
                                    onPressed: () {
                                      ProgressService().addWordToLearn(word.id);
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to learning queue!')));
                                    },
                                  ),
                                  onTap: () => _openWord(word.id, wordText: word.text),
                                ),
                              ),
                            ),
                          );
                          },
                          childCount: _filteredAndSortedCurriculumWords.length,
                        ),
                      ),
              ], // slivers
            ), // CustomScrollView
          ), // Padding
      ), // ConstrainedBox
    ), // Center
  ), // SafeArea
), // Container
); // Scaffold
}

  Widget _buildProgressTabs(ThemeData theme) {
    final learning = ProgressService().learningWords;
    final knownIds = ProgressService().knownWordIds;
    
    final learningDictWords = learning.map((p) => DatabaseService.getWordById(p.wordId)).whereType<DictWord>().toList();
    final knownDictWords = knownIds.map((id) => DatabaseService.getWordById(id)).whereType<DictWord>().toList();
    
    // Quick summary
    return Row(
      children: [
        Expanded(child: _buildStatCard('Learning', learningDictWords.length.toString(), Colors.cyanAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(title: 'Learning Words', words: learningDictWords)));
        })),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Known', knownDictWords.length.toString(), Colors.greenAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WordListScreen(title: 'Known Words', words: knownDictWords)));
        })),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
