import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/house_list_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase can't start (e.g. bad config), don't crash - show a message.
    initError = e.toString();
  }
  runApp(QuotingApp(initError: initError));
}

class QuotingApp extends StatelessWidget {
  const QuotingApp({super.key, this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interior Design Quoting',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // House list is the first screen the user sees, unless Firebase failed.
      home: initError == null
          ? const HouseListScreen()
          : _StartupError(message: initError!),
    );
  }
}

/// Shown when Firebase fails to initialise so the marker sees a clear message
/// instead of a blank screen.
class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              const Text(
                "Couldn't connect to Firebase.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
