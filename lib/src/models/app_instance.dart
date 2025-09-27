import 'app_package.dart';

/// Represents an installed instance of an app
class AppInstance {
  /// The package this instance is based on
  final AppPackage package;
  
  /// Installation timestamp
  final DateTime installTime;
  
  /// Whether the app is currently enabled
  final bool isEnabled;
  
  /// Whether the user has granted permissions to this app
  final Map<String, bool> grantedPermissions;
  
  AppInstance({
    required this.package,
    required this.installTime,
    this.isEnabled = true,
    required this.grantedPermissions,
  });

  /// Create AppInstance from JSON
  factory AppInstance.fromJson(Map<String, dynamic> json) {
    return AppInstance(
      package: AppPackage.fromJson(json['package']),
      installTime: DateTime.parse(json['installTime']),
      isEnabled: json['isEnabled'] ?? true,
      grantedPermissions: Map<String, bool>.from(json['grantedPermissions'] ?? {}),
    );
  }

  /// Convert AppInstance to JSON
  Map<String, dynamic> toJson() {
    return {
      'package': package.toJson(),
      'installTime': installTime.toIso8601String(),
      'isEnabled': isEnabled,
      'grantedPermissions': grantedPermissions,
    };
  }
}