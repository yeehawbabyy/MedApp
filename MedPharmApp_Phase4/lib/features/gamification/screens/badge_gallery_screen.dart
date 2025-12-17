

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import '../models/gamification_model.dart';

class BadgeGalleryScreen extends StatelessWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Gallery'),
        centerTitle: true,
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final earnedBadges = provider.earnedBadges;
          final earnedTypes = earnedBadges.map((b) => b.badgeType).toSet();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSummary(context, earnedBadges.length),
                const SizedBox(height: 24),

                if (earnedBadges.isNotEmpty) ...[
                  Text(
                    'Earned Badges (${earnedBadges.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBadgeGrid(
                    context,
                    BadgeType.values.where((t) => earnedTypes.contains(t)).toList(),
                    earnedBadges,
                    isEarned: true,
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Locked Badges (${BadgeType.values.length - earnedBadges.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBadgeGrid(
                  context,
                  BadgeType.values.where((t) => !earnedTypes.contains(t)).toList(),
                  earnedBadges,
                  isEarned: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, int earnedCount) {
    final totalBadges = BadgeType.values.length;
    final progress = earnedCount / totalBadges;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Text(
                  '$earnedCount / $totalBadges',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.amber,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% Complete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(
    BuildContext context,
    List<BadgeType> badgeTypes,
    List<BadgeModel> earnedBadges,
    {required bool isEarned}
  ) {
    if (badgeTypes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              isEarned ? 'No badges earned yet' : 'All badges earned!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badgeTypes.length,
      itemBuilder: (context, index) {
        final badgeType = badgeTypes[index];
        final earnedBadge = earnedBadges.firstWhere(
          (b) => b.badgeType == badgeType,
          orElse: () => BadgeModel(studyId: '', badgeType: badgeType),
        );
        return _buildBadgeCard(context, badgeType, isEarned, earnedBadge);
      },
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    BadgeType badgeType,
    bool isEarned,
    BadgeModel badge,
  ) {
    return InkWell(
      onTap: () {
        _showBadgeDetails(context, badgeType, isEarned, badge);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEarned ? Colors.amber.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? Colors.amber : Colors.grey.shade300,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEarned ? Colors.amber.shade100 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForBadge(badgeType),
                color: isEarned ? Colors.amber.shade700 : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              badgeType.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                color: isEarned ? Colors.black : Colors.grey[600],
              ),
            ),

            if (!isEarned)
              Icon(
                Icons.lock,
                size: 14,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForBadge(BadgeType badgeType) {
 
    switch (badgeType) {
      case BadgeType.streak3Day:
      case BadgeType.streak7Day:
      case BadgeType.streak14Day:
      case BadgeType.streak30Day:
        return Icons.local_fire_department;
      case BadgeType.firstAssessment:
        return Icons.star;
      case BadgeType.tenthAssessment:
      case BadgeType.twentyFifthAssessment:
      case BadgeType.fiftiethAssessment:
      case BadgeType.hundredthAssessment:
        return Icons.emoji_events;
      case BadgeType.earlyBird:
        return Icons.wb_sunny;
      case BadgeType.perfectWeek:
        return Icons.calendar_today;
      case BadgeType.dedicated:
        return Icons.workspace_premium;
    }
  }

  void _showBadgeDetails(
    BuildContext context,
    BadgeType badgeType,
    bool isEarned,
    BadgeModel badge,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isEarned ? Colors.amber.shade100 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEarned ? Colors.amber : Colors.grey,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _getIconForBadge(badgeType),
                  color: isEarned ? Colors.amber.shade700 : Colors.grey,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                badgeType.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                badgeType.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              if (isEarned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Earned on ${_formatDate(badge.earnedAt)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Text('Not yet earned'),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
