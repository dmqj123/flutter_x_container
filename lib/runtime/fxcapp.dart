import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

Widget FxcToWidget(String app_code, {Function(String)? func}) {
  List<Widget> widgets = [];
  //解析
  final xml = XmlDocument.parse(app_code);
  //遍历xml,解析为List<Widget>
  for (var node in xml.rootElement.children) {
    if (node is XmlElement) {
      //解析标签
      //node.name.local标签名称
      //node.children标签子元素
      widgets.add(
          GetWidgetFromName(node.name.local, node.attributes, node.children, func: func));
    }
  }

  return Column(children: widgets);
}

List<Widget> GetChildrenWidgetFromParents(List children, {Function(String)? func}) {
  List<Widget> widgets = [];
  for (var child in children) {
    if (child is XmlElement) {
      //解析标签
      //child.name.local标签名称
      //child.children标签子元素
      //child.attributes参数列表
      widgets.add(GetWidgetFromName(
          child.name.local, child.attributes, child.children,func: func));
    }
  }
  return widgets;
}

Widget GetWidgetFromName(String cn, List attributes, List children ,  {Function(String)? func}) {
  switch (cn) {
    case "Column":
      MainAxisAlignment? mainAxisAlignment;
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
            }
            break;
        }
      }
      return Column(
          children: GetChildrenWidgetFromParents(children,func: func),
          mainAxisAlignment: (mainAxisAlignment != null)
              ? mainAxisAlignment
              : MainAxisAlignment.start);
    case "ListView":
      return ListView(
          shrinkWrap: true, children: GetChildrenWidgetFromParents(children,func: func));
    case "Row":
      MainAxisAlignment? mainAxisAlignment;
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
            }
            break;
        }
      }
      return Row(
          children: GetChildrenWidgetFromParents(children,func: func),
          mainAxisAlignment: (mainAxisAlignment != null)
              ? mainAxisAlignment
              : MainAxisAlignment.start);
    case "Center":
      if (GetChildrenWidgetFromParents(children).length <= 0) {
        break;
      }
      return Center(child: GetChildrenWidgetFromParents(children,func: func)[0]);
    case "TextButton":
      void Function()? onPressed;
      for (XmlAttribute arg in attributes) {
        switch (arg.name.toString()) {
          case "onclick":
            //格式#fxcf:function_name()
            //检测是否以#fxcf:开头且以()结尾
            if (arg.value.startsWith("#fxcf:") && arg.value.endsWith("()")) {
              //获取函数名称
              String function_name = arg.value.substring(6, arg.value.length - 2);
              onPressed = () {
                //调用函数
                func!(function_name);
              };
            }
            break;
        }
      }
      return TextButton(
        child: GetChildrenWidgetFromParents(children,func: func)[0],
        onPressed: onPressed,
      );
    case "Text":
      double? font_size;
      String data = "";
      if (attributes.length >= 1) {
        for (XmlAttribute arg in attributes) {
          switch (arg.name.toString()) {
            case "data":
              data = arg.value.toString();
              break;
            case "font_size":
              font_size = double.parse(arg.value);
              break;
          }
        }
      }
      return Text(
        data,
        style: TextStyle(fontSize: (font_size ?? null)),
      );
    case "SizeBox":
      double? width;
      double? height;
      if (attributes.length >= 0) {
        for (XmlAttribute arg in attributes) {
          switch (arg.name.toString()) {
            case "width":
              width = double.parse(arg.value);
              break;
            case "height":
              height = double.parse(arg.value);
              break;
          }
        }
      }
      return SizedBox(
        width: width,
        height: height,
      );
  }
  return Container();
}
