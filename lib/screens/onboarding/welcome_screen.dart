import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Benvenuto in PhotoAI Catalog',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Catalogazione intelligente delle foto con IA. Seleziona la tua professione per iniziare.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/profession_picker'),
                child: const Text('Scegli professione'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
