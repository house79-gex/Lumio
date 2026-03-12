import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cloud/google_drive_provider.dart';

final googleDriveProvider = Provider<GoogleDriveProvider>((ref) => GoogleDriveProvider());

class CloudSettingsScreen extends ConsumerStatefulWidget {
  const CloudSettingsScreen({super.key});

  @override
  ConsumerState<CloudSettingsScreen> createState() => _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends ConsumerState<CloudSettingsScreen> {
  bool _driveAuthLoading = false;
  bool? _driveAuthenticated;

  Future<void> _toggleGoogleDrive() async {
    final drive = ref.read(googleDriveProvider);
    if (_driveAuthenticated == true) {
      await drive.signOut();
      if (!mounted) return;
      setState(() => _driveAuthenticated = false);
      return;
    }
    setState(() => _driveAuthLoading = true);
    try {
      final ok = await drive.authenticate();
      if (mounted) setState(() {
        _driveAuthenticated = ok;
        _driveAuthLoading = false;
      });
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive connesso. Il backup userà questo account.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _driveAuthLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkDriveAuth();
  }

  Future<void> _checkDriveAuth() async {
    final ok = await ref.read(googleDriveProvider).isAuthenticated;
    if (!mounted) return;
    setState(() => _driveAuthenticated = ok);
  }

  @override
  Widget build(BuildContext context) {
    final driveConnected = _driveAuthenticated == true;
    final loading = _driveAuthLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup cloud')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Provider',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Text('📁', style: TextStyle(fontSize: 28)),
            title: const Text('Google Drive'),
            subtitle: Text(
              loading ? 'Accesso in corso...' : (driveConnected ? 'Connesso' : 'Non configurato'),
            ),
            trailing: loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(driveConnected ? Icons.check_circle : Icons.link_off),
            onTap: loading ? null : _toggleGoogleDrive,
          ),
          ListTile(
            leading: const Text('📦', style: TextStyle(fontSize: 28)),
            title: const Text('Dropbox'),
            subtitle: const Text('Non configurato'),
            onTap: () {},
          ),
          ListTile(
            leading: const Text('☁️', style: TextStyle(fontSize: 28)),
            title: const Text('OneDrive'),
            subtitle: const Text('Non configurato'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'Collega Google Drive per abilitare il backup delle cartelle PhotoAI. La sincronizzazione può avvenire anche in background.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
