function main(){
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Hello World!"']);
    window.flutter_inappwebview.callHandler('fxc_api_call',['print','"Hello World!"']);
}

function hellotext(){
    // 使用Base64编码传递XML字符串，避免引号转义问题
    const xmlString = '<Text data="Welcome!"/>';
    const encodedXml = btoa(encodeURIComponent(xmlString));
    window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01', encodedXml]);
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Button Clicked!"']);
}