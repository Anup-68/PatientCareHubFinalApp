import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Patients_Screens/SettingScreen.dart';
import 'package:patientcarehub/USER_Regestration/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://vwluqbuocpmawrcnmlsf.supabase.co',
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3bHVxYnVvY3BtYXdyY25tbHNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyMTAxMDksImV4cCI6MjA1NDc4NjEwOX0.80oRvX9XIY2s3tyYzzMBRRf265kNQ3n4gQZAxejwEdk",
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Use global navigator key
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const WelcomeScreen(),
      title: "FlutterApp",
    );
  }
}
