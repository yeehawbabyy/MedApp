
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _consentChecked = false;

  Future<void> _handleAcceptConsent() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.acceptConsent();

    if (authProvider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consent accepted! Welcome to the study.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informed Consent'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Trial Informed Consent',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to the MedPharm Pain Assessment Study.\n\n'
                        'This app will collect daily pain assessments to help evaluate '
                        'the effectiveness of Painkiller Forte medication.\n\n'
                        'Your participation is voluntary and you may withdraw at any time.\n\n'
                        'Data collected:\n'
                        '• Daily pain scores\n'
                        '• Assessment completion times\n'
                        '• App usage patterns\n\n'
                        'Your data will be:\n'
                        '• Encrypted and stored securely\n'
                        '• Used only for this research study\n'
                        '• Anonymized in all reports\n\n'
                        'By accepting, you confirm that:\n'
                        '• You have read and understood this consent form\n'
                        '• You agree to participate in this study\n'
                        '• You understand your data will be collected\n\n'
                        'For questions, contact: study@medpharm.com',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Checkbox(
                    value: _consentChecked,
                    onChanged: (value) {
                      setState(() {
                        _consentChecked = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'I have read and accept the consent form',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _consentChecked ? _handleAcceptConsent : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('I Accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
