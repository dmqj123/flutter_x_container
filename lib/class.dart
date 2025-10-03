import 'package:flutter/widgets.dart';

class OpenAppResult {
  late final bool success;
  late final String? message;
  late final Widget? page;

  OpenAppResult(this.success, [this.message, this.page]);
}

class Applnk {
  late final String name;
  late final String icon_path;
  late final String? bundle_name;

  Applnk(this.name, this.icon_path, [this.bundle_name]);

  // 添加toJson方法
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon_path,
      'bundle_name': bundle_name,
    };
  }

  // 添加fromJson工厂构造函数
  factory Applnk.fromJson(Map<String, dynamic> json) {
    return Applnk(
      json['name'],
      json['icon'],
      json['bundle_name'],
    );
  }
}

class Appbundle {
  late final String name;
  late final String bundle_name;
  late final String version;
  late final String icon_path;
  late final String description;
  late final String author;
  late final String min_version;
  late final String permissions;
  late final String main_code_path;

  Appbundle(
      this.name,
      this.bundle_name,
      this.version,
      this.icon_path,
      this.description,
      this.author,
      this.min_version,
      this.permissions,
      this.main_code_path);
}

class ApiCallResult{
  late bool success;
  String? return_value;
  Map<dynamic, dynamic>? Function() api_func = ()=>{}; //函数操作

  static Map<dynamic, dynamic>? _defaultApiFunc() {
    return {};
  }

  ApiCallResult(this.success,[this.return_value, this.api_func=_defaultApiFunc]);
}