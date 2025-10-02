import 'package:flutter_x_container/class.dart' show ApiCallResult;
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;



ApiCallResult? api_call(String api) {
  //先将由空格分开的api命令通过空格拆分成列表（如果空格由双引号包裹则计入一项）
  List<String> api_list = api.split(RegExp(r'[ ]+'));
  //将列表中的第一个元素作为命令
  String command = api_list[0];
  //将列表中的剩余元素作为参数
  List<String> cargs = api_list.sublist(1);
  //根据命令执行相应的操作
  switch (command) {
    case "api_call":
      List<String> api_path = cargs[0].split("/");
      switch (api_path[0]) {
        case "show_dialog":
          //弹窗
          //获取内容参数
          List<String> args = cargs.sublist(1);
          return ApiCallResult("success", ()=>{});
      }
      break;
  }
  //return;
}
