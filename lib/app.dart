import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/profession_picker_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/profile_provider.dart';
import 'providers/ai_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(initGeminiKeyProvider); // inizializza chiave API
    final onboardingAsync = ref.watch(onboardingDoneProvider);

    return MaterialApp(
      title: 'PhotoAI Catalog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => onboardingAsync.when(
              data: (done) {
                if (done == true) return const HomeScreen();
                return const WelcomeScreen();
              },
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (e, _) => Scaffold(body: Center(child: Text('Errore: $e'))),
            ),
        '/welcome': (context) => const WelcomeScreen(),
        '/profession_picker': (context) => const ProfessionPickerScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
