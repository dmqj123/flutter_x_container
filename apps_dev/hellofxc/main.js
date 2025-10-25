function main(){
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Hello World!"']);
    window.flutter_inappwebview.callHandler('fxc_api_call',['print','"Hello World!"']);
}

function hellotext(){
    window.flutter_inappwebview.callHandler('fxc_api_call',['ui_api','change_ui','text01','"<Text data="Welcome!"/>"']);
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Button Clicked!"']);
}