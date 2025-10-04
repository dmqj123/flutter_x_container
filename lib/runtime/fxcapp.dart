import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

Widget? FxcToWidget(String app_code) {
    List<Widget> widgets = [];
    //解析
    app_code = """
  <!-- 根布局：垂直排列的计算器界面 -->
<FlutterLayout 
    type="Column" 
    mainAxisAlignment="center" 
    crossAxisAlignment="center"
    padding="16,16,16,16"
    backgroundColor="#f5f5f5">

    <!-- 1. 显示区域：顶部输入/结果框 -->
    <Widget 
        type="Container" 
        id="calc_display"
        width="match_parent" 
        height="80"
        margin="0,0,0,20"
        padding="16,16,16,16"
        backgroundColor="#ffffff"
        borderRadius="8"
        borderColor="#e0e0e0"
        borderWidth="1">
        
        <Widget 
            type="Text" 
            id="display_text"
            text="0" 
            textAlign="right"
            fontSize="28"
            fontWeight="bold"
            textColor="#333333" />
    </Widget>

    <!-- 2. 按钮区域：4列网格布局 -->
    <Widget 
        type="GridView" 
        id="button_grid"
        width="match_parent" 
        crossAxisCount="4"  <!-- 4列 -->
        crossAxisSpacing="8"  <!-- 列间距 -->
        mainAxisSpacing="8">  <!-- 行间距 -->

        <!-- 第一行按钮 -->
        <Widget 
            type="ElevatedButton" 
            id="btn_clear"
            text="C"
            textColor="#ffffff"
            backgroundColor="#ff5722"
            borderRadius="8"
            onClick="UI_UPDATE_TEXT|display_text|0" />  <!-- 点击清空显示 -->

        <Widget 
            type="ElevatedButton" 
            id="btn_backspace"
            text="←"
            textColor="#ffffff"
            backgroundColor="#ff5722"
            borderRadius="8"
            onClick="UI_UPDATE_TEXT|display_text|{{substring(display_text,0,-1)}}" />  <!-- 点击删最后一位（示例命令，实际需解析substring逻辑） -->

        <Widget 
            type="ElevatedButton" 
            id="btn_percent"
            text="%"
            textColor="#333333"
            backgroundColor="#e0e0e0"
            borderRadius="8"
            onClick="UI_UPDATE_TEXT|display_text|{{display_text}}%" />  <!-- 点击加百分号 -->

        <Widget 
            type="ElevatedButton" 
            id="btn_divide"
            text="÷"
            textColor="#ffffff"
            backgroundColor="#ff9800"
            borderRadius="8"
            onClick="UI_UPDATE_TEXT|display_text|{{display_text}}÷" />  <!-- 点击加除号 -->

        <!-- 第二行按钮：7/8/9/× -->
        <Widget type="ElevatedButton" id="btn_7" text="7" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}7" />
        <Widget type="ElevatedButton" id="btn_8" text="8" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}8" />
        <Widget type="ElevatedButton" id="btn_9" text="9" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}9" />
        <Widget type="ElevatedButton" id="btn_multiply" text="×" textColor="#ffffff" backgroundColor="#ff9800" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}×" />

        <!-- 第三行按钮：4/5/6/- -->
        <Widget type="ElevatedButton" id="btn_4" text="4" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}4" />
        <Widget type="ElevatedButton" id="btn_5" text="5" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}5" />
        <Widget type="ElevatedButton" id="btn_6" text="6" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}6" />
        <Widget type="ElevatedButton" id="btn_minus" text="-" textColor="#ffffff" backgroundColor="#ff9800" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}-" />

        <!-- 第四行按钮：1/2/3/+ -->
        <Widget type="ElevatedButton" id="btn_1" text="1" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}1" />
        <Widget type="ElevatedButton" id="btn_2" text="2" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}2" />
        <Widget type="ElevatedButton" id="btn_3" text="3" textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}3" />
        <Widget type="ElevatedButton" id="btn_plus" text="+" textColor="#ffffff" backgroundColor="#ff9800" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}+" />

        <!-- 第五行按钮：0/./= -->
        <Widget 
            type="ElevatedButton" 
            id="btn_0"
            text="0"
            textColor="#333333"
            backgroundColor="#ffffff"
            borderRadius="8"
            width="match_parent"  <!-- 占2列宽度 -->
            crossAxisSpan="2"
            onClick="UI_UPDATE_TEXT|display_text|{{display_text}}0" />

        <Widget type="ElevatedButton" id="btn_dot" text="." textColor="#333333" backgroundColor="#ffffff" borderRadius="8" onClick="UI_UPDATE_TEXT|display_text|{{display_text}}." />
        <Widget 
            type="ElevatedButton" 
            id="btn_equal"
            text="="
            textColor="#ffffff"
            backgroundColor="#ff9800"
            borderRadius="8"
            onClick="API_CALL|calc_compute|expression={{display_text}}" />  <!-- 调用“计算”接口 -->
    </Widget>
</FlutterLayout>
"""; //模拟界面数据
    final xml = XmlDocument.parse(app_code);
    print(xml.attributes);
}
