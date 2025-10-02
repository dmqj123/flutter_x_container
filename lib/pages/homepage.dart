import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_x_container/enum.dart';

import 'settingspage.dart';
import 'package:flutter_x_container/class.dart';
import 'package:flutter_x_container/app_manage.dart';

bool is_home = true;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  String now_app_bundle_name = "";
  late Future<Widget> _appViewFuture;
  
  // 添加一个 Map 来缓存每个应用的 Future
  final Map<String, Future<Widget>> _appViewFutureCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: is_home ? 0 : 1);
    // 初始化一个默认的 Future，避免空值
    _appViewFuture =
        Future.value(const Center(child: CircularProgressIndicator()));
  }
  
  // 新增方法：获取或创建应用视图的 Future
  Future<Widget> _getCachedAppViewFuture(String bundleName) {
    if (!_appViewFutureCache.containsKey(bundleName) || bundleName != now_app_bundle_name) {
      _appViewFutureCache[bundleName] = _app_view();
    }
    return _appViewFutureCache[bundleName]!;
  }

  Future<Widget> _app_view() async {
    OpenAppResult result = await OpenApp(now_app_bundle_name);

    if (!result.success) {
      return Center(
        child: Text("错误：" + (result.message ?? "")),
      );
    }

    //TODO 实现应用视图
    return Center(
      child: result.page ?? const Text("加载中..."),
    );
  }

  late List<Applnk> apps;

  Widget _build_apps_list() {
    apps = GetAppList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 每行4个应用
          childAspectRatio: 1.0, // 宽高比
          crossAxisSpacing: 5.0, // 水平间距
          mainAxisSpacing: 5.0, // 垂直间距
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final Applnk app = apps[index];
          return Card(
              child: InkWell(
            onTap: () => {
              setState(() {
                now_app_bundle_name = app.bundle_name!;
                is_home = false;
                _pageController.animateToPage(1,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut);
              })
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
                  width: 40,
                  height: 40,
                  child: (File(app.icon_path).existsSync())
                      ? Image.file(
                          File(app.icon_path),
                          cacheWidth: 160,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.error),
                ),
                const SizedBox(height: 8),
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    apps = GetAppList();
    return Scaffold(
        appBar: AppBar(
          title: (is_home) ? null : const Text("App"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            (is_home)
                ? IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SettingsPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
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
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
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
                            allowedExtensions: ['zip', 'fcx'],
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
                      _pageController.animateToPage(0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut);
                    });
                  },
                ),
        ),
        body: (apps.length == 0)
            ? const Center(
                child: Column(children: [Text("暂无应用"), Icon(Icons.widgets)]),
              )
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    is_home = index == 0;
                    // 当切换到应用视图时，使用缓存的 Future 或创建新的
                    if (index == 1 && now_app_bundle_name.isNotEmpty) {
                      //如果对应包名的PageStorageKey不存在，则创建新的
                      _appViewFuture = _getCachedAppViewFuture(now_app_bundle_name);
                    }
                  });
                },
                children: [
                  _build_apps_list(),
                  FutureBuilder<Widget>(
                    key: PageStorageKey(now_app_bundle_name),
                    future: _appViewFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return snapshot.data!;
                      } else if (snapshot.hasError) {
                        return Center(child: Text('加载错误: ${snapshot.error}'));
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ));
  }
}