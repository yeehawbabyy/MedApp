
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {

  final TextEditingController _codeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleEnrollment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    await authProvider.enrollUser(_codeController.text);

    if (authProvider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/consent');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Welcome to MedPharm'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                Text(
                  'Pain Assessment Study',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Please enter your enrollment code provided by your doctor',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Code',
                    hintText: 'e.g., ABC12345',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    context.read<AuthProvider>().updateEnrollmentCode(value);
                  },

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an enrollment code';
                    }
                    if (value.length < 8 || value.length > 12) {
                      return 'Code must be 8-12 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Consumer<AuthProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return ElevatedButton(
                      onPressed: _handleEnrollment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'Enroll in Study',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

               
                Consumer<AuthProvider>(
                  builder: (context, provider, child) {
                    if (provider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
