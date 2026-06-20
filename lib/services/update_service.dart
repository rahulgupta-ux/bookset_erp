import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
final bool updateAvailable;
final String currentVersion;
final String latestVersion;
final String updateMessage;
final String downloadUrl;
final bool forceUpdate;

UpdateInfo({
required this.updateAvailable,
required this.currentVersion,
required this.latestVersion,
required this.updateMessage,
required this.downloadUrl,
required this.forceUpdate,
});
}

class UpdateService {
static Future<UpdateInfo> checkForUpdate() async {
try {
final packageInfo = await PackageInfo.fromPlatform();


  final currentVersion = packageInfo.version;

  final doc = await FirebaseFirestore.instance
      .collection('system')
      .doc('app_config')
      .get();

  if (!doc.exists) {
    return UpdateInfo(
      updateAvailable: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      updateMessage: '',
      downloadUrl: '',
      forceUpdate: false,
    );
  }

  final data = doc.data()!;

  final latestVersion =
      data['latestVersion']?.toString() ?? currentVersion;

  final updateMessage =
      data['updateMessage']?.toString() ?? '';

  final downloadUrl =
      data['downloadUrl']?.toString() ?? '';

  final forceUpdate =
      data['forceUpdate'] ?? false;

  return UpdateInfo(
    updateAvailable:
        currentVersion != latestVersion,
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    updateMessage: updateMessage,
    downloadUrl: downloadUrl,
    forceUpdate: forceUpdate,
  );
} catch (e) {
  return UpdateInfo(
    updateAvailable: false,
    currentVersion: 'Unknown',
    latestVersion: 'Unknown',
    updateMessage: '',
    downloadUrl: '',
    forceUpdate: false,
  );
}


}
}
