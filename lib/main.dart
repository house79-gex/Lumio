import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Task in background: in futuro qui si può avviare CloudSyncService
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    'photoai-sync',
    'cloudSync',
    frequency: const Duration(hours: 1),
  );
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
