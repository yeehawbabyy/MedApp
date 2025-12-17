
import 'package:flutter/material.dart';


class NrsAssessmentScreen extends StatefulWidget {
  const NrsAssessmentScreen({super.key});

  @override
  State<NrsAssessmentScreen> createState() => _NrsAssessmentScreenState();
}

class _NrsAssessmentScreenState extends State<NrsAssessmentScreen> {
  
  double _nrsScore = 5.0; 

 
  void _handleNext() {
    final nrsScore = _nrsScore.round();
    Navigator.pushNamed(
      context,
      '/assessment/vas',
      arguments: {'nrsScore': nrsScore},
    );
  }

  Color _getPainColor() {
    final score = _nrsScore.round();
    if (score == 0) return Colors.green;
    if (score <= 3) return Colors.lightGreen;
    if (score <= 6) return Colors.orange;
    if (score <= 9) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPainDescription() {
    final score = _nrsScore.round();
    if (score == 0) return 'No Pain';
    if (score <= 3) return 'Mild Pain';
    if (score <= 6) return 'Moderate Pain';
    if (score <= 9) return 'Severe Pain';
    return 'Worst Possible Pain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Pain Assessment - NRS'),
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
                'Numerical Rating Scale',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              const Text(
                'On a scale from 0 to 10, how much pain are you experiencing right now?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

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
                      _nrsScore.round().toString(),
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
                value: _nrsScore,
                min: 0,
                max: 10,
                divisions: 10,
                label: _nrsScore.round().toString(),
                activeColor: _getPainColor(),
                onChanged: (value) {
                  setState(() {
                    _nrsScore = value;
                  });
                },
              ),

             
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0\nNo Pain', textAlign: TextAlign.center),
                  Text('10\nWorst Pain', textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _getPainColor(),
                ),
                child: const Text(
                  'Next: Visual Analog Scale',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Step 1 of 2',
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
