import 'models/permission.dart';
import 'utils/data_persistence_service.dart';

/// Manages app permissions - validation, granting, and checking
class PermissionManager {
  /// List of all supported permissions in the system
  static final List<Permission> _supportedPermissions = [
    // Normal permissions
    Permission(
      name: 'basic_functionality',
      level: PermissionLevel.normal,
      description: 'Basic app functionality',
    ),
    Permission(
      name: 'camera',
      level: PermissionLevel.normal,
      description: 'Access camera to take photos',
    ),
    Permission(
      name: 'location',
      level: PermissionLevel.normal,
      description: 'Access device location',
    ),
    Permission(
      name: 'storage_read',
      level: PermissionLevel.normal,
      description: 'Read files from device storage',
    ),
    Permission(
      name: 'storage_write',
      level: PermissionLevel.normal,
      description: 'Write files to device storage',
    ),
    Permission(
      name: 'microphone',
      level: PermissionLevel.normal,
      description: 'Access microphone for audio recording',
    ),
    Permission(
      name: 'nfc',
      level: PermissionLevel.normal,
      description: 'Access NFC functionality',
    ),
    Permission(
      name: 'bluetooth',
      level: PermissionLevel.normal,
      description: 'Access Bluetooth functionality',
    ),
    
    // Administrator permissions
    Permission(
      name: 'system_settings',
      level: PermissionLevel.administrator,
      description: 'Change system settings',
    ),
    Permission(
      name: 'device_admin',
      level: PermissionLevel.administrator,
      description: 'Perform device administration tasks',
    ),
    Permission(
      name: 'window_management',
      level: PermissionLevel.administrator,
      description: 'Manage window properties (desktop)',
    ),
    Permission(
      name: 'mouse_position',
      level: PermissionLevel.administrator,
      description: 'Access mouse position (desktop)',
    ),
  ];

  /// Checks if a permission name is valid in the system
  bool isValidPermission(String permissionName) {
    return _supportedPermissions.any((permission) => permission.name == permissionName);
  }

  /// Gets a permission by name
  Permission? getPermissionByName(String name) {
    for (final permission in _supportedPermissions) {
      if (permission.name == name) {
        return permission;
      }
    }
    return null;
  }

  /// Checks if an app has been granted a specific permission
  Future<bool> isPermissionGranted(
    String packageName,
    String permissionName,
  ) async {
    final permissions = await DataPersistenceService.loadAppPermissions(packageName);
    return permissions[permissionName] ?? false;
  }

  /// Requests permission for an app
  /// Returns true if granted, false if denied
  Future<bool> requestPermission({
    required String packageName,
    required String permissionName,
    required String appName,
  }) async {
    // Check if the app is a system app, and if so, auto-grant system permissions
    // This is a simplified approach for development purposes
    try {
      // Load the app package to check if it's a system app
      // For this implementation, we'll check if it's a known system permission and the app is a system app
      final permission = getPermissionByName(permissionName);
      if (permission != null && permission.level == PermissionLevel.administrator) {
        // For system-level permissions, check if the app requesting is a system app
        // In a real implementation, we would check the app's manifest or certificates to verify
        // For development, we'll auto-grant system permissions for system apps
        // Since we don't have a direct way to check if an app is a system app here,
        // we'll implement a workaround in the app manager
      }
      
      // In a real implementation, this would show a permission request UI
      // For development purposes, we'll return true to allow the app to run
      return true;
    } catch (e) {
      // If there's any error, return false
      return false;
    }
  }

  /// Grants a permission to an app
  Future<void> grantPermission({
    required String packageName,
    required String permissionName,
  }) async {
    // Load existing permissions
    final permissions = await DataPersistenceService.loadAppPermissions(packageName);
    
    // Update the permission
    permissions[permissionName] = true;
    
    // Save back to storage
    await DataPersistenceService.saveAppPermissions(packageName, permissions);
  }

  /// Revokes a permission from an app
  Future<void> revokePermission({
    required String packageName,
    required String permissionName,
  }) async {
    // Load existing permissions
    final permissions = await DataPersistenceService.loadAppPermissions(packageName);
    
    // Update the permission
    permissions[permissionName] = false;
    
    // Save back to storage
    await DataPersistenceService.saveAppPermissions(packageName, permissions);
  }

  /// Gets all supported permissions
  List<Permission> getSupportedPermissions() {
    return [..._supportedPermissions];
  }

  /// Gets permissions for a specific app
  Future<Map<String, bool>> getAppPermissions(String packageName) async {
    return await DataPersistenceService.loadAppPermissions(packageName);
  }
}