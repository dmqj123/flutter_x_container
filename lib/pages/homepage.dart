import 'package:flutter/material.dart';

import 'settingspage.dart';
import 'package:flutter_x_container/class.dart';

bool is_home = true;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// 模拟应用数据
List<Applnk> apps = [
  Applnk('HelloWorld',
      Image.network("https://kooly.faistudio.top/material/icon.png"))
];

class _HomePageState extends State<HomePage> {
  Widget _app_view() {
    //TODO 实现应用视图
    return Text("Appview");
  }

  Widget _build_apps_list() {
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
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cancel),
                        title: const Text('取消'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ].map((child) => Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: child,
                    )).toList(),
                  );
                }
              )
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: app.icon,
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
                  onPressed: () {},
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      is_home = true;
                    });
                  },
                ),
        ),
        body: (is_home) ? _build_apps_list() : _app_view());
  }
}
