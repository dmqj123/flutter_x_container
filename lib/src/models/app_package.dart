import 'permission.dart';

/// Represents an app package with its metadata
class AppPackage {
  /// Unique identifier for the app
  final String packageName;
  
  /// Human-readable name of the app
  final String name;
  
  /// Version of the app
  final String version;
  
  /// Path to the app icon
  final String iconPath;
  
  /// List of permissions required by the app
  final List<Permission> permissions;
  
  /// Path to the main XML interface file
  final String interfacePath;
  
  /// Path to the main Dart code file
  final String codePath;
  
  /// Path to the package file
  String packagePath;
  
  /// Whether the app is system-level (has admin privileges)
  final bool isSystemApp;
  
  AppPackage({
    required this.packageName,
    required this.name,
    required this.version,
    required this.iconPath,
    required this.permissions,
    required this.interfacePath,
    required this.codePath,
    required this.packagePath,
    this.isSystemApp = false,
  });

  /// Create AppPackage from JSON
  factory AppPackage.fromJson(Map<String, dynamic> json) {
    return AppPackage(
      packageName: json['packageName'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? '1.0.0',
      iconPath: json['iconPath'] ?? '',
      permissions: (json['permissions'] as List?)
              ?.map((e) => Permission.fromJson(e))
              .toList() ?? [],
      interfacePath: json['interfacePath'] ?? '',
      codePath: json['codePath'] ?? '',
      packagePath: json['packagePath'] ?? '',
      isSystemApp: json['isSystemApp'] ?? false,
    );
  }

  /// Convert AppPackage to JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'name': name,
      'version': version,
      'iconPath': iconPath,
      'permissions': permissions.map((e) => e.toJson()).toList(),
      'interfacePath': interfacePath,
      'codePath': codePath,
      'packagePath': packagePath,
      'isSystemApp': isSystemApp,
    };
  }
}