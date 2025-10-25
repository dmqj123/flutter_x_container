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
      //js端调用代码：window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01', base64EncodedXmlString]);
      switch (api_path[0]) {
        case "change_ui":
          //修改UI
          //获取内容参数
          List<String> args = cargs.sublist(1);
          String id = args[0];
          String ui_code = args[1];
          
          // 尝试解码Base64编码的XML字符串
          try {
            // 首先检查是否是Base64编码的字符串
            if (ui_code.length > 0) {
              // 先尝试Base64解码
              try {
                List<int> bytes = base64Decode(ui_code);
                String decodedXml = utf8.decode(bytes);
                // 对URL编码的内容进行解码
                decodedXml = Uri.decodeComponent(decodedXml);
                ui_code = decodedXml;
              } catch (e) {
                // 如果不是Base64编码，则保持原样
                // 移除引号（如果存在）- 为向后兼容保留
                if (ui_code.startsWith('"') && ui_code.endsWith('"')) {
                  ui_code = ui_code.substring(1, ui_code.length - 1);
                }
              }
            }
            
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
          } catch (e) {
            print('Error decoding UI code: $e');
            return ApiCallResult(false, 'Failed to decode UI code: $e', () => {});
          }
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

/// 将 XML 字符串转换为 Flutter Widget
Widget _parseXmlElement(String xmlString) {
  try {
    // 解析 XML 字符串
    final document = XmlDocument.parse('<root>$xmlString</root>');
    if (document.rootElement.children.isNotEmpty) {
      final element = document.rootElement.children.first;
      if (element is XmlElement) {
        return _getWidgetFromXmlElement(element.name.local, element.attributes, element.children);
      }
    }
    return Container(); // 如果解析失败，返回空容器
  } catch (e) {
    print('Error parsing XML: $e');
    return Container(); // 解析失败时返回空容器
  }
}

/// 根据 XML 元素创建对应的 Flutter Widget
Widget _getWidgetFromXmlElement(String elementName, List<XmlAttribute> attributes, List<XmlNode> children) {
  switch (elementName) {
    case "Column":
      MainAxisAlignment? mainAxisAlignment;
      CrossAxisAlignment? crossAxisAlignment;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "mainAxisAlignment":
            switch (arg.value) {
              case "start":
                mainAxisAlignment = MainAxisAlignment.start;
                break;
              case "end":
                mainAxisAlignment = MainAxisAlignment.end;
                break;
              case "center":
                mainAxisAlignment = MainAxisAlignment.center;
                break;
              case "spaceBetween":
                mainAxisAlignment = MainAxisAlignment.spaceBetween;
                break;
              case "spaceAround":
                mainAxisAlignment = MainAxisAlignment.spaceAround;
                break;
              case "spaceEvenly":
                mainAxisAlignment = MainAxisAlignment.spaceEvenly;
                break;
            }
            break;
          case "crossAxisAlignment":
            switch (arg.value) {
              case "start":
                crossAxisAlignment = CrossAxisAlignment.start;
                break;
              case "end":
                crossAxisAlignment = CrossAxisAlignment.end;
                break;
              case "center":
                crossAxisAlignment = CrossAxisAlignment.center;
                break;
              case "stretch":
                crossAxisAlignment = CrossAxisAlignment.stretch;
                break;
              case "baseline":
                crossAxisAlignment = CrossAxisAlignment.baseline;
                break;
            }
            break;
        }
      }
      return Column(
        children: _getChildrenFromXmlNodes(children),
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      );
    case "ListView":
      return ListView(
        shrinkWrap: true,
        children: _getChildrenFromXmlNodes(children),
      );
    case "Row":
      MainAxisAlignment? mainAxisAlignment;
      CrossAxisAlignment? crossAxisAlignment;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "mainAxisAlignment":
            switch (arg.value) {
              case "start":
                mainAxisAlignment = MainAxisAlignment.start;
                break;
              case "end":
                mainAxisAlignment = MainAxisAlignment.end;
                break;
              case "center":
                mainAxisAlignment = MainAxisAlignment.center;
                break;
              case "spaceBetween":
                mainAxisAlignment = MainAxisAlignment.spaceBetween;
                break;
              case "spaceAround":
                mainAxisAlignment = MainAxisAlignment.spaceAround;
                break;
              case "spaceEvenly":
                mainAxisAlignment = MainAxisAlignment.spaceEvenly;
                break;
            }
            break;
          case "crossAxisAlignment":
            switch (arg.value) {
              case "start":
                crossAxisAlignment = CrossAxisAlignment.start;
                break;
              case "end":
                crossAxisAlignment = CrossAxisAlignment.end;
                break;
              case "center":
                crossAxisAlignment = CrossAxisAlignment.center;
                break;
              case "stretch":
                crossAxisAlignment = CrossAxisAlignment.stretch;
                break;
              case "baseline":
                crossAxisAlignment = CrossAxisAlignment.baseline;
                break;
            }
            break;
        }
      }
      return Row(
        children: _getChildrenFromXmlNodes(children),
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      );
    case "Center":
      final childrenWidgets = _getChildrenFromXmlNodes(children);
      if (childrenWidgets.isNotEmpty) {
        return Center(child: childrenWidgets.first);
      }
      return const Center();
    case "TextButton":
      void Function()? onPressed;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "onclick":
            // 在系统上下文中，我们不能直接调用FxcView的函数，所以暂时设置为空
            onPressed = () {
              print('TextButton clicked, but function execution not available in system context');
            };
            break;
        }
      }
      return TextButton(
        child: _getChildrenFromXmlNodes(children).isNotEmpty 
            ? _getChildrenFromXmlNodes(children).first 
            : const Text('Button'),
        onPressed: onPressed,
      );
    case "Text":
      double? fontSize;
      String data = "";
      Color? textColor;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "data":
            data = arg.value.toString();
            break;
          case "font_size":
            fontSize = double.tryParse(arg.value);
            break;
          case "text_color":
            // 简单的颜色解析，支持基本颜色名称
            textColor = _getColorFromName(arg.value);
            break;
        }
      }
      return Text(
        data,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
        ),
      );
    case "SizeBox":
      double? width;
      double? height;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "width":
            width = double.tryParse(arg.value);
            break;
          case "height":
            height = double.tryParse(arg.value);
            break;
        }
      }
      return SizedBox(
        width: width,
        height: height,
      );
    case "Container":
      double? width, height;
      Color? color;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "width":
            width = double.tryParse(arg.value);
            break;
          case "height":
            height = double.tryParse(arg.value);
            break;
          case "color":
            color = _getColorFromName(arg.value);
            break;
        }
      }
      return Container(
        width: width,
        height: height,
        color: color,
        child: _getChildrenFromXmlNodes(children).isNotEmpty 
            ? _getChildrenFromXmlNodes(children).first 
            : null,
      );
    default:
      return Container(child: Text('Unknown widget: $elementName'));
  }
}

/// 从 XML 节点列表创建子 Widget 列表
List<Widget> _getChildrenFromXmlNodes(List<XmlNode> nodes) {
  List<Widget> widgets = [];
  for (var child in nodes) {
    if (child is XmlElement) {
      widgets.add(_getWidgetFromXmlElement(
          child.name.local, child.attributes, child.children));
    }
  }
  return widgets;
}

/// 从颜色名称获取 Color 对象
Color _getColorFromName(String colorName) {
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
