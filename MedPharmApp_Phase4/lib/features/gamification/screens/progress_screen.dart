
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/gamification_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, bool> _weeklyCompletion = {};
  double _completionPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final gamificationProvider = context.read<GamificationProvider>();

    final studyId = authProvider.currentUser?.studyId;
    if (studyId != null) {
      await gamificationProvider.loadUserStats(studyId);

      final weekly = await gamificationProvider.getWeeklyCompletion(studyId);
      final percentage = await gamificationProvider.getCompletionPercentage(studyId);

      setState(() {
        _weeklyCompletion = weekly;
        _completionPercentage = percentage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
             
              _buildWeeklyCalendar(),
              const SizedBox(height: 24),

              _buildCompletionStats(),
              const SizedBox(height: 24),

        
              _buildStreakStats(),
              const SizedBox(height: 24),

     
              _buildBadgeProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _getWeekDays().map((day) {
                return SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _getLast7Days().map((date) {
                final dateKey = _formatDateKey(date);
                final isCompleted = _weeklyCompletion[dateKey] ?? false;
                final isToday = _isToday(date);

                return _buildDayCircle(date, isCompleted, isToday);
              }).toList(),
            ),

            const SizedBox(height: 16),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Completed'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.red, 'Missed'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.blue, 'Today'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCircle(DateTime date, bool isCompleted, bool isToday) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isToday && !isCompleted) {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue;
      textColor = Colors.blue;
    } else if (isCompleted) {
      backgroundColor = Colors.green.shade100;
      borderColor = Colors.green;
      textColor = Colors.green.shade700;
    } else {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade400;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.green, size: 20)
            : Text(
                date.day.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCompletionStats() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        final stats = provider.userStats;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Big percentage
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _completionPercentage / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[300],
                          color: _getCompletionColor(_completionPercentage),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_completionPercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Complete'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      '${stats?.totalAssessments ?? 0}',
                      Icons.assignment,
                    ),
                    _buildStatItem(
                      'Points',
                      '${stats?.totalPoints ?? 0}',
                      Icons.stars,
                    ),
                    _buildStatItem(
                      'Level',
                      '${stats?.level ?? 1}',
                      Icons.leaderboard,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.lightGreen;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStreakStats() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        final stats = provider.userStats;
        final currentStreak = stats?.currentStreak ?? 0;
        final longestStreak = stats?.longestStreak ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streaks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    // Current streak
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: currentStreak > 0
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 40,
                              color: currentStreak > 0 ? Colors.orange : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$currentStreak',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Current Streak'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Longest streak
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 40,
                              color: Colors.purple.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$longestStreak',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Best Streak'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Streak milestones
                const SizedBox(height: 16),
                _buildStreakMilestones(currentStreak),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakMilestones(int currentStreak) {
    final milestones = [3, 7, 14, 30];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Streak Milestones',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: milestones.map((milestone) {
            final isAchieved = currentStreak >= milestone;
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAchieved ? Colors.orange.shade100 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAchieved ? Colors.orange : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isAchieved
                        ? const Icon(Icons.check, color: Colors.orange, size: 20)
                        : Text(
                            '$milestone',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$milestone days',
                  style: TextStyle(
                    fontSize: 10,
                    color: isAchieved ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================================================
  // BADGE PROGRESS
  // ==========================================================================

  Widget _buildBadgeProgress() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        final earned = provider.earnedBadges.length;
        final total = BadgeType.values.length;

        return Card(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/badges');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Badges',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$earned of $total earned',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: earned / total,
                          backgroundColor: Colors.grey[300],
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _getWeekDays() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  List<DateTime> _getLast7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      return today.subtract(Duration(days: 6 - i));
    });
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
