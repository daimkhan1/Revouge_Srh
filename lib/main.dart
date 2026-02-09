// Location: lib/main.dart
import 'package:flutter/material.dart';
// We don't strictly need Provider yet because we used the 'globalCart' singleton,
// but we keep the import for future expansion.
import 'package:provider/provider.dart';

// 1. IMPORT YOUR SCREENS
import 'screens/return_portal.dart'; // (Partner's Code: Handles Login & Selling)
import 'screens/home_screen.dart';   // (Your Code: Buying Interface)

void main() {
  runApp(const RevougeApp());
}

class RevougeApp extends StatelessWidget {
  const RevougeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We use MultiProvider to prepare for future state management features
    return MultiProvider(
      providers: [
        // Placeholder for future global state
        Provider(create: (_) => 'App Config'),
      ],
      child: MaterialApp(
        title: 'Revouge',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F9AAE),
          ),
          // CRITICAL: Make background transparent so the photo shows through
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),

        // -----------------------------------------------------------
        // 2. GLOBAL BACKGROUND IMAGE BUILDER
        // This puts the photo behind EVERY screen in the app.
        // -----------------------------------------------------------
        builder: (context, child) {
          return Stack(
            children: [
              // The Image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    // IF YOU CHANGED THE PHOTO NAME, UPDATE IT HERE:
                    image: const AssetImage('assets/Revouge.jpg'),
                    fit: BoxFit.cover,
                    // Add a white fade so text is readable
                    colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.9),
                        BlendMode.lighten
                    ),
                  ),
                ),
              ),
              // The App Content
              if (child != null) child,
            ],
          );
        },

        // -----------------------------------------------------------
        // 3. INTEGRATION LOGIC
        // We start with ReturnPortalApp because it contains the Login Screen.
        // -----------------------------------------------------------
        home: const ReturnPortalApp(),

        // Define routes for easy navigation
        routes: {
          '/buying/home': (context) => const HomeScreen(),
          '/selling/portal': (context) => const ReturnPortalApp(),
        },
      ),
    );
  }
}
