import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Standalone app to get and display the app signature hash
/// Run this with: flutter run -t lib/get_app_hash.dart
void main() {
  runApp(const GetAppHashApp());
}

class GetAppHashApp extends StatelessWidget {
  const GetAppHashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Get App Hash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GetAppHashScreen(),
    );
  }
}

class GetAppHashScreen extends StatefulWidget {
  const GetAppHashScreen({super.key});

  @override
  State<GetAppHashScreen> createState() => _GetAppHashScreenState();
}

class _GetAppHashScreenState extends State<GetAppHashScreen> {
  String? _appHash;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getAppHash();
  }

  Future<void> _getAppHash() async {
    setState(() {
      _loading = true;
    });

    try {
      final signature = await SmsAutoFill().getAppSignature;
      setState(() {
        _appHash = signature;
        _loading = false;
      });

      // Print to console
      print('═══════════════════════════════════════');
      print('🔑 App Signature Hash: $signature');
      print('═══════════════════════════════════════');
      print('📋 Add this to your backend .env file:');
      print('PASSENGER_APP_HASH=$signature');
      print('═══════════════════════════════════════');
    } catch (e) {
      setState(() {
        _appHash = 'Error: $e';
        _loading = false;
      });
      print('❌ Error getting app signature: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger App - SMS Hash'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.key, size: 80, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'App Signature Hash',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _appHash ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Add this to your backend .env file:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        'PASSENGER_APP_HASH=${_appHash ?? ""}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _getAppHash,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
