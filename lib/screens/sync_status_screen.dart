import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sync_service.dart';
import '../services/progress_service.dart';

class SyncStatusScreen extends StatefulWidget {
  @override
  _SyncStatusScreenState createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final SyncService _sync = SyncService();
  final ProgressService _progress = ProgressService();

  @override
  void initState() {
    super.initState();
    _sync.isSyncing.addListener(_onSyncChange);
    _sync.lastSynced.addListener(_onSyncChange);
    _sync.lastError.addListener(_onSyncChange);
  }

  @override
  void dispose() {
    _sync.isSyncing.removeListener(_onSyncChange);
    _sync.lastSynced.removeListener(_onSyncChange);
    _sync.lastError.removeListener(_onSyncChange);
    super.dispose();
  }

  void _onSyncChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Cloud Sync Diagnostics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Pull from Cloud',
            onPressed: _sync.isSyncing.value ? null : () => _sync.forceSyncDown(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Account Card
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle, color: theme.colorScheme.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'Not Logged In',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            Text(
                              'UID: ${user?.uid ?? "N/A"}',
                              style: TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),

          // Local Counts Card
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local Device Database', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Known Words', '${_progress.knownWordIds.length}', Colors.greenAccent),
                      _buildStatColumn('In Progress', '${_progress.allProgress.length}', Colors.blueAccent),
                      _buildStatColumn('To Learn', '${_progress.queuedWordsToLearn.length}', Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),

          // Sync State Card
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sync Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          if (_sync.isSyncing.value) ...[
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            _sync.syncStatus.value,
                            style: TextStyle(
                              color: _sync.isSyncing.value ? theme.colorScheme.primary : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last Synced: ${_sync.lastSynced.value != null ? _sync.lastSynced.value!.toLocal().toString().substring(0, 19) : "Never"}',
                    style: TextStyle(fontSize: 13, color: Colors.white54),
                  ),
                  if (_sync.lastError.value != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _sync.lastError.value!,
                              style: TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sync.isSyncing.value ? null : () => _sync.forceSyncDown(),
                  icon: Icon(Icons.cloud_download),
                  label: Text('Pull Cloud Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sync.isSyncing.value ? null : () => _sync.forceSyncUp(),
                  icon: Icon(Icons.cloud_upload),
                  label: Text('Push to Cloud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Diagnostic Log Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Activity Log', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
              TextButton.icon(
                onPressed: () {
                  final logText = _sync.logs.join('\\n');
                  Clipboard.setData(ClipboardData(text: logText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logs copied to clipboard')),
                  );
                },
                icon: Icon(Icons.copy, size: 16),
                label: Text('Copy Logs', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 240,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: _sync.logs.isEmpty
                ? Center(child: Text('No log entries yet', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: _sync.logs.length,
                    itemBuilder: (context, index) {
                      final line = _sync.logs[_sync.logs.length - 1 - index];
                      final isError = line.toLowerCase().contains('error') || line.toLowerCase().contains('denied');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isError ? Colors.redAccent : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}
