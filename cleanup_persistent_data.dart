import 'dart:io';
import 'package:path/path.dart' as path;

/// 一个脚本，用于清理FlutterX Container的持久化数据
void main() async {
  // 清理Windows下的持久化数据
  String? appData = Platform.environment['APPDATA'];
  if (appData != null) {
    String appDirPath = path.join(appData, 'FlutterXContainer');
    Directory appDir = Directory(appDirPath);
    if (await appDir.exists()) {
      print('正在删除 $appDirPath 目录...');
      await appDir.delete(recursive: true);
      print('已删除持久化数据目录');
    } else {
      print('没有找到持久化数据目录: $appDirPath');
    }
  }
  
  print('清理完成。现在重新运行应用时，所有数据都会重新初始化。');
}