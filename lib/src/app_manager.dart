import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path/path.dart' as path;
import 'models/app_instance.dart';
import 'package_manager.dart';
import 'permission_manager.dart';
import 'utils/data_persistence_service.dart';

/// Manages installed apps - loading, running, and lifecycle
class AppManager {
  final PackageManager _packageManager;
  final PermissionManager _permissionManager;
  
  List<AppInstance> _installedApps = [];
  
  List<AppInstance> get installedApps => [..._installedApps];

  AppManager({
    required PackageManager packageManager,
    required PermissionManager permissionManager,
  })  : _packageManager = packageManager,
        _permissionManager = permissionManager;

  /// Initializes the app manager by loading all installed apps
  Future<void> initialize() async {
    _installedApps = await _loadInstalledAppsFromStorage();
  }
  
  /// Loads installed apps from persistent storage
  Future<List<AppInstance>> _loadInstalledAppsFromStorage() async {
    final packageNames = await DataPersistenceService.getInstalledAppPackageNames();
    final apps = <AppInstance>[];
    
    for (final packageName in packageNames) {
      final appInstanceData = await DataPersistenceService.loadAppInstance(packageName);
      if (appInstanceData != null) {
        final appInstance = AppInstance.fromJson(appInstanceData);
        apps.add(appInstance);
      }
    }
    
    return apps;
  }

  /// Loads all installed apps directly from persistent storage
  Future<List<AppInstance>> loadInstalledApps() async {
    return await _loadInstalledAppsFromStorage();
  }
  
  /// Refreshes the in-memory list of installed apps from persistent storage
  Future<void> refreshInstalledApps() async {
    _installedApps = await _loadInstalledAppsFromStorage();
  }
  
  

  /// Launches an app by package name
  Future<void> launchApp(String packageName) async {
    final appInstance = _installedApps.firstWhere(
      (app) => app.package.packageName == packageName,
      orElse: () => throw Exception('App not found: $packageName'),
    );
    
    // Check permissions before launching
    final missingPermissions = <String>[];
    for (final permission in appInstance.package.permissions) {
      if (!await _permissionManager.isPermissionGranted(packageName, permission.name)) {
        final granted = await _permissionManager.requestPermission(
          packageName: packageName,
          permissionName: permission.name,
          appName: appInstance.package.name,
        );
        
        if (!granted) {
          missingPermissions.add(permission.name);
        } else {
          await _permissionManager.grantPermission(
            packageName: packageName,
            permissionName: permission.name,
          );
        }
      }
    }
    
    if (missingPermissions.isNotEmpty) {
      // Handle missing permissions - show error or deny launch
      throw Exception(
        'App cannot run without granted permissions: ${missingPermissions.join(', ')}',
      );
    }
    
    // Load and run the app
    await _runApp(appInstance);
  }

  /// Runs an app instance
  Future<void> _runApp(AppInstance appInstance) async {
    // Load the app's interface definition
    final interfacePath = _packageManager.getAppResourcePath(
      appInstance.package.packageName,
      appInstance.package.interfacePath,
    );
    
    final interfaceContent = await Future.value('');
    // In a real implementation, we would read the XML interface file
    // and convert it to Flutter widgets
    
    // For now, we'll simulate launching with a placeholder screen
    runApp(
      MaterialApp(
        title: appInstance.package.name,
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(appInstance.package.name),
              backgroundColor: Colors.blue,
            ),
            body: _buildAppPlaceholder(context, appInstance),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppPlaceholder(BuildContext context, AppInstance appInstance) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps,
            size: 80,
            color: Colors.blue[300],
          ),
          const SizedBox(height: 24),
          Text(
            'App: ${appInstance.package.name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Version: ${appInstance.package.version}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'This is where the app UI would be rendered\n(parsed from XML + Dart code)',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Go back to container home
              Navigator.of(context).pop();
            },
            child: const Text('Back to Container'),
          ),
        ],
      ),
    );
  }

  /// Parses an XML interface file into Flutter widgets
  /// This is a simplified implementation - a full implementation would be more complex
  Widget _parseXmlInterface(String xmlContent) {
    try {
      final document = xml.XmlDocument.parse(xmlContent);
      final rootElement = document.rootElement;
      
      return _convertXmlElementToWidget(rootElement);
    } catch (e) {
      // If XML parsing fails, return an error widget
      return const Center(
        child: Text('Error loading app interface'),
      );
    }
  }

  /// Converts an XML element to a Flutter widget
  Widget _convertXmlElementToWidget(xml.XmlElement element) {
    switch (element.name.local) {
      case 'container':
        return Container(
          child: _buildChildren(element),
          padding: const EdgeInsets.all(16),
        );
      case 'column':
        return Column(
          children: element.children
              .whereType<xml.XmlElement>()
              .map(_convertXmlElementToWidget)
              .toList(),
        );
      case 'row':
        return Row(
          children: element.children
              .whereType<xml.XmlElement>()
              .map(_convertXmlElementToWidget)
              .toList(),
        );
      case 'text':
        return Text(element.text ?? '');
      case 'button':
        return ElevatedButton(
          onPressed: () {
            // Handle button press
          },
          child: Text(element.text ?? 'Button'),
        );
      case 'image':
        final imagePath = element.getAttribute('src') ?? '';
        // In a real implementation, we'd load the image from the app's resources
        return Image.asset(imagePath);
      default:
        return Container(
          child: Text('Unknown element: ${element.name.local}'),
        );
    }
  }

  /// Builds children of an XML element
  Widget _buildChildren(xml.XmlElement element) {
    final children = element.children
        .whereType<xml.XmlElement>()
        .map(_convertXmlElementToWidget)
        .toList();
    
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(children: children);
  }

  /// Uninstalls an app
  Future<void> uninstallApp(String packageName) async {
    // Remove from in-memory list
    _installedApps.removeWhere((app) => app.package.packageName == packageName);
    
    // In a real implementation, this would also:
    // 1. Remove the app's directory
    // 2. Remove permissions associated with the app
    // 3. Clean up any other app-specific data
  }

  /// Adds an app instance to the installed apps list and persists it
  Future<void> addInstalledApp(AppInstance appInstance) async {
    _installedApps.add(appInstance);
    
    // Persist to storage
    await DataPersistenceService.saveAppInstance(
      appInstance.package.packageName,
      appInstance.toJson(),
    );
  }
}