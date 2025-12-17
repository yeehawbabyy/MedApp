
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/models/gamification_model.dart';


class VasAssessmentScreen extends StatefulWidget {
  const VasAssessmentScreen({super.key});

  @override
  State<VasAssessmentScreen> createState() => _VasAssessmentScreenState();
}

class _VasAssessmentScreenState extends State<VasAssessmentScreen> {
  
  double _vasScore = 50.0; 

  int? _nrsScore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_nrsScore == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      _nrsScore = args?['nrsScore'] as int?;
    }
  }

  Future<void> _handleSubmit() async {
    final authProvider = context.read<AuthProvider>();
    final assessmentProvider = context.read<AssessmentProvider>();

    final studyId = authProvider.currentUser?.studyId;
    if (studyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No user session found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nrsScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: NRS score not provided'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await assessmentProvider.submitAssessment(
      studyId: studyId,
      nrsScore: _nrsScore!,
      vasScore: _vasScore.round(),
    );

    if (assessmentProvider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assessmentProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      
      final gamificationProvider = context.read<GamificationProvider>();
      
      final isEarly = DateTime.now().hour < 9;
      
      await gamificationProvider.recordAssessmentCompletion(
        studyId: studyId,
        isEarly: isEarly,
      );

      if (mounted) {
        final points = gamificationProvider.lastPointsAwarded;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment submitted! +$points points'),
            backgroundColor: Colors.green,
          ),
        );

        if (gamificationProvider.hasNewBadges) {
          await _showBadgeCelebration(gamificationProvider);
        }

        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _showBadgeCelebration(GamificationProvider provider) async {
    final newBadges = provider.newlyEarnedBadges;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('New Badge!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final badge in newBadges) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      badge.badgeType.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.badgeType.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              provider.clearNewBadges();
              Navigator.pop(context);
            },
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  Color _getPainColor() {
    final percentage = _vasScore / 100;
    if (percentage == 0) return Colors.green;
    if (percentage <= 0.3) return Colors.lightGreen;
    if (percentage <= 0.6) return Colors.orange;
    if (percentage <= 0.9) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPainDescription() {
    final percentage = _vasScore / 100;
    if (percentage == 0) return 'No Pain';
    if (percentage <= 0.3) return 'Mild Pain';
    if (percentage <= 0.6) return 'Moderate Pain';
    if (percentage <= 0.9) return 'Severe Pain';
    return 'Worst Possible Pain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      appBar: AppBar(
        title: const Text('Pain Assessment - VAS'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
             
              const Text(
                'Visual Analog Scale',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              const Text(
                'Move the slider to indicate your current pain level.\nThis scale provides more precision than the 0-10 rating.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_nrsScore != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Your NRS score: $_nrsScore/10',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getPainColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getPainColor(),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _vasScore.round().toString(),
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: _getPainColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPainDescription(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: _getPainColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              Slider(
                value: _vasScore,
                min: 0,
                max: 100,
                divisions: 100,
                label: _vasScore.round().toString(),
                activeColor: _getPainColor(),
                onChanged: (value) {
                  setState(() {
                    _vasScore = value;
                  });
                },
              ),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0\nNo Pain', textAlign: TextAlign.center),
                  Text('100\nWorst Pain', textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(height: 48),

            
              Consumer<AssessmentProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _getPainColor(),
                    ),
                    child: const Text(
                      'Submit Assessment',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Step 2 of 2',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
