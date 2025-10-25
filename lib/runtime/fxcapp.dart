import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

class FxcView extends StatefulWidget {
  final String appCode;
  final Function(String)? func;
  
  const FxcView({required this.appCode, this.func, super.key});

  @override
  State<FxcView> createState() => FxcViewState();
}

class FxcViewState extends State<FxcView> {
  final Map<String, Widget> _idToWidget = {};

  void updateWidget(String id, Widget widget) {
    setState(() {
      _idToWidget[id] = widget;
    });
  }

  List<Widget> _parseXml(String appCode) {
    final xml = XmlDocument.parse(appCode);
    List<Widget> widgets = [];
    for (var node in xml.rootElement.children) {
      if (node is XmlElement) {
        widgets.add(_getWidgetFromName(node.name.local, node.attributes, node.children));
      }
    }
    return widgets;
  }

  Widget _getWidgetFromName(String cn, List<XmlAttribute> attributes, List<XmlNode> children) {
    // 检查是否有id属性
    String? id;
    for (var attr in attributes) {
      if (attr.name.toString() == 'id') {
        id = attr.value;
        break;
      }
    }

    Widget result = _buildWidget(cn, attributes, children);
    
    // 如果有id，则用IdWrapper包装
    if (id != null) {
      return IdWrapper(id: id, child: result);
    }
    return result;
  }

  Widget _buildWidget(String cn, List<XmlAttribute> attributes, List<XmlNode> children) {
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
            children: _getChildrenWidgetFromParents(children),
            mainAxisAlignment: (mainAxisAlignment != null)
                ? mainAxisAlignment
                : MainAxisAlignment.start);
      case "ListView":
        return ListView(
            shrinkWrap: true, children: _getChildrenWidgetFromParents(children));
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
            children: _getChildrenWidgetFromParents(children),
            mainAxisAlignment: (mainAxisAlignment != null)
                ? mainAxisAlignment
                : MainAxisAlignment.start);
      case "Center":
        if (_getChildrenWidgetFromParents(children).length <= 0) {
          break;
        }
        return Center(child: _getChildrenWidgetFromParents(children)[0]);
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
                  widget.func!(function_name);
                };
              }
              break;
          }
        }
        return TextButton(
          child: _getChildrenWidgetFromParents(children)[0],
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

  List<Widget> _getChildrenWidgetFromParents(List<XmlNode> children) {
    List<Widget> widgets = [];
    for (var child in children) {
      if (child is XmlElement) {
        //解析标签
        //child.name.local标签名称
        //child.children标签子元素
        //child.attributes参数列表
        widgets.add(_getWidgetFromName(
            child.name.local, child.attributes, child.children));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: _parseXml(widget.appCode));
  }
}

class IdWrapper extends StatelessWidget {
  final String id;
  final Widget child;

  const IdWrapper({required this.id, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<FxcViewState>();
    if (state != null && state._idToWidget.containsKey(id)) {
      return state._idToWidget[id]!;
    }
    return child;
  }
}

