import 'dart:async' show Completer;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_x_container/class.dart' show ApiCallResult;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import 'app_manage.dart';

late final SharedPreferences prefs;

// 创建一个持久的HeadlessInAppWebView实例
HeadlessInAppWebView? _headlessWebView;
InAppWebViewController? _webController;
bool _isWebViewReady = false;

// 定义onWebViewCreated回调函数类型
typedef WebViewCreatedCallback = void Function(
    InAppWebViewController controller);

// 初始化WebView环境
Future<void> initJsEnvironment(
    {WebViewCreatedCallback? onWebViewCreated}) async {
  if (_headlessWebView != null && _isWebViewReady) return;

  final Completer<void> completer = Completer<void>();

  _headlessWebView = HeadlessInAppWebView(
    initialData: InAppWebViewInitialData(
      data: '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="utf-8">
          <title>JS Runner</title>
      </head>
      <body>
      </body>
      </html>
      ''',
      mimeType: "text/html",
      encoding: "utf-8",
    ),
    initialSettings: InAppWebViewSettings(
      javaScriptEnabled: true,
      useShouldOverrideUrlLoading: true,
      isInspectable: false,
    ),
    onWebViewCreated: (controller) async {
      _webController = controller;
      // 调用传入的回调函数
      if (onWebViewCreated != null) {
        onWebViewCreated(controller);
      }
    },
    onLoadStop: (controller, url) async {
      _isWebViewReady = true;
      completer.complete();
    },
    onReceivedError: (controller, request, error) async {
      _isWebViewReady = false;
      completer.completeError(error);
    },
  );

  try {
    await _headlessWebView!.run();
    await completer.future;
  } catch (e) {
    _isWebViewReady = false;
    rethrow;
  }
}

// 执行JavaScript代码并自动调用main函数
Future<String?> runjs(String jscode, String? function_name,
    {WebViewCreatedCallback? onWebViewCreated, String? pargs}) async {
  String fn = function_name ?? "main";
  if (!_isWebViewReady || _webController == null) {
    await initJsEnvironment(
      onWebViewCreated: onWebViewCreated ??
          (controller) {
            controller.addJavaScriptHandler(
              //TEST
              handlerName: 'consoleLog',
              callback: (args) {
                print(args.toString().split(', ')[1]);
              },
            );
          },
    );
  }

  try {
    // 先执行传入的JavaScript代码（可能包含函数定义）
    await _webController!.evaluateJavascript(source: jscode);

    // 然后尝试调用main函数并获取结果
    late final result;
    if (pargs != null) {
      result = await _webController!.evaluateJavascript(
          source: 'typeof $fn === "function" ? $fn($pargs) : undefined');
    } else {
      result = await _webController!.evaluateJavascript(
          source: 'typeof $fn === "function" ? $fn() : undefined');
    }
    return result?.toString();
  } catch (e) {
    return null;
  }
}

// 销毁JavaScript环境
Future<void> disposeJsEnvironment() async {
  _isWebViewReady = false;
  _webController = null;
  if (_headlessWebView != null) {
    await _headlessWebView!.dispose();
    _headlessWebView = null;
  }
}

/// Decodes a string argument that may be base64 encoded with the "base64:" prefix
String _decodeArgument(String arg) {
  if (arg.startsWith('base64:')) {
    try {
      // Extract the base64 part and decode it
      String base64Content = arg.substring(7); // Remove "base64:" prefix
      List<int> bytes = base64Decode(base64Content);
      String decodedString = utf8.decode(bytes);
      // Decode any URL-encoded content that might have been encoded
      decodedString = Uri.decodeComponent(decodedString);
      return decodedString;
    } catch (e) {
      // If there's an error in decoding, return the original argument
      return arg;
    }
  } else {
    // If no base64 prefix, return the argument as is for backward compatibility
    // Remove quotes if they're present
    if (arg.startsWith('"') && arg.endsWith('"')) {
      return arg.substring(1, arg.length - 1);
    }
    return arg;
  }
}

ApiCallResult? api_call(String api,{String? bundle_name}) {
  //TODO 完善ApiCall
  //先将由空格分开的api命令通过空格拆分成列表（如果空格由双引号包裹则计入一项）
  List<String> api_list = _parseCommand(api);
  //将列表中的第一个元素作为命令
  String command = api_list[0];
  //将列表中的剩余元素作为参数
  List<String> cargs = api_list.sublist(1);
  List<String> api_path = cargs[0].split("/");
  //根据命令执行相应的操作
  // Apply base64 decoding to all arguments for backward compatibility
  cargs = cargs.map((arg) => _decodeArgument(arg)).toList();
  api_path = cargs[0].split("/");
  
  switch (command) {
    case "print":
      print((bundle_name ?? "")+":"+cargs[0]);
      break;
    case "test":
      print("test_call:" + cargs[0]);
      break;
    case "api_call":
      
      switch (api_path[0]) {
        case "show_dialog":
          //弹窗
          //获取内容参数
          List<String> args = cargs.sublist(1);
          return ApiCallResult(true, null, () => {});
      }
      break;
    case "ui_api":
      //js端调用代码：window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01', 'base64:encodedXmlString']);
      switch (api_path[0]) {
        case "change_ui":
          //修改UI
          //获取内容参数
          List<String> args = cargs.sublist(1);
          String id = args[0];
          String ui_code = args[1];
          
          // The ui_code is already decoded by _decodeArgument
          
            // 更新指定应用的UI组件
            if (bundle_name != null) {
              try {
                final fxcKey = getFxcKeyByBundleName(bundle_name);
                if (fxcKey != null && fxcKey.currentState != null) {
                  // 检查状态是否已挂载，避免在组件未准备好时调用setState
                  if (fxcKey.currentWidget != null && fxcKey.currentState!.mounted) {
                    // 调用 FxcView 的 updateWidget 方法
                    fxcKey.currentState!.updateWidget(id, _parseXmlElement(ui_code));
                  } else {
                    print('FxcView not mounted, skipping UI update for bundle: $bundle_name');
                  }
                } else {
                  print('FxcKey not found or not initialized for bundle: $bundle_name');
                }
              } catch (e) {
                print('Error updating UI for bundle $bundle_name: $e');
              }
            } else {
              print('Bundle name is null, cannot update UI');
            }
            return ApiCallResult(true, null, () => {});
      }
      break;
    case "get_system_info":
      break;
  }

  return ApiCallResult(false);
}

/// 解析命令行字符串，正确处理引号包裹的参数
List<String> _parseCommand(String command) {
  final List<String> result = [];
  final RegExp regExp = RegExp(r'"([^"]*)"|(\S+)');
  final Iterable<RegExpMatch> matches = regExp.allMatches(command);

  for (final match in matches) {
    String? arg = match.group(1) ?? match.group(2);
    if (arg != null) {
      result.add(arg);
    }
  }

  return result;
}

/// 将 XML 字符串转换为 Flutter Widget（单个 Widget，兼容旧系统）
Widget _parseXmlElement(String xmlString) {
  try {
    // 解析 XML 字符串
    final document = XmlDocument.parse('<root>$xmlString</root>');
    if (document.rootElement.children.isNotEmpty) {
      final element = document.rootElement.children.first;
      if (element is XmlElement) {
        // Need to create a simple function to build widgets from XML elements
        // Since the full implementation was in the removed functions, I'll implement a basic version
        return _buildWidgetFromElement(element.name.local, element.attributes, element.children);
      }
    }
    return Container(); // 如果解析失败，返回空容器
  } catch (e) {
    print('Error parsing XML: $e');
    return Container(); // 解析失败时返回空容器
  }
}

/// 根据 XML 元素创建对应的 Flutter Widget（简化版）
Widget _buildWidgetFromElement(String elementName, List<XmlAttribute> attributes, List<XmlNode> children) {
  switch (elementName) {
    case "Text":
      String data = "";
      double? fontSize;
      for (XmlAttribute arg in attributes) {
        if (arg.name.toString() == "data") {
          data = arg.value.toString();
        } else if (arg.name.toString() == "font_size") {
          fontSize = double.tryParse(arg.value);
        }
      }
      return Text(data, style: TextStyle(fontSize: fontSize));
    case "SizeBox":
      double? width;
      double? height;
      for (XmlAttribute arg in attributes) {
        if (arg.name.toString() == "width") {
          width = double.tryParse(arg.value);
        } else if (arg.name.toString() == "height") {
          height = double.tryParse(arg.value);
        }
      }
      return SizedBox(width: width, height: height);
    case "Container":
      double? width, height;
      Color? color;
      for (XmlAttribute arg in attributes) {
        if (arg.name.toString() == "width") {
          width = double.tryParse(arg.value);
        } else if (arg.name.toString() == "height") {
          height = double.tryParse(arg.value);
        } else if (arg.name.toString() == "color") {
          color = _getColorByName(arg.value);
        }
      }
      return Container(
        width: width,
        height: height,
        color: color,
        child: _getChildWidgetFromNodes(children),
      );
    case "Center":
      Widget? child = _getChildWidgetFromNodes(children);
      return Center(child: child);
    default:
      // If it's not a recognized widget, return a container with the element name
      return Container(child: Text('Unknown widget: $elementName'));
  }
}

/// 从 XML 节点列表获取单个子 Widget
Widget? _getChildWidgetFromNodes(List<XmlNode> nodes) {
  for (var child in nodes) {
    if (child is XmlElement) {
      return _buildWidgetFromElement(child.name.local, child.attributes, child.children);
    }
  }
  return null;
}

/// 从颜色名称获取 Color 对象
Color _getColorByName(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    case 'purple':
      return Colors.purple;
    case 'orange':
      return Colors.orange;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'grey':
    case 'gray':
      return Colors.grey;
    case 'transparent':
      return Colors.transparent;
    default:
      return Colors.transparent; // 默认透明色
  }
}


