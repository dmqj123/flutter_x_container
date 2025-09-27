import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Handles persistent data storage for the FlutterX Container
class DataPersistenceService {
  /// Gets the directory where app data is stored
  static Future<Directory> getAppsDirectory() async {
    // Use a platform-specific persistent directory
    String persistentPath = await _getPersistentPath();
    final appsDir = Directory(path.join(persistentPath, 'flutterx_apps'));
    if (!await appsDir.exists()) {
      await appsDir.create(recursive: true);
    }
    return appsDir;
  }

  /// Gets the directory where app packages are stored
  static Future<Directory> getPackagesDirectory() async {
    // Use a platform-specific persistent directory
    String persistentPath = await _getPersistentPath();
    final packagesDir = Directory(path.join(persistentPath, 'flutterx_packages'));
    if (!await packagesDir.exists()) {
      await packagesDir.create(recursive: true);
    }
    return packagesDir;
  }
  
  /// Helper to get a persistent path that works in all environments
  static Future<String> _getPersistentPath() async {
    // On Windows, use APPDATA directory
    if (Platform.isWindows) {
      String? appData = Platform.environment['APPDATA'];
      if (appData != null) {
        String appDirPath = path.join(appData, 'FlutterXContainer');
        Directory appDir = Directory(appDirPath);
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDirPath;
      }
    }
    // On macOS, use Application Support
    else if (Platform.isMacOS) {
      String? home = Platform.environment['HOME'];
      if (home != null) {
        String appDirPath = path.join(home, 'Library', 'Application Support', 'FlutterXContainer');
        Directory appDir = Directory(appDirPath);
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDirPath;
      }
    }
    // On Linux, use .config directory
    else if (Platform.isLinux) {
      String? home = Platform.environment['HOME'];
      if (home != null) {
        String appDirPath = path.join(home, '.config', 'flutterx');
        Directory appDir = Directory(appDirPath);
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDirPath;
      }
    }
    
    // Fallback: try to use a subdirectory in the user's home directory
    String? home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      String appDirPath = path.join(home, '.flutterx_container');
      Directory appDir = Directory(appDirPath);
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDirPath;
    }
    
    // Last resort: try to create in a predictable location
    try {
      String fallbackPath = path.join(Directory.systemTemp.path, 'flutterx_persistent');
      Directory fallbackDir = Directory(fallbackPath);
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackPath;
    } catch (e) {
      // If everything fails, return a temporary location (though not ideal)
      String tempPath = await Directory.systemTemp.createTemp('flutterx_persistent_').then((dir) => dir.path);
      return tempPath;
    }
  }

  /// Saves an app instance to persistent storage
  static Future<void> saveAppInstance(String packageName, Map<String, dynamic> appInstanceData) async {
    final appsDir = await getAppsDirectory();
    final appDir = Directory(path.join(appsDir.path, packageName));
    
    // Create the app directory if it doesn't exist
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    // Save the app instance data
    final appInstanceFile = File(path.join(appDir.path, 'app_instance.json'));
    await appInstanceFile.writeAsString(json.encode(appInstanceData));
  }

  /// Loads an app instance from persistent storage
  static Future<Map<String, dynamic>?> loadAppInstance(String packageName) async {
    final appsDir = await getAppsDirectory();
    final appDir = Directory(path.join(appsDir.path, packageName));
    
    if (!await appDir.exists()) {
      return null;
    }
    
    final appInstanceFile = File(path.join(appDir.path, 'app_instance.json'));
    if (!await appInstanceFile.exists()) {
      return null;
    }
    
    final content = await appInstanceFile.readAsString();
    return json.decode(content) as Map<String, dynamic>;
  }

  /// Deletes an app instance from persistent storage
  static Future<void> deleteAppInstance(String packageName) async {
    final appsDir = await getAppsDirectory();
    final appDir = Directory(path.join(appsDir.path, packageName));
    
    if (await appDir.exists()) {
      await appDir.delete(recursive: true);
    }
  }

  /// Gets all installed app package names
  static Future<List<String>> getInstalledAppPackageNames() async {
    final appsDir = await getAppsDirectory();
    if (!await appsDir.exists()) {
      return [];
    }
    
    final packages = <String>[];
    
    await for (final entity in appsDir.list()) {
      if (entity is Directory) {
        packages.add(path.basename(entity.path));
      }
    }
    
    return packages;
  }

  /// Saves permissions for an app
  static Future<void> saveAppPermissions(String packageName, Map<String, bool> permissions) async {
    final appsDir = await getAppsDirectory();
    final appDir = Directory(path.join(appsDir.path, packageName));
    
    // Create the app directory if it doesn't exist
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    // Save the permissions data
    final permissionsFile = File(path.join(appDir.path, 'permissions.json'));
    await permissionsFile.writeAsString(json.encode(permissions));
  }

  /// Loads permissions for an app
  static Future<Map<String, bool>> loadAppPermissions(String packageName) async {
    final appsDir = await getAppsDirectory();
    final appDir = Directory(path.join(appsDir.path, packageName));
    
    if (!await appDir.exists()) {
      return {};
    }
    
    final permissionsFile = File(path.join(appDir.path, 'permissions.json'));
    if (!await permissionsFile.exists()) {
      return {};
    }
    
    final content = await permissionsFile.readAsString();
    final jsonMap = json.decode(content) as Map<String, dynamic>;
    
    // Convert values to bool
    final permissions = <String, bool>{};
    for (final entry in jsonMap.entries) {
      permissions[entry.key] = entry.value as bool;
    }
    
    return permissions;
  }
  
  /// Clears all persistent data
  static Future<void> clearAllData() async {
    // Get both apps and packages directories
    final appsDir = await getAppsDirectory();
    final packagesDir = await getPackagesDirectory();
    
    // Delete the apps directory and all its contents
    if (await appsDir.exists()) {
      await appsDir.delete(recursive: true);
    }
    
    // Delete the packages directory and all its contents
    if (await packagesDir.exists()) {
      await packagesDir.delete(recursive: true);
    }
  }
}