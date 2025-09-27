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
  Future<AppInstance> launchApp(String packageName) async {
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
    
    // Return the app instance so the UI can handle the navigation
    return appInstance;
  }

  /// Gets the resource path for an app file
  Future<String> getAppResourcePath(String packageName, String resourcePath) async {
    final packagesDir = await DataPersistenceService.getPackagesDirectory();
    return path.join(packagesDir.path, packageName, resourcePath);
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
          padding: _parseEdgeInsets(element.getAttribute('padding')),
          margin: _parseEdgeInsets(element.getAttribute('margin')),
          width: _parseDouble(element.getAttribute('width')),
          height: _parseDouble(element.getAttribute('height')),
          color: _parseColor(element.getAttribute('color')),
        );
      case 'column':
        return Column(
          mainAxisAlignment: _parseMainAxisAlignment(element.getAttribute('mainAxisAlignment') ?? 'start'),
          crossAxisAlignment: _parseCrossAxisAlignment(element.getAttribute('crossAxisAlignment') ?? 'center'),
          children: element.children
              .whereType<xml.XmlElement>()
              .map(_convertXmlElementToWidget)
              .toList(),
        );
      case 'row':
        return Row(
          mainAxisAlignment: _parseMainAxisAlignment(element.getAttribute('mainAxisAlignment') ?? 'start'),
          crossAxisAlignment: _parseCrossAxisAlignment(element.getAttribute('crossAxisAlignment') ?? 'center'),
          children: element.children
              .whereType<xml.XmlElement>()
              .map(_convertXmlElementToWidget)
              .toList(),
        );
      case 'text':
        return Text(
          element.innerText ?? '',
          style: _parseTextStyle(element),
        );
      case 'button':
        final onPressedAction = element.getAttribute('onPressed');
        return ElevatedButton(
          onPressed: onPressedAction != null 
            ? () => _executeAction(onPressedAction) 
            : null,
          child: Text(element.innerText ?? 'Button'),
        );
      case 'icon_button':
        final iconType = element.getAttribute('icon') ?? 'add';
        final onPressedAction = element.getAttribute('onPressed');
        return IconButton(
          icon: Icon(_parseIconData(iconType)),
          onPressed: onPressedAction != null 
            ? () => _executeAction(onPressedAction) 
            : null,
        );
      case 'image':
        final imagePath = element.getAttribute('src') ?? '';
        // In a real implementation, we'd load the image from the app's resources
        return Image.asset(imagePath);
      case 'divider':
        return const Divider();
      case 'card':
        return Card(
          child: _buildChildren(element),
        );
      case 'list_tile':
        xml.XmlElement? titleElement;
        xml.XmlElement? subtitleElement;
        
        for (final child in element.children) {
          if (child is xml.XmlElement) {
            if (child.name.local == 'title') {
              titleElement = child;
            } else if (child.name.local == 'subtitle') {
              subtitleElement = child;
            }
          }
        }
        
        return ListTile(
          title: titleElement != null 
            ? _convertXmlElementToWidget(titleElement)
            : null,
          subtitle: subtitleElement != null 
            ? _convertXmlElementToWidget(subtitleElement)
            : null,
        );
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

  /// Parse EdgeInsets from string (e.g., "10" or "10,5,10,5")
  EdgeInsets _parseEdgeInsets(String? value) {
    if (value == null || value.isEmpty) return const EdgeInsets.all(0);
    
    final parts = value.split(',');
    if (parts.length == 1) {
      final all = double.tryParse(parts[0]) ?? 0.0;
      return EdgeInsets.all(all);
    } else if (parts.length == 4) {
      final top = double.tryParse(parts[0]) ?? 0.0;
      final right = double.tryParse(parts[1]) ?? 0.0;
      final bottom = double.tryParse(parts[2]) ?? 0.0;
      final left = double.tryParse(parts[3]) ?? 0.0;
      return EdgeInsets.fromLTRB(left, top, right, bottom);
    }
    
    return const EdgeInsets.all(0);
  }

  /// Parse double value
  double? _parseDouble(String? value) {
    return value != null ? double.tryParse(value) : null;
  }

  /// Parse color from string
  Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Simple color parsing (could be extended)
    switch (value.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'grey': case 'gray': return Colors.grey;
      case 'transparent': return Colors.transparent;
      default: 
        // Try to parse hex color
        if (value.startsWith('#')) {
          try {
            final hexColor = value.replaceAll('#', '');
            if (hexColor.length == 6) {
              return Color(int.parse('FF$hexColor', radix: 16));
            } else if (hexColor.length == 8) {
              return Color(int.parse(hexColor, radix: 16));
            }
          } catch (e) {
            return null;
          }
        }
        return null;
    }
  }

  /// Parse MainAxisAlignment
  MainAxisAlignment _parseMainAxisAlignment(String value) {
    switch (value.toLowerCase()) {
      case 'start': return MainAxisAlignment.start;
      case 'end': return MainAxisAlignment.end;
      case 'center': return MainAxisAlignment.center;
      case 'space_between': return MainAxisAlignment.spaceBetween;
      case 'space_around': return MainAxisAlignment.spaceAround;
      case 'space_evenly': return MainAxisAlignment.spaceEvenly;
      default: return MainAxisAlignment.start;
    }
  }

  /// Parse CrossAxisAlignment
  CrossAxisAlignment _parseCrossAxisAlignment(String value) {
    switch (value.toLowerCase()) {
      case 'start': return CrossAxisAlignment.start;
      case 'end': return CrossAxisAlignment.end;
      case 'center': return CrossAxisAlignment.center;
      case 'stretch': return CrossAxisAlignment.stretch;
      case 'baseline': return CrossAxisAlignment.baseline;
      default: return CrossAxisAlignment.center;
    }
  }

  /// Parse TextStyle from element attributes
  TextStyle _parseTextStyle(xml.XmlElement element) {
    final color = _parseColor(element.getAttribute('color'));
    final size = double.tryParse(element.getAttribute('size') ?? '');
    final weight = element.getAttribute('weight');
    
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight != null ? _parseFontWeight(weight) : null,
    );
  }

  /// Parse FontWeight
  FontWeight _parseFontWeight(String value) {
    switch (value.toLowerCase()) {
      case 'w100': return FontWeight.w100;
      case 'w200': return FontWeight.w200;
      case 'w300': return FontWeight.w300;
      case 'w400': return FontWeight.w400;
      case 'w500': return FontWeight.w500;
      case 'w600': return FontWeight.w600;
      case 'w700': return FontWeight.w700;
      case 'w800': return FontWeight.w800;
      case 'w900': return FontWeight.w900;
      case 'normal': return FontWeight.normal;
      case 'bold': return FontWeight.bold;
      default: return FontWeight.normal;
    }
  }

  /// Parse IconData from string
  IconData _parseIconData(String value) {
    switch (value.toLowerCase()) {
      case 'add': return Icons.add;
      case 'remove': case 'delete': return Icons.delete;
      case 'edit': return Icons.edit;
      case 'save': return Icons.save;
      case 'home': return Icons.home;
      case 'settings': return Icons.settings;
      case 'info': return Icons.info;
      case 'close': return Icons.close;
      default: return Icons.help;
    }
  }

  /// Gets the directory path for an app
  Future<String> _getAppDirectoryPath(String packageName) async {
    final packagesDir = await DataPersistenceService.getPackagesDirectory();
    return path.join(packagesDir.path, packageName);
  }

  /// Executes an action (for now just print, in real implementation would execute Dart code)
  void _executeAction(String action) {
    print('Executing action: $action');
    // In a real implementation, this would execute the Dart code associated with the action
  }

  /// Uninstalls an app
  Future<void> uninstallApp(String packageName) async {
    // Remove from in-memory list
    _installedApps.removeWhere((app) => app.package.packageName == packageName);
    
    // Remove app data from persistent storage
    await DataPersistenceService.deleteAppInstance(packageName);
    
    // Remove app package directory
    final packagesDir = await DataPersistenceService.getPackagesDirectory();
    final appPackageDir = Directory(path.join(packagesDir.path, packageName));
    if (await appPackageDir.exists()) {
      await appPackageDir.delete(recursive: true);
    }
    
    // Remove permissions associated with the app
    await _permissionManager.removeAppPermissions(packageName);
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