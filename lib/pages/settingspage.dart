import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool wifiEnabled = true;
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
      body: ListView(
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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
      title: Text(title),
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
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageSettings() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('简体中文'),
                subtitle: const Text('中国大陆'),
                onTap: () {
                  setState(() {
                    language = '简体中文';
                    region = '中国大陆';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                subtitle: const Text('United States'),
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
        );
      },
    );
  }
}