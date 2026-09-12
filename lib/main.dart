import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart';
import 'ui/screens/trip_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  runApp(const RiderTrackingApp());
}

class RiderTrackingApp extends StatelessWidget {
  const RiderTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripProvider()..init(),
      child: MaterialApp(
        title: 'Rider Tracking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF111827),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF111827),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF111827),
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0,
          ),
        ),
        home: const TripScreen(),
      ),
    );
  }
}
