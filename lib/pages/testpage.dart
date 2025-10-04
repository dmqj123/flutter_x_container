//测试页面

import 'package:flutter/material.dart';
import 'package:flutter_x_container/runtime/fxcapp.dart';

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('测试页面'),
        ),
        body: Column(
          children: [
            FxcToWidget("""
<xml version="1.0">
<Text
        data="Flutter Xml Widget"/>
<Center>
  <Column>
    <TextButton><Text data="Click Me"/></TextButton>
  </Column>
</Center>
</xml>
""")
          ],
        ));
  }
}
