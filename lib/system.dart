import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_x_container/class.dart' show ApiCallResult;
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;

// 创建一个持久的HeadlessInAppWebView实例
HeadlessInAppWebView? _headlessWebView;
InAppWebViewController? _webController;
bool _isWebViewReady = false;

// 初始化WebView环境
Future<void> initJsEnvironment() async {
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
          List<String> command = args.toString().split(', ');
          //TODO 处理fxc命令
        },
      );
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
Future<String?> runjs(String jscode,String? function_name) async {
  String fn = function_name ?? "main";
  if (!_isWebViewReady || _webController == null) {
    await initJsEnvironment();
  }

  try {
    // 先执行传入的JavaScript代码（可能包含函数定义）
    await _webController!.evaluateJavascript(source: jscode);
    
    // 然后尝试调用main函数并获取结果
    final result = await _webController!.evaluateJavascript(
        source: 'typeof $fn === "function" ? $fn() : undefined');
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

ApiCallResult? api_call(String api) {
  //先将由空格分开的api命令通过空格拆分成列表（如果空格由双引号包裹则计入一项）
  List<String> api_list = api.split(RegExp(r'[ ]+'));
  //将列表中的第一个元素作为命令
  String command = api_list[0];
  //将列表中的剩余元素作为参数
  List<String> cargs = api_list.sublist(1);
  //根据命令执行相应的操作
  switch (command) {
    case "test":
      print("test_call:"+cargs[0]);
    case "api_call":
      List<String> api_path = cargs[0].split("/");
      switch (api_path[0]) {
        case "show_dialog":
          //弹窗
          //获取内容参数
          List<String> args = cargs.sublist(1);
          return ApiCallResult(true, null, () => {});
      }
      break;
    case "ui_api":
      break;
    case "get_system_info":
      break;
  }

  return ApiCallResult(false);
}
