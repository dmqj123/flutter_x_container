import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_x_container/enum.dart';

import 'settingspage.dart';
import 'package:flutter_x_container/class.dart';
import 'package:flutter_x_container/app_manage.dart';
import 'testpage.dart';

bool is_home = true;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // 使用索引来控制当前显示的页面
  String now_app_bundle_name = "";

  // 添加动画控制器
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // 存储已打开应用的IndexedStack索引
  final Map<String, int> _appIndices = {};
  List<Widget> _appViews = [];
  int _currentAppIndex = 0;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _setupAnimations();

    // 启动初始动画
    _animationController.forward();
  }

  void _setupAnimations() {
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _addAppView(String bundleName, Widget view) {
    if (!_appIndices.containsKey(bundleName)) {
      // 如果应用未被添加到视图中，则添加它
      setState(() {
        _appViews = List.from(_appViews)..add(view);
        _appIndices[bundleName] = _appViews.length - 1;
      });
    }
  }

  void _switchToApp(String bundleName) {
    if (_appIndices.containsKey(bundleName)) {
      setState(() {
        _currentAppIndex = _appIndices[bundleName]!;
        now_app_bundle_name = bundleName;
      });
    }
  }

  late List<Applnk> apps;

  Widget _build_apps_list() {
    apps = GetAppList();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 每行4个应用
          childAspectRatio: 1.0, // 宽高比
          crossAxisSpacing: 30, // 水平间距
          mainAxisSpacing: 30, // 垂直间距
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final Applnk app = apps[index];
          return Card(
              child: InkWell(
            onTap: () async {
              // 先检查是否已经有这个应用的视图
              if (!_appIndices.containsKey(app.bundle_name!)) {
                // 如果没有，则创建应用视图并添加到_appViews中
                OpenAppResult result = await OpenApp(app.bundle_name!);
                
                if (result.success) {
                  _addAppView(app.bundle_name!, result.page ?? const Text("加载中..."));
                } else {
                  _addAppView(app.bundle_name!, Center(
                    child: Text("错误：" + (result.message ?? "")),
                  ));
                }
              }
              
              // 切换到目标应用
              _switchToApp(app.bundle_name!);
              
              setState(() {
                is_home = false;
                _currentIndex = 1; // 切换到应用视图
                // 重新启动动画
                _animationController.reset();
                _setupAnimations();
                _animationController.forward();
              });
            },
            onLongPress: () => {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('卸载'),
                          onTap: () {
                            if (app.bundle_name != null) {
                              UnInstallApp(app.bundle_name!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('卸载成功'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            setState(() {});
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('详细信息'),
                          onTap: () {
                            //TODO 应用详细信息显示
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.cancel),
                          title: const Text('取消'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ]
                          .map((child) => Padding(
                                padding: const EdgeInsets.all(2.5),
                                child: child,
                              ))
                          .toList(),
                    );
                  })
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: (File(app.icon_path).existsSync())
                      ? Image.file(
                          File(app.icon_path),
                          cacheWidth: 160,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.error),
                ),
                const SizedBox(height: 2),
                Text(
                  app.name,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    apps = GetAppList();
    return Scaffold(
        appBar: AppBar(
          title: (is_home) ? const Text("Apps") : const Text("App"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            (is_home)
                ? Row(
                    children: [
                      //如果是调试模式
                      (!const bool.fromEnvironment("dart.vm.product"))
                          ? IconButton(
                              onPressed: () => {
                                    Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              TestPage(),
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;

                                            var tween = Tween(
                                                    begin: begin, end: end)
                                                .chain(
                                                    CurveTween(curve: curve));
                                            var offsetAnimation =
                                                animation.drive(tween);

                                            return SlideTransition(
                                              position: offsetAnimation,
                                              child: child,
                                            );
                                          },
                                          transitionDuration:
                                              const Duration(milliseconds: 150),
                                        ))
                                  },
                              icon: Icon(Icons.bug_report))
                          : Container(),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SettingsPage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      )
                    ],
                  )
                : const SizedBox(width: 48)
          ],
          leading: (is_home)
              ? IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    //询问应用包
                    FilePickerResult? picker_result = await FilePicker.platform
                        .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['zip', 'fxc'],
                            allowMultiple: false);
                    if (picker_result == null || picker_result.paths.isEmpty) {
                      return;
                    }
                    if (await InstallApp(picker_result!.paths[0]!) ==
                        AppInstall_Result.Success) {
                      //弹窗：安装成功
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: const Text('安装成功'),
                                content: const Text('应用安装成功'),
                                actions: [
                                  TextButton(
                                      child: const Text('确定'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      })
                                ]);
                          });
                      setState(() {});
                    } else {
                      //弹窗：安装失败
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: const Text('安装失败'),
                                content: const Text('应用安装失败'),
                                actions: [
                                  TextButton(
                                      child: const Text('确定'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      })
                                ]);
                          });
                    }
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    setState(() {
                      is_home = true;
                      _currentIndex = 0; // 切换到主页视图
                      // 重新启动动画
                      _animationController.reset();
                      _setupAnimations();
                      _animationController.forward();
                    });
                  },
                ),
        ),
        body: (apps.length == 0)
            ? const Center(
                child: Column(
                  children: [Text("暂无应用"), Icon(Icons.widgets)],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
              )
            : IndexedStack(
                index: _currentIndex,
                children: [
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _build_apps_list(),
                    ),
                  ),
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: IndexedStack(
                        index: _currentAppIndex,
                        children: _appViews,
                      ),
                    ),
                  ),
                ],
              ));
  }
}
