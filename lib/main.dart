import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'features/sms_sender/presentation/screens/dashboard_screen.dart';
import 'features/sms_sender/presentation/state/sms_sender_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive offline database
  await Hive.initFlutter();

  // 2. Instantiate state provider
  final provider = SmsSenderProvider();

  runApp(BulkSmsApp(provider: provider));
}

class BulkSmsApp extends StatefulWidget {
  final SmsSenderProvider provider;

  const BulkSmsApp({Key? key, required this.provider}) : super(key: key);

  @override
  State<BulkSmsApp> createState() => _BulkSmsAppState();
}

class _BulkSmsAppState extends State<BulkSmsApp> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  /// Request essential permissions dynamically on startup
  Future<void> _checkAndRequestPermissions() async {
    final statusSms = await Permission.sms.status;
    final statusPhone = await Permission.phone.status;

    if (!statusSms.isGranted || !statusPhone.isGranted) {
      final results = await [
        Permission.sms,
        Permission.phone,
      ].request();

      setState(() {
        _permissionsGranted = 
            results[Permission.sms]?.isGranted == true &&
            results[Permission.phone]?.isGranted == true;
      });
    } else {
      setState(() {
        _permissionsGranted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bulk SMS Sender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.tealAccent,
          background: Color(0xFF0F0C1B),
        ),
      ),
      home: _permissionsGranted
          ? DashboardScreen(provider: widget.provider)
          : _buildPermissionRequestScreen(),
    );
  }

  /// Interactive layout forcing user to accept permissions
  Widget _buildPermissionRequestScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C1B),
              Color(0xFF15102A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 80,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                "Hardware Permissions Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This 100% offline app uses your physical phone SIM card to send text messages. It requires the 'Send SMS' and 'Read Phone State' permissions to function.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkAndRequestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Grant Permissions",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
