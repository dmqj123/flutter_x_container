import 'package:flutter/material.dart';
import 'package:flutter_x_container/system.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool wifiEnabled = true;
  bool bluetoothEnabled = false;
  double brightness = 0.7;
  String language = '简体中文';
  String region = '中国大陆';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text('设置'),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          decoration: (Settings.dark_mode) ? new BoxDecoration(color: Colors.black) : null,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              _buildSectionHeader('网络'),
              _buildSwitchListTile(
                icon: Icons.wifi,
                title: 'Wi-Fi',
                value: wifiEnabled,
                onChanged: (bool value) {
                  setState(() {
                    wifiEnabled = value;
                  });
                },
              ),
              const Divider(),
              _buildSectionHeader('显示'),
              _buildSwitchListTile(
                icon: Icons.dark_mode,
                title: '深色模式',
                value: Settings.dark_mode,
                onChanged: (bool value) {
                  setState(() {
                    Settings.dark_mode = value;
                    setState(() {});
                  });
                },
              ),
              const Divider(),
              _buildSectionHeader('通用'),
              _buildListTile(
                icon: Icons.language,
                title: '语言与地区',
                subtitle: '$language ($region)',
                onTap: _showLanguageSettings,
              ),
              _buildListTile(
                icon: Icons.wallpaper,
                title: '壁纸',
                onTap: () {
                  // 壁纸设置功能
                },
              ),
              _buildListTile(
                icon: Icons.security,
                title: '安全性与隐私',
                onTap: () {
                  // 安全性设置功能
                },
              ),
              _buildListTile(
                icon: Icons.info,
                title: '关于',
                subtitle: '系统版本 1.0.0',
                onTap: () {
                  // 关于页面
                },
              ),
            ],
          ),
        ));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Settings.dark_mode ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSwitchListTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          color: Settings.dark_mode ? Colors.white : Colors.black,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          color: Settings.dark_mode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Settings.dark_mode ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageSettings() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Settings.dark_mode ? Colors.grey[900] : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    '简体中文',
                    style: TextStyle(
                      color: Settings.dark_mode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '中国大陆',
                    style: TextStyle(
                      color: Settings.dark_mode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      language = '简体中文';
                      region = '中国大陆';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(
                    'English',
                    style: TextStyle(
                      color: Settings.dark_mode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'United States',
                    style: TextStyle(
                      color: Settings.dark_mode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      language = 'English';
                      region = 'United States';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
