import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final doc = await FirebaseFirestore.instance
          .collection('system')
          .doc('app_config')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      final latestVersion = data['latestVersion'] ?? '';
      final downloadUrl = data['downloadUrl'] ?? '';
      final releaseNotes = data['releaseNotes'] ?? '';
      final forceUpdate = data['forceUpdate'] ?? false;

      if (currentVersion != latestVersion) {
        _showUpdateDialog(
          context,
          latestVersion,
          releaseNotes,
          downloadUrl,
          forceUpdate,
        );
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String url,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (_) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: $version'),
            const SizedBox(height: 10),
            Text(notes),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
