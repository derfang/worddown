import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';
import 'word_view_screen.dart';

class WordListScreen extends StatelessWidget {
  final String title;
  final List<DictWord> words;

  const WordListScreen({Key? key, required this.title, required this.words}) : super(key: key);

  void _openWord(BuildContext context, int wordId, String text) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordViewScreen(wordId: wordId, wordText: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                child: words.isEmpty
                    ? Center(
                        child: Text(
                          'No words in this list yet.',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: words.length,
                        itemBuilder: (context, index) {
                          final dictWord = words[index];

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
                                  dictWord.text,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: title == 'Known Words' 
                                        ? Colors.greenAccent 
                                        : (title == 'Learning Words' ? Colors.cyanAccent : Colors.white),
                                  )
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dictWord.meaning,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white70, height: 1.3),
                                  ),
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary),
                                ),
                                onTap: () => _openWord(context, dictWord.id, dictWord.text),
                              ),
                            ),
                          ),
                        );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
