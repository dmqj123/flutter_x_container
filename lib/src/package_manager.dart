import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_x_container/flutterx_container.dart';
import 'package:path/path.dart' as path;
import 'models/app_package.dart';
import 'models/app_instance.dart';
import 'permission_manager.dart';
import 'utils/data_persistence_service.dart';

/// Manages app packages - installation, extraction, and validation
class PackageManager {
  final PermissionManager _permissionManager;
  
  // Directory where app packages are stored
  static const String _packagesDir = 'packages';
  
  PackageManager({required PermissionManager permissionManager})
      : _permissionManager = permissionManager;

  /// Installs an app from a package file (.fxc)
  /// 从包文件安装应用（.fxc）
  Future<AppInstance> installApp(String packagePath) async {
    try {
      // 解压包文件到临时目录
      final extractedPath = await _extractPackage(packagePath);
      
      // 检查并读取 manifest.json
      final manifestPath = path.join(extractedPath, 'manifest.json');
      if (!await File(manifestPath).exists()) {
        throw Exception('Package does not contain manifest.json');
      }
      
      final manifestContent = await File(manifestPath).readAsString();
      final manifestJson = json.decode(manifestContent) as Map<String, dynamic>;
      
      // 构建 AppPackage 实例
      final appPackage = AppPackage(
        packageName: manifestJson['packageName'] ?? '',
        name: manifestJson['name'] ?? '',
        version: manifestJson['version'] ?? '1.0.0',
        iconPath: manifestJson['iconPath'] ?? '',
        permissions: (manifestJson['permissions'] as List?)
                ?.map((e) => Permission.fromJson(e))
                .toList() ?? [],
        interfacePath: manifestJson['interfacePath'] ?? '',
        codePath: manifestJson['codePath'] ?? '',
        packagePath: packagePath, // 使用原始包路径
        isSystemApp: manifestJson['isSystemApp'] ?? false,
      );
      
      // 校验包内必须文件是否存在
      await _validatePackageFiles(extractedPath, appPackage);
      
      // 获取应用包存储目录并移动解压内容
      final packagesDir = await _getPackagesDirectory();
      final appDir = Directory(path.join(packagesDir.path, appPackage.packageName));
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }
      await _moveDirectory(Directory(extractedPath), appDir);
      
      // Create app instance
      final appInstance = AppInstance(
        package: appPackage,
        installTime: DateTime.now(),
        grantedPermissions: <String, bool>{},
      );
      
      // For system apps, automatically grant all their requested permissions
      if (appPackage.isSystemApp) {
        for (final permission in appPackage.permissions) {
          appInstance.grantedPermissions[permission.name] = true;
        }
      }
      
      // Save the app instance to storage
      await _saveAppInstance(appInstance, appDir.path);
      
      return appInstance;
    } catch (e) {
      rethrow;
    }
  }

  /// Extracts the package file to a temporary directory
  Future<String> _extractPackage(String packagePath) async {
    final packageFile = File(packagePath);
    if (!await packageFile.exists()) {
      throw Exception('Package file does not exist: $packagePath');
    }
    
    // Read the package file
    final bytes = await packageFile.readAsBytes();
    
    // Decode the archive
    final archive = ZipDecoder().decodeBytes(bytes);
    
    // Create a temporary directory for extraction
    final extractedDir = Directory(
      path.join(Directory.systemTemp.path, 'flutterx_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await extractedDir.create();
    
    // Extract all files
    for (final file in archive) {
      final filename = file.name;
      final filePath = path.join(extractedDir.path, filename);
      
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File(filePath);
        
        // Create parent directories if they don't exist
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else {
        // Create directory
        await Directory(filePath).create(recursive: true);
      }
    }
    
    return extractedDir.path;
  }

  /// Validates that all required files exist in the package
  Future<void> _validatePackageFiles(String extractedPath, AppPackage package) async {
    // Check if the interface file exists
    final interfaceFile = File(path.join(extractedPath, package.interfacePath));
    if (!await interfaceFile.exists()) {
      throw Exception('Interface file does not exist: ${package.interfacePath}');
    }
    
    // Check if the code file exists
    final codeFile = File(path.join(extractedPath, package.codePath));
    if (!await codeFile.exists()) {
      throw Exception('Code file does not exist: ${package.codePath}');
    }
    
    // Check if the icon file exists
    final iconFile = File(path.join(extractedPath, package.iconPath));
    if (!await iconFile.exists()) {
      throw Exception('Icon file does not exist: ${package.iconPath}');
    }
    
    // Validate permissions against the system permissions
    for (final permission in package.permissions) {
      if (!_permissionManager.isValidPermission(permission.name)) {
        throw Exception('Invalid permission requested: ${permission.name}');
      }
    }
  }

  /// Saves an app instance to persistent storage
  Future<void> _saveAppInstance(AppInstance appInstance, String appDirPath) async {
    // Save the app instance data using the data persistence service
    await DataPersistenceService.saveAppInstance(
      appInstance.package.packageName,
      appInstance.toJson(),
    );
  }
  
  /// Gets the packages directory
  Future<Directory> _getPackagesDirectory() async {
    return await DataPersistenceService.getPackagesDirectory();
  }

  /// Loads an installed app package
  Future<AppPackage> loadAppPackage(String packageName) async {
    final appDir = Directory(path.join(_packagesDir, packageName));
    if (!await appDir.exists()) {
      throw Exception('App not installed: $packageName');
    }
    
    final manifestFile = File(path.join(appDir.path, 'manifest.json'));
    if (!await manifestFile.exists()) {
      throw Exception('App manifest not found for: $packageName');
    }
    
    final manifestContent = await manifestFile.readAsString();
    final manifestJson = json.decode(manifestContent) as Map<String, dynamic>;
    
    return AppPackage.fromJson(manifestJson);
  }

  /// Gets the path to an app's resource file
  String getAppResourcePath(String packageName, String resourcePath) {
    return path.join(_packagesDir, packageName, resourcePath);
  }

  /// Moves a directory and its contents to a new location
  Future<void> _moveDirectory(Directory source, Directory destination) async {
    if (!await source.exists()) {
      throw Exception('Source directory does not exist: ${source.path}');
    }
    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);

    await for (var entity in source.list(recursive: false)) {
      final newPath = path.join(destination.path, path.basename(entity.path));
      if (entity is File) {
        await entity.copy(newPath);
        await entity.delete();
      } else if (entity is Directory) {
        await _moveDirectory(entity, Directory(newPath));
      }
    }
    await source.delete(recursive: true);
  }
}