import 'dart:io';
import 'package:flutter/material.dart';

/// Settings App for FlutterX Container
class SettingsApp {
  late BuildContext _context;
  
  // Settings state variables
  String _theme = 'system';
  String _language = 'en';
  bool _biometricLock = false;
  String _timeout = '5';
  
  /// Main entry point for the settings app
  void run() {
    runApp(
      MaterialApp(
        title: 'Settings',
        home: Builder(
          builder: (context) {
            _context = context;
            return _buildSettingsScreen();
          },
        ),
      ),
    );
  }
  
  Widget _buildSettingsScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'FlutterX Container Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            // General Settings
            _buildSection('General', [
              _buildSettingItem('Theme', _theme, [
                _buildChoiceButton('Light', 'light'),
                const SizedBox(width: 8),
                _buildChoiceButton('Dark', 'dark'),
                const SizedBox(width: 8),
                _buildChoiceButton('System', 'system'),
              ]),
              
              const SizedBox(height: 16),
              
              _buildSettingItem('Language', _language, [
                _buildChoiceButton('English', 'en'),
                const SizedBox(width: 8),
                _buildChoiceButton('中文', 'zh'),
              ]),
            ]),
            
            const SizedBox(height: 16),
            
            // Security Settings
            _buildSection('Security', [
              _buildSettingItem('Biometric Lock', _biometricLock ? 'On' : 'Off', [
                _buildChoiceButton('On', 'on', isBool: true),
                const SizedBox(width: 8),
                _buildChoiceButton('Off', 'off', isBool: true),
              ]),
              
              const SizedBox(height: 16),
              
              _buildSettingItem('Auto-lock Timeout', '${_timeout} min', [
                _buildChoiceButton('1 min', '1'),
                const SizedBox(width: 8),
                _buildChoiceButton('5 min', '5'),
                const SizedBox(width: 8),
                _buildChoiceButton('15 min', '15'),
                const SizedBox(width: 8),
                _buildChoiceButton('Never', 'never'),
              ]),
            ]),
            
            const SizedBox(height: 16),
            
            // About Section
            _buildSection('About', [
              const ListTile(
                title: Text('FlutterX Container'),
                subtitle: Text('Version 1.0.0'),
              ),
              const ListTile(
                title: Text('© 2025 FlutterX Project'),
              ),
              ElevatedButton(
                onPressed: _checkForUpdates,
                child: const Text('Check for Updates'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingItem(String label, String currentValue, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: buttons,
        ),
      ],
    );
  }
  
  Widget _buildChoiceButton(String label, String value, {bool isBool = false}) {
    bool isSelected = isBool 
        ? (value == 'on' && _biometricLock) || (value == 'off' && !_biometricLock)
        : value == _getSettingValue(isBool);
    
    return ElevatedButton(
      onPressed: () => _updateSetting(value, isBool),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
  
  String _getSettingValue(bool isBool) {
    if (isBool) return _biometricLock ? 'on' : 'off';
    return _theme; // Default to theme for non-boolean settings
  }
  
  void _updateSetting(String value, bool isBool) {
    if (isBool) {
      _biometricLock = value == 'on';
    } else {
      switch(value) {
        case 'light':
        case 'dark':
        case 'system':
          _theme = value;
          break;
        case 'en':
        case 'zh':
          _language = value;
          break;
        case '1':
        case '5':
        case '15':
        case 'never':
          _timeout = value;
          break;
      }
    }
    
    // Update the UI
    if (_context.mounted) {
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text('Setting updated: $value'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  void _checkForUpdates() {
    if (_context.mounted) {
      showDialog(
        context: _context,
        builder: (context) => AlertDialog(
          title: const Text('Check for Updates'),
          content: const Text('Checking for updates...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      // Simulate update check
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (_context.mounted) {
          Navigator.of(_context).pop(); // Close progress dialog
          showDialog(
            context: _context,
            builder: (context) => AlertDialog(
              title: const Text('Update Check Complete'),
              content: const Text('Your FlutterX Container is up to date.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    }
  }
}

/// Entry point function for the app
void main() {
  final app = SettingsApp();
  app.run();
}