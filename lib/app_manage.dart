import 'dart:io';
import 'dart:convert';
//import 'package:dart_eval/dart_eval.dart';
//import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:flutter_x_container/class.dart';
import 'package:flutter_x_container/runtime/fxcapp.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter_x_container/enum.dart';
import 'package:flutter_x_container/system.dart';

List<Applnk> apps_list = [];

List<Map<String, dynamic>> apps_view_key_list = [];

void SaveAppList() async {
  //将apps_list保存到preferences中
  List<Map<String, dynamic>> encodableList =
      apps_list.map((app) => app.toJson()).toList();
  prefs.setString("app_list_json", json.encode(encodableList));
}

List<Applnk> GetAppList() {
  //读取preferences中的app_list_json
  String app_list_json = prefs.getString("app_list_json") ?? "[]";
  apps_list = (json.decode(app_list_json) as List)
      .map((app) => Applnk.fromJson(app as Map<String, dynamic>))
      .toList();
  return apps_list;
}

Future<void> UnInstallApp(String app_bundle_name) async {
  Directory appDir = await getApplicationDocumentsDirectory();
  String appPath = '${appDir.path}/FlutterXContainer/apps/${app_bundle_name}/';
  File(appPath).deleteSync(recursive: true);

  apps_list.removeWhere((app) => app.bundle_name == app_bundle_name);
  SaveAppList();
}

Appbundle GetBundleInfoFromJson(String app_json) {
  Map<String, dynamic> appInfo = json.decode(app_json);
  return Appbundle(
      appInfo['name'],
      appInfo['bundle_name'],
      appInfo['version'],
      appInfo['icon'],
      appInfo['description'],
      appInfo['author'],
      appInfo['min_version'],
      appInfo['permissions'],
      appInfo['main_code'],
      appInfo['app_type']);
}

Future<AppInstall_Result> InstallApp(String app_path) async {
  //先检查路径是否存在
  if (await !File(app_path).existsSync()) {
    //TODO 找不到文件处理
    return AppInstall_Result.Failed;
  }
  //将文件解压缩到provide的临时目录下
  Directory tempDir = await getTemporaryDirectory();
  //获取时间戳
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  String tempPath = '${tempDir.path}/fxcapps/${timestamp}/';
  //使用archive
  Archive archive = ZipDecoder().decodeBytes(File(app_path).readAsBytesSync());
  //保存解压结果到临时目录
  for (ArchiveFile file in archive) {
    String filename = '${tempPath}${file.name}';
    if (file.isFile) {
      List<int> data = file.content as List<int>;
      File(filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory(filename).create(recursive: true);
    }
  }
  if (!File(tempPath + "app.json").existsSync()) {
    //TODO 找不到文件处理
    return AppInstall_Result.Failed;
  }
  String app_json = File(tempPath + "app.json").readAsStringSync();
  // 解析 JSON 获取 name 字段
  Map<String, dynamic> appInfo = json.decode(app_json);
  Appbundle appbundle = GetBundleInfoFromJson(app_json);
  if (!File(tempPath + appbundle.icon_path).existsSync()) {
    //TODO 找不到图标处理
    return AppInstall_Result.Failed;
  }
  if (!File(tempPath + appbundle.main_code_path).existsSync()) {
    //TODO 找不到主程序处理
    return AppInstall_Result.Failed;
  }
  //将临时目录中的文件移动到provide的文件目录的app目录下的已包名为名称的文件夹下
  //先通过provider获取文件目录
  Directory appDir = await getApplicationDocumentsDirectory();
  String appPath =
      '${appDir.path}/FlutterXContainer/apps/${appbundle.bundle_name}/';
  //移动目录中的所有文件到新目录
  Directory(appPath).createSync(recursive: true);

  // 复制整个目录中的所有文件，而不仅仅是app.json
  Directory tempDirectory = Directory(tempPath);
  await for (FileSystemEntity entity in tempDirectory.list(recursive: true)) {
    if (entity is File) {
      String relativePath = entity.path.replaceFirst(tempPath, '');
      String destinationPath = appPath + relativePath;
      // 手动创建目录结构，不使用path库
      int lastSeparatorIndex =
          destinationPath.lastIndexOf('/') > destinationPath.lastIndexOf('\\')
              ? destinationPath.lastIndexOf('/')
              : destinationPath.lastIndexOf('\\');
      if (lastSeparatorIndex != -1) {
        String dirPath = destinationPath.substring(0, lastSeparatorIndex);
        Directory(dirPath).createSync(recursive: true);
      }
      await entity.copy(destinationPath);
    } else if (entity is Directory) {
      String relativePath = entity.path.replaceFirst(tempPath, '');
      String destinationPath = appPath + relativePath;
      Directory(destinationPath).createSync(recursive: true);
    }
  }

  File(tempPath).deleteSync(recursive: true);

  //保存应用
  if (apps_list.any((app) => app.bundle_name == appbundle.bundle_name)) {
    apps_list.removeWhere((app) => app.bundle_name == appbundle.bundle_name);
  }
  apps_list.add(Applnk(
      appbundle.name, appPath + appbundle.icon_path, appbundle.bundle_name));
  SaveAppList();

  return AppInstall_Result.Success;
}

Future<OpenAppResult> OpenApp(String app_bundle_name) async {
  WidgetsFlutterBinding.ensureInitialized(); //初始化WebView
  Directory appDir = await getApplicationDocumentsDirectory();
  String appPath = '${appDir.path}/FlutterXContainer/apps/${app_bundle_name}/';
  if (await !File(appPath + "app.json").existsSync()) {
    return OpenAppResult(false, "error:app.json not found");
  }
  String app_json = await File(appPath + "app.json").readAsStringSync();
  Appbundle appbundle = GetBundleInfoFromJson(app_json);
  if (appbundle.bundle_name != app_bundle_name) {
    return OpenAppResult(false, "error:app.json bundle_name not match");
  }
  String main_codes =
      await File(appPath + appbundle.main_code_path).readAsStringSync();

  //获取代码文件后缀
  String code_suffix = appbundle.main_code_path.split('.').last;

  late Widget app_page;

  if (appbundle.app_type == "fxc") {
    if (code_suffix == "fxcap") {
      Map<String, dynamic> appInfo = json.decode(main_codes);
      String code_path = appInfo['main_code_path'];
      String page_path = appInfo['main_page_path'];
      String program = await File(appPath + code_path).readAsStringSync();
      String page = await File(appPath + page_path).readAsStringSync();

      if (code_path.endsWith(".dart")) {
        //运行dart代码
      } else if (code_path.endsWith(".js")) {
        //运行js代码
        runjs(
          program,
          "main",
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
              //TEST
              handlerName: 'consoleLog',
              callback: (args) {
                print(args.toString().split(', ')[1]);
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'fxc_api_call',
              callback: (args) {
                String argsString = args.toString();
                // 去除首尾的方括号
                if (argsString.startsWith('[') && argsString.endsWith(']')) {
                  argsString = argsString.substring(1, argsString.length - 1);
                }
                // 再次检查并去除可能的内层方括号
                if (argsString.startsWith('[') && argsString.endsWith(']')) {
                  argsString = argsString.substring(1, argsString.length - 1);
                }
                List<String> commandsw = argsString.split(', ');
                String command = "";
                for (String i in commandsw) {
                  if (command != "") {
                    command = command + " " + i;
                  } else {
                    command = i;
                  }
                }
                //TODO 处理fxc命令
                api_call(command);
              },
            );
          },
        );
      }

      app_page = FxcToWidget(page,func: (p0) {
        runjs(program, p0);
      },);
    }
    /*
      case "dart":
        //使用dart_eval库编译代码
        //实验性代码
        /*
      final Compiler compiler = Compiler();
      //compiler.addPlugin(flutterEvalPlugin);
      final program = compiler.compile({
      'my_pack': {
        'main.dart': """int calculate() {
          return 2 + 2;
        }"""
      }
      });
      print(eval(main_codes,function: 'build',plugins: [flutterEvalPlugin]));*/
        return OpenAppResult(false, "暂不支持dart语言");
        break;
      case "js":
        //运行js代码  TODO
        late InAppWebViewController web_controller;
        String UA = "FlutterXContainer/1.0.0 ";

        InAppWebView webview_widget = InAppWebView(
          initialSettings: InAppWebViewSettings(
            suppressesIncrementalRendering: false,
            webViewAssetLoader: WebViewAssetLoader()
              ..domain = "file:///" + appPath, //BUG
            disableContextMenu: true, //禁用右键菜单
            javaScriptEnabled: true,
            userAgent: UA,
            useShouldOverrideUrlLoading: true,
            allowsInlineMediaPlayback: true,
            isInspectable: false, // 禁用 WebView 检查功能
          ),
          initialData: InAppWebViewInitialData(
            data: main_codes,
            mimeType: "text/html",
            encoding: "utf-8",
          ),
          onWebViewCreated: (controller) async {
            web_controller = controller;
          },
          onLoadStart: (controller, url) async {
            // 页面开始加载时会调用
          },
          onLoadStop: (controller, url) async {
            // 页面加载完成时会调用
          },
          onReceivedError: (controller, request, error) async {
            // 页面加载出错时调用
          },
        );

        app_page = webview_widget;
        break;
      case "html":
        //使用webview运行html代码
        late InAppWebViewController web_controller;
        String UA = "FlutterXContainer/1.0.0 ";

        InAppWebView webview_widget = InAppWebView(
          initialSettings: InAppWebViewSettings(
            suppressesIncrementalRendering: false,
            webViewAssetLoader: WebViewAssetLoader()
              ..domain = "file:///" + appPath, //BUG
            disableContextMenu: true, //禁用右键菜单
            javaScriptEnabled: true,
            userAgent: UA,
            useShouldOverrideUrlLoading: true,
            allowsInlineMediaPlayback: true,
            isInspectable: false, // 禁用 WebView 检查功能
          ),
          initialData: InAppWebViewInitialData(
            data: main_codes,
            mimeType: "text/html",
            encoding: "utf-8",
          ),
          onWebViewCreated: (controller) async {
            web_controller = controller;
          },
          onLoadStart: (controller, url) async {
            // 页面开始加载时会调用
          },
          onLoadStop: (controller, url) async {
            // 页面加载完成时会调用
          },
          onReceivedError: (controller, request, error) async {
            // 页面加载出错时调用
          },
        );

        app_page = webview_widget;
        break;*/
  } else if (appbundle.app_type == "web") {
    switch (code_suffix) {
      case "js":
        //运行js代码  TODO
        late InAppWebViewController web_controller;
        String UA = "FlutterXContainer/1.0.0 ";

        InAppWebView webview_widget = InAppWebView(
          initialSettings: InAppWebViewSettings(
            suppressesIncrementalRendering: false,
            webViewAssetLoader: WebViewAssetLoader()
              ..domain = "file:///" + appPath, //BUG
            disableContextMenu: true, //禁用右键菜单
            javaScriptEnabled: true,
            userAgent: UA,
            useShouldOverrideUrlLoading: true,
            allowsInlineMediaPlayback: true,
            isInspectable: false, // 禁用 WebView 检查功能
          ),
          initialData: InAppWebViewInitialData(
            data: main_codes,
            mimeType: "text/html",
            encoding: "utf-8",
          ),
          onWebViewCreated: (controller) async {
            web_controller = controller;
            controller.addJavaScriptHandler(
              //TEST
              handlerName: 'consoleLog',
              callback: (args) {
                print(args);
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'fxc_api_call',
              callback: (args) {
                List<String> command = args.toString().split(', ');
                //TODO 处理fxc命令
              },
            );
          },
          onLoadStart: (controller, url) async {
            // 页面开始加载时会调用
          },
          onLoadStop: (controller, url) async {
            // 页面加载完成时会调用
          },
          onReceivedError: (controller, request, error) async {
            // 页面加载出错时调用
          },
        );

        app_page = webview_widget;
        break;
      case "html":
        //使用webview运行html代码
        late InAppWebViewController web_controller;
        String UA = "FlutterXContainer/1.0.0 ";

        InAppWebView webview_widget = InAppWebView(
          initialSettings: InAppWebViewSettings(
            suppressesIncrementalRendering: false,
            webViewAssetLoader: WebViewAssetLoader()
              ..domain = "file:///" + appPath, //BUG
            disableContextMenu: true, //禁用右键菜单
            javaScriptEnabled: true,
            userAgent: UA,
            useShouldOverrideUrlLoading: true,
            allowsInlineMediaPlayback: true,
            isInspectable: false, // 禁用 WebView 检查功能
          ),
          initialData: InAppWebViewInitialData(
            data: main_codes,
            mimeType: "text/html",
            encoding: "utf-8",
          ),
          onWebViewCreated: (controller) async {
            web_controller = controller;
            controller.addJavaScriptHandler(
              //TEST
              handlerName: 'consoleLog',
              callback: (args) {
                print(args);
              },
            );
            controller.addJavaScriptHandler(
              handlerName: 'fxc_api_call',
              callback: (args) {
                //此时args.toString()=="[[test, hello]]"
                String argsString = args.toString();
                // 去除首尾的方括号
                if (argsString.startsWith('[') && argsString.endsWith(']')) {
                  argsString = argsString.substring(1, argsString.length - 1);
                }
                // 再次检查并去除可能的内层方括号
                if (argsString.startsWith('[') && argsString.endsWith(']')) {
                  argsString = argsString.substring(1, argsString.length - 1);
                }
                List<String> commandsw = argsString.split(', ');
                String command = "";
                for (String i in commandsw) {
                  if (command != "") {
                    command = command + " " + i;
                  } else {
                    command = i;
                  }
                }
                api_call(command);
                //TODO 处理fxc命令
              },
            );
          },
          onLoadStart: (controller, url) async {
            // 页面开始加载时会调用
          },
          onLoadStop: (controller, url) async {
            // 页面加载完成时会调用
          },
          onReceivedError: (controller, request, error) async {
            // 页面加载出错时调用
          },
        );

        app_page = webview_widget;
        break;
    }
  }
  //如果app_view_list中不包含bn为app_bundle_name的app，则添加
  if (apps_view_key_list.isEmpty ||
      apps_view_key_list
          .where((element) => element["bn"] == app_bundle_name)
          .isEmpty) {
    apps_view_key_list
        .add({"id": ValueKey(app_bundle_name), "bn": app_bundle_name});
  }
  // 安全地访问first元素，避免Bad state: No element异常
  var appView =
      apps_view_key_list.where((element) => element["bn"] == app_bundle_name);
  /*return OpenAppResult(true, null, Container(
    key: appView.isNotEmpty ? appView.first["id"] : UniqueKey(),
    child: app_page,));*/
  return OpenAppResult(
      true,
      null,
      Appview(
        key: appView.isNotEmpty
            ? appView.first["id"]
            : ValueKey(app_bundle_name),
        cchild: app_page,
      ));
}

class Appview extends StatefulWidget {
  // 必须接收“唯一ID”当key
  final Widget cchild;
  const Appview({super.key, required this.cchild});

  @override
  State<Appview> createState() => _AppviewState();
}

class _AppviewState extends State<Appview> with AutomaticKeepAliveClientMixin {
  // 1. 开启缓存
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 2. 必须加这句，缓存才生效
    return widget.cchild;
  }
}
