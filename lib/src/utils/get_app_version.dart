import 'package:package_info_plus/package_info_plus.dart';

class GetAppVersion {
  static Future<String> get version async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    return version;
  }
}
