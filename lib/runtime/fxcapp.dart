import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

Widget FxcToWidget(String app_code) {
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
          GetWidgetFromName(node.name.local, node.attributes, node.children));
    }
  }

  return Column(children: widgets);
}

List<Widget> GetChildrenWidgetFromParents(List children) {
  List<Widget> widgets = [];
  for (var child in children) {
    if (child is XmlElement) {
      //解析标签
      //child.name.local标签名称
      //child.children标签子元素
      //child.attributes参数列表
      widgets.add(GetWidgetFromName(
          child.name.local, child.attributes, child.children));
    }
  }
  return widgets;
}

Widget GetWidgetFromName(String cn, List attributes, List children) {
  switch (cn) {
    case "Column":
      return Column(children: GetChildrenWidgetFromParents(children));
    case "Center":
      if (GetChildrenWidgetFromParents(children).length <= 0) {
        break;
      }
      return Center(
          child: GetChildrenWidgetFromParents(
              children)[0]);
    case "TextButton":
        return TextButton(
          child: GetChildrenWidgetFromParents(
              children)[0],
          onPressed: () {},
        );
    case "Text":
      return Text(attributes[0].value);
  }
  return Container();
}
