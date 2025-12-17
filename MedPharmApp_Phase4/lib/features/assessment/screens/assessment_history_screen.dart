
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import '../models/assessment_model.dart';
import '../../authentication/providers/auth_provider.dart';

class AssessmentHistoryScreen extends StatefulWidget {
  const AssessmentHistoryScreen({super.key});

  @override
  State<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {

  @override
  void initState() {
    super.initState();
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final authProvider = context.read<AuthProvider>();
    final assessmentProvider = context.read<AssessmentProvider>();

    final studyId = authProvider.currentUser?.studyId;
    if (studyId != null) {
      await assessmentProvider.refreshAssessments(studyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Assessment History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),

      
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
         
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

       
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadHistory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

         
          if (provider.assessmentHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No assessments yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete your first assessment to see it here',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/assessment/nrs');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Assessment'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.assessmentHistory.length,
              itemBuilder: (context, index) {
                final assessment = provider.assessmentHistory[index];
                return _AssessmentCard(assessment: assessment);
              },
            ),
          );
        },
      ),

  
      floatingActionButton: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          if (!provider.canSubmitToday) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/assessment/nrs');
            },
            icon: const Icon(Icons.add),
            label: const Text('New Assessment'),
          );
        },
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final AssessmentModel assessment;

  const _AssessmentCard({required this.assessment});

  Color _getPainColor() {
    final score = assessment.nrsScore;
    if (score == 0) return Colors.green;
    if (score <= 3) return Colors.lightGreen;
    if (score <= 6) return Colors.orange;
    if (score <= 9) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getPainColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getPainColor(), width: 2),
          ),
          child: Center(
            child: Text(
              assessment.nrsScore.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getPainColor(),
              ),
            ),
          ),
        ),
        title: Text(
          assessment.painLevelDescription,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('NRS: ${assessment.nrsScore}/10'),
            Text('VAS: ${assessment.vasScore}/100'),
            const SizedBox(height: 4),
            Text(
              '${assessment.formattedDate} at ${assessment.formattedTime}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: assessment.isTodayAssessment
            ? Chip(
                label: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue.shade100,
              )
            : null,
      ),
    );
  }
}


