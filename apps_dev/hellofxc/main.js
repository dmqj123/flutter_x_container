function main(){
    // 测试普通字符串（向后兼容）
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Hello World!"']);
    window.flutter_inappwebview.callHandler('fxc_api_call',['print','"Hello World!"']);
    
    // 测试base64编码的字符串
    const encodedHello = 'base64:' + btoa(encodeURIComponent('Base64 Encoded Hello World!'));
    window.flutter_inappwebview.callHandler('fxc_api_call',['test', encodedHello]);
    window.flutter_inappwebview.callHandler('fxc_api_call',['print', encodedHello]);
}

function hellotext(){
    // 使用Base64编码传递XML字符串，避免引号转义问题
    const xmlString = '<Text data="Welcome!"/>';
    const encodedXml = 'base64:' + btoa(encodeURIComponent(xmlString));
    // 调用Flutter端的ui_api，change_ui命令，将id为text01的组件更新为encodedXml指定的UI
    window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01', encodedXml]);
    // 调用test命令，传递"Button Clicked!"参数
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Button Clicked!"']);

    //等待1秒
    setTimeout(function(){
        // 调用Flutter端的ui_api，change_ui命令，将id为text01的组件更新为encodedXml指定的UI
        window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01', encodedXml]);
    },1000);
    
    // 额外的base64编码示例
    const newTextXml = '<Text data="Flutter X Container" font_size="20" text_color="blue"/>';
    const encodedNewText = 'base64:' + btoa(encodeURIComponent(newTextXml));
    // 再次调用ui_api，change_ui命令更新UI组件
    window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01', encodedNewText]);
}