import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/profession_picker_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/ai_provider.dart';
import 'providers/profile_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // All'avvio inizializziamo in background la chiave IA (se presente).
    ref.watch(initGeminiKeyProvider);

    return MaterialApp(
      title: 'PhotoAI Catalog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Decidiamo la prima schermata in base all'onboarding:
      // - se non completato -> Welcome
      // - se completato -> Home
      home: _StartupRouter(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/profession_picker': (context) => const ProfessionPickerScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

/// Piccolo widget che decide quale schermata mostrare per prima.
class _StartupRouter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingDoneProvider);

    return onboardingAsync.when(
      data: (done) => done ? const HomeScreen() : const WelcomeScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const WelcomeScreen(),
    );
  }
}
