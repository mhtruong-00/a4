import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/house_list_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QuotingApp());
}

class QuotingApp extends StatelessWidget {
  const QuotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interior Design Quoting',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // House list is the first screen the user sees.
      home: const HouseListScreen(),
    );
  }
}
