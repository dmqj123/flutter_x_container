import 'package:flutter/material.dart';
import 'app_manager.dart';
import 'package_manager.dart';
import 'permission_manager.dart';
import 'models/app_instance.dart';

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
              );
            },
          ),
        );
      },
    );
  }

  void _launchApp(appInstance) {
    // Launch the selected app
    widget.appManager.launchApp(appInstance.package.packageName);
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
              hintText: 'e.g., /storage/emulated/0/app.fxc',
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
  final dynamic appInstance;
  final VoidCallback onTap;

  const AppTile({
    Key? key,
    required this.appInstance,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
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
              child: const Icon(Icons.apps, size: 36),
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
}