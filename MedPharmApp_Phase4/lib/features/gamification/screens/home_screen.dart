
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../assessment/providers/assessment_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/gamification_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final assessmentProvider = context.read<AssessmentProvider>();

    final studyId = authProvider.currentUser?.studyId;
    if (studyId != null) {
      await gamificationProvider.loadUserStats(studyId);
      await assessmentProvider.loadTodayAssessment(studyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedPharm Study'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
             
              _buildLevelCard(),
              const SizedBox(height: 16),

              
              _buildStreakCard(),
              const SizedBox(height: 16),

              
              _buildAssessmentCard(),
              const SizedBox(height: 16),

              
              _buildRecentBadgesSection(),
              const SizedBox(height: 16),

            
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      
                      '${provider.currentLevel}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Level ${provider.currentLevel}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                Text(
                
                  '${provider.totalPoints} points',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                Column(
                  children: [
                    LinearProgressIndicator(
                     
                      value: provider.levelProgress,
                      backgroundColor: Colors.grey[300],
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                    
                      '${provider.pointsToNextLevel} points to next level',
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildStreakCard() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        final streak = provider.currentStreak;
        final isActive = streak > 0;

        return Card(
          color: isActive ? Colors.orange.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 48,
                  color: isActive ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak Day Streak',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        isActive
                            ? 'Keep it going! Complete today\'s assessment.'
                            : 'Start a new streak today!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssessmentCard() {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, child) {
        final hasCompletedToday = !provider.canSubmitToday;

        return Card(
          color: hasCompletedToday ? Colors.green.shade50 : Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  hasCompletedToday ? Icons.check_circle : Icons.assignment,
                  size: 48,
                  color: hasCompletedToday ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 12),
                Text(
                  hasCompletedToday
                      ? 'Today\'s Assessment Complete!'
                      : 'Daily Assessment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasCompletedToday
                      ? 'Great job! Come back tomorrow.'
                      : 'Complete your daily pain assessment',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                if (!hasCompletedToday)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/assessment/nrs');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Assessment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentBadgesSection() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        final badges = provider.earnedBadges;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Badges',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/badges');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (badges.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No badges yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Text('Complete assessments to earn badges!'),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length > 5 ? 5 : badges.length,
                  itemBuilder: (context, index) {
                    return _buildBadgeItem(badges[index]);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBadgeItem(BadgeModel badge) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.badgeType.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: 'History',
                onTap: () {
                  Navigator.pushNamed(context, '/assessment/history');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.bar_chart,
                label: 'Progress',
                onTap: () {
                  Navigator.pushNamed(context, '/progress');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.emoji_events,
                label: 'Badges',
                onTap: () {
                  Navigator.pushNamed(context, '/badges');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
