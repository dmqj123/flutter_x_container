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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: is_home ? 0 : 1);
  }

  Widget _app_view() {
    //TODO 实现应用视图
    return const Center(
      child: Text("Appview"),
    );
  }

  Widget _build_apps_list() {
    List<Applnk> apps = GetAppList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 每行4个应用
          childAspectRatio: 1.0, // 宽高比
          crossAxisSpacing: 8.0, // 水平间距
          mainAxisSpacing: 8.0, // 垂直间距
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return Card(
              child: InkWell(
            onTap: () => {
              setState(() {
                is_home = false;
                _pageController.animateToPage(1,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut);
              })
              //TODO 跳转应用
            },
            onLongPress: () => {
              //TODO 应用长按菜单
              //从页面下方弹出一个小选择框，选择打开或卸载
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
                            if(app.bundle_name != null){
                              UnInstallApp(app.bundle_name!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('卸载成功'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            setState(() {
                              
                            });
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
                  child: (File(app.icon_path).existsSync()) ? Image.file(File(app.icon_path)) : const Icon(Icons.error),
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
  Widget build(BuildContext context) {
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
                    FilePickerResult? picker_result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['zip','fcx'],
                      allowMultiple: false
                    );
                    if(picker_result == null || picker_result.paths.isEmpty){
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
                        setState(() {
                          
                        });
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
                                      child: const Text('确定'), onPressed: () {
                                        Navigator.of(context).pop();
                                      })
                                ]);
                          });
                    }
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
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
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              is_home = index == 0;
            });
          },
          children: [
            _build_apps_list(),
            _app_view(),
          ],
        ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
