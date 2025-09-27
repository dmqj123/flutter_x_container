import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path/path.dart' as path;
import 'app_manager.dart';
import 'package_manager.dart';
import 'permission_manager.dart';
import 'models/app_instance.dart';
import 'utils/data_persistence_service.dart';

/// Interface that apps must implement to provide their main UI
abstract class AppInterface {
  Widget buildUI();
}

/// Registry for app-specific UI implementations
class AppUIRegistry {
  static final Map<String, AppInterface> _appInterfaces = {};
  
  /// Register an app's UI implementation
  static void registerAppInterface(String packageName, AppInterface appInterface) {
    _appInterfaces[packageName] = appInterface;
  }
  
  /// Get an app's UI implementation
  static AppInterface? getAppInterface(String packageName) {
    return _appInterfaces[packageName];
  }
}

/// Main entry point for the FlutterX Container
class FlutterXContainer extends StatefulWidget {
  const FlutterXContainer({Key? key}) : super(key: key);

  @override
  State<FlutterXContainer> createState() => _FlutterXContainerState();
}

class _FlutterXContainerState extends State<FlutterXContainer> {
  late AppManager _appManager;
  late PackageManager _packageManager;
  late PermissionManager _permissionManager;

  @override
  void initState() {
    super.initState();
    
    // Initialize managers
    _permissionManager = PermissionManager();
    _packageManager = PackageManager(permissionManager: _permissionManager);
    _appManager = AppManager(
      packageManager: _packageManager,
      permissionManager: _permissionManager,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterX Container',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ContainerHome(
        appManager: _appManager,
        packageManager: _packageManager,
      ),
    );
  }
}

/// The main home screen of the container
class ContainerHome extends StatefulWidget {
  final AppManager appManager;
  final PackageManager packageManager;

  const ContainerHome({
    Key? key,
    required this.appManager,
    required this.packageManager,
  }) : super(key: key);

  @override
  State<ContainerHome> createState() => _ContainerHomeState();
}

class _ContainerHomeState extends State<ContainerHome> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeContainer();
  }

  Future<void> _initializeContainer() async {
    // Initialize the container by loading installed apps
    await widget.appManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterX Container'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Launch settings app
              _launchSettingsApp();
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Now we use the FutureBuilder from _buildAppGrid to ensure data is always fresh
            return _buildAppGrid();
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _installNewApp,
        tooltip: 'Install App',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppGrid() {
    return FutureBuilder<List<AppInstance>>(
      future: widget.appManager.loadInstalledApps(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final apps = snapshot.data!;
        
        if (apps.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apps, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No apps installed',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to install an app',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return AppTile(
                appInstance: app,
                onTap: () => _launchApp(app),
                appManager: widget.appManager,
                onUninstalled: () {
                  setState(() {}); // 刷新UI
                },
              );
            },
          ),
        );
      },
    );
  }

  void _launchApp(AppInstance appInstance) async {
    try {
      // Check permissions and get verified app instance
      final verifiedAppInstance = await widget.appManager.launchApp(appInstance.package.packageName);
      
      // Navigate to the app's screen
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AppScreen(
        appInstance: verifiedAppInstance,
        appManager: widget.appManager,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 缩放动画
        return ScaleTransition(
          scale: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
          ),
          child: child,
        );
          },
        ),
      );
    } catch (e) {
      // Show error if app launch fails
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error launching app: $e')));
    }
  }

  void _launchSettingsApp() {
    // For now, we'll just show a placeholder
    // Later this will launch the actual settings app
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings app would be launched here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _installNewApp() async {
    // Show a dialog to select an app package to install
    // This is a simplified version - in reality, we'd have a file picker
    String? packagePath = await showDialog<String>(
      context: context,
      builder: (context) => const AppInstallDialog(),
    );
    
    if (packagePath != null) {
      try {
        // Install the app package
        final appInstance = await widget.packageManager.installApp(packagePath);
        
        // Refresh installed apps in the app manager to include the new one
        await widget.appManager.refreshInstalledApps();
        
        // Show success message
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('App installed successfully')));
            
        // Refresh the UI after a short delay to ensure data is loaded
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

/// Dialog for installing new apps
class AppInstallDialog extends StatefulWidget {
  const AppInstallDialog({Key? key}) : super(key: key);

  @override
  State<AppInstallDialog> createState() => _AppInstallDialogState();
}

class _AppInstallDialogState extends State<AppInstallDialog> {
  final TextEditingController _pathController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Install App'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter path to app package:'),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              hintText: 'path/to/app.fxc',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final path = _pathController.text.trim();
            if (path.isNotEmpty) {
                // 如果路径不为空，则关闭对话框并返回路径
                Navigator.of(context).pop(path);
            }
          },
          child: const Text('Install'),
        ),
      ],
    );
  }
}

/// Widget representing a single app tile
class AppTile extends StatelessWidget {
  final AppInstance appInstance;
  final VoidCallback onTap;
  final AppManager appManager; // 添加 AppManager 参数以便卸载应用
  final VoidCallback onUninstalled; // 添加卸载回调

  const AppTile({
    Key? key,
    required this.appInstance,
    required this.onTap,
    required this.appManager,
    required this.onUninstalled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showUninstallDialog(context), // 长按触发卸载
        onSecondaryTap: () => _showUninstallDialog(context), // 右键点击触发卸载
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildAppIcon(),
            ),
            const SizedBox(height: 8),
            // App name
            Text(
              appInstance.package.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppIcon() {
    // If we have a valid icon path, try to display it
    if (appInstance.package.iconPath.isNotEmpty) {
      return FutureBuilder<String>(
        future: _getFullIconPath(),
        builder: (context, snapshot) {
          if (snapshot.hasData && File(snapshot.data!).existsSync()) {
            return Image.file(
              File(snapshot.data!),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            );
          } else {
            // If no valid icon, show the default icon
            return const Icon(Icons.apps, size: 36, color: Colors.grey);
          }
        },
      );
    } else {
      // If no icon path, show the default icon
      return const Icon(Icons.apps, size: 36, color: Colors.grey);
    }
  }
  
  Future<String> _getFullIconPath() async {
    final packagesDir = await DataPersistenceService.getPackagesDirectory();
    return path.join(packagesDir.path, appInstance.package.packageName, appInstance.package.iconPath);
  }
  
  /// 显示卸载确认对话框
  void _showUninstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall App'),
        content: Text('Are you sure you want to uninstall "${appInstance.package.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // 取消
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 关闭对话框
              try {
                // 调用卸载功能
                await appManager.uninstallApp(appInstance.package.packageName);
                
                // 刷新UI
                onUninstalled();
                
                // 显示成功消息
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${appInstance.package.name} uninstalled successfully'),
                  ),
                );
              } catch (e) {
                // 显示错误消息
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error uninstalling app: $e'),
                  ),
                );
              }
            },
            child: const Text('Uninstall'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // 设置文本颜色为红色
            ),
          ),
        ],
      ),
    );
  }
}

/// A screen to display an app's UI
class AppScreen extends StatefulWidget {
  final AppInstance appInstance;
  final AppManager appManager;

  const AppScreen({
    Key? key,
    required this.appInstance,
    required this.appManager,
  }) : super(key: key);

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  String? _interfaceContent;
  String? _codeContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppContent();
  }

  Future<void> _loadAppContent() async {
    try {
      // Load the app's interface definition
      final interfacePath = await _getAppResourcePath(
        widget.appInstance.package.packageName,
        widget.appInstance.package.interfacePath,
      );
      
      final interfaceFile = File(interfacePath);
      if (!await interfaceFile.exists()) {
        throw Exception('Interface file not found: ${widget.appInstance.package.interfacePath}');
      }
      
      final interfaceContent = await interfaceFile.readAsString();
      
      // Load the app's Dart code
      final codePath = await _getAppResourcePath(
        widget.appInstance.package.packageName,
        widget.appInstance.package.codePath,
      );
      
      final codeFile = File(codePath);
      if (!await codeFile.exists()) {
        throw Exception('Code file not found: ${widget.appInstance.package.codePath}');
      }
      
      final codeContent = await codeFile.readAsString();
      
      setState(() {
        _interfaceContent = interfaceContent;
        _codeContent = codeContent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> _getAppResourcePath(String packageName, String resourcePath) async {
    // Get the packages directory and build the full path
    final packagesDir = await DataPersistenceService.getPackagesDirectory();
    return path.join(packagesDir.path, packageName, resourcePath);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.appInstance.package.name),
          backgroundColor: Colors.blue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.appInstance.package.name),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close App',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Error loading app: $_error',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Container'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appInstance.package.name),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false, // 不自动显示返回键，因为我们有关闭按钮
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close App',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: _buildAppInterface(),
      ),
    );
  }

  /// Handle special actions from app interface
  void _handleAction(String action) {
    switch (action) {
      case 'clearAllData':
        _clearAllData();
        break;
      case 'show_dialog':
        //ShowDialog
  
        break;
      default:
        // Handle other actions as needed
        print('Unknown action: $action');
    }
  }
  
  /// Show a popup dialog with specified content
  void _showPopup(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Popup Message'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Adapter function to match the new onAction signature
  void _handleActionAdapter(String action, [String? message]) {
    switch (action) {
      case 'clearAllData':
        _clearAllData();
        break;
      case 'showPopup':
        String popupMessage = message ?? 'Default message';
        _showPopup(popupMessage);
        break;
      default:
        // Handle other actions as needed
        print('Unknown action: $action');
    }
  }
  
  /// Clear all application data
  void _clearAllData() {
    // Show a confirmation dialog before clearing data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all application data? This will delete all installed apps and their data permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _confirmClearAllData();
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
  
  /// Confirm and execute clearing all data
  void _confirmClearAllData() async {
    try {
      // Use the DataPersistenceService to clear all data
      await DataPersistenceService.clearAllData();
      print('Data cleanup completed.');
      
      // Show a success message
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data Cleared'),
          content: const Text('All application data has been cleared successfully. The app will now close. Please restart it.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Close the app so it can be restarted with clean data
                exit(0); // This will terminate the app
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      print('Error clearing data: $error');
      // Show an error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to clear data: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildAppInterface() {
    // First, check if the app has registered a custom UI implementation
    AppInterface? appInterface = AppUIRegistry.getAppInterface(widget.appInstance.package.packageName);
    
    if (appInterface != null) {
      // Use the app's custom UI implementation
      return appInterface.buildUI();
    }
    
    // Fallback to XML interface if no custom UI is registered
    if (_interfaceContent == null) {
      return const Center(child: Text('No interface content to display'));
    }
    
    try {
      // Parse the XML content into Flutter widgets
      final widgetBuilder = _AppWidgetBuilder(
        widget.appManager,
        onAction: _handleActionAdapter,
      );
      return widgetBuilder.parseXmlInterface(_interfaceContent!);
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error parsing app interface: $e',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}

/// Helper class to build widgets from XML for the app screen
class _AppWidgetBuilder {
  final AppManager _appManager;
  final Function(String action, [String? message])? onAction;
  
  _AppWidgetBuilder(this._appManager, {this.onAction});

  Widget parseXmlInterface(String xmlContent) {
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
      case 'listview':
        return ListView(
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

  /// Execute an action (for now just print, in real implementation would execute Dart code)
  void _executeAction(String action) {
    print('Executing action: $action');
    
    // Parse action to extract potential parameters
    String actionName = action;
    String? parameter;
    
    // Check if action contains parameter (format: actionName:paramValue)
    if (action.contains(':')) {
      int colonIndex = action.indexOf(':');
      actionName = action.substring(0, colonIndex);
      parameter = action.substring(colonIndex + 1);
    }
    
    // If there's a callback for special actions, use it
    if (onAction != null) {
      // Pass the action name and parameter separately
      onAction!(actionName, parameter);
    }
    // In a real implementation, this would execute the Dart code associated with the action
  }
}