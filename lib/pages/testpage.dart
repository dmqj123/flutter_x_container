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
<Column mainAxisAlignment="end">

<Text
        data="Flutter Xml Widget"
        font_size="20"
        />
  <Center>
    <Row mainAxisAlignment="center">
    <TextButton><Text data="Click Me"/></TextButton><Text data="666"></Text>
    <SizeBox width="150"/>
    <TextButton><Text data="Click Me"/></TextButton></Row>
  </Center>
</Column>
</xml>
""")
          ],
        ));
  }
}
