
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class SyncStatusIndicator extends StatelessWidget {
  final bool showLabel;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return InkWell(
          onTap: onTap ?? () => _showSyncDialog(context, syncProvider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(syncProvider),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    syncProvider.statusMessage,
                    style: TextStyle(
                      color: _getColor(syncProvider),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(SyncProvider provider) {
    if (provider.isSyncing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_getColor(provider)),
        ),
      );
    }

    return Icon(
      _getIcon(provider),
      color: _getColor(provider),
      size: 20,
    );
  }

  IconData _getIcon(SyncProvider provider) {
    if (!provider.isOnline) return Icons.cloud_off;
    if (provider.hasOverdueItems) return Icons.error;
    if (provider.hasFailedItems) return Icons.warning;
    if (provider.hasPendingItems) return Icons.cloud_upload;
    if (provider.isFullySynced) return Icons.cloud_done;
    return Icons.cloud_queue;
  }

  Color _getColor(SyncProvider provider) {
    if (!provider.isOnline) return Colors.grey;
    if (provider.hasOverdueItems) return Colors.red;
    if (provider.hasFailedItems) return Colors.orange;
    if (provider.hasPendingItems) return Colors.amber;
    if (provider.isSyncing) return Colors.blue;
    if (provider.isFullySynced) return Colors.green;
    return Colors.grey;
  }

  void _showSyncDialog(BuildContext context, SyncProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: SyncStatusCard(compact: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (provider.isOnline && !provider.isSyncing)
            ElevatedButton.icon(
              onPressed: () {
                provider.syncNow();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }
}


class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isOnline &&
            !syncProvider.hasOverdueItems &&
            !syncProvider.hasFailedItems) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _getBannerColor(syncProvider),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  _getBannerIcon(syncProvider),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getBannerMessage(syncProvider),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (syncProvider.isOnline && !syncProvider.isSyncing)
                  TextButton(
                    onPressed: () => syncProvider.syncNow(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBannerColor(SyncProvider provider) {
    if (!provider.isOnline) return Colors.grey.shade700;
    if (provider.hasOverdueItems) return Colors.red.shade700;
    if (provider.hasFailedItems) return Colors.orange.shade700;
    return Colors.blue.shade700;
  }

  IconData _getBannerIcon(SyncProvider provider) {
    if (!provider.isOnline) return Icons.cloud_off;
    if (provider.hasOverdueItems) return Icons.error;
    if (provider.hasFailedItems) return Icons.warning;
    return Icons.sync;
  }

  String _getBannerMessage(SyncProvider provider) {
    if (!provider.isOnline) {
      return 'You are offline. Data will sync when connected.';
    }
    if (provider.hasOverdueItems) {
      return '${provider.syncStatus.overdueCount} items are overdue. Please sync now.';
    }
    if (provider.hasFailedItems) {
      return '${provider.syncStatus.failedCount} items failed to sync.';
    }
    return 'Syncing...';
  }
}

class SyncStatusCard extends StatelessWidget {
  final bool compact;

  const SyncStatusCard({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        final status = syncProvider.syncStatus;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status
            _buildStatusRow(
              icon: syncProvider.isOnline ? Icons.wifi : Icons.wifi_off,
              label: 'Connection',
              value: syncProvider.isOnline ? 'Online' : 'Offline',
              color: syncProvider.isOnline ? Colors.green : Colors.grey,
            ),

            const SizedBox(height: 12),

            // Pending items
            _buildStatusRow(
              icon: Icons.cloud_upload,
              label: 'Pending',
              value: '${status.pendingCount} items',
              color: status.pendingCount > 0 ? Colors.amber : Colors.green,
            ),

            const SizedBox(height: 12),

            // Failed items
            _buildStatusRow(
              icon: Icons.error_outline,
              label: 'Failed',
              value: '${status.failedCount} items',
              color: status.failedCount > 0 ? Colors.orange : Colors.green,
            ),

            const SizedBox(height: 12),

            // Overdue items
            _buildStatusRow(
              icon: Icons.timer_off,
              label: 'Overdue',
              value: '${status.overdueCount} items',
              color: status.overdueCount > 0 ? Colors.red : Colors.green,
            ),

            if (!compact) ...[
              const Divider(height: 24),

              // Last sync time
              _buildStatusRow(
                icon: Icons.access_time,
                label: 'Last sync',
                value: _formatLastSync(status.lastSyncAt),
                color: Colors.grey,
              ),
            ],

            // Error message
            if (syncProvider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncProvider.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!compact) ...[
              const SizedBox(height: 16),

              // Sync button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: syncProvider.isOnline && !syncProvider.isSyncing
                      ? () => syncProvider.syncNow()
                      : null,
                  icon: syncProvider.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(syncProvider.isSyncing ? 'Syncing...' : 'Sync Now'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${lastSync.day}/${lastSync.month}/${lastSync.year}';
  }
}


class SyncRequiredWrapper extends StatelessWidget {
  final Widget child;

  const SyncRequiredWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        return Column(
          children: [
            const SyncStatusBanner(),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
