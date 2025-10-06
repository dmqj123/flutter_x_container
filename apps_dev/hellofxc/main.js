function main(){
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Hello World!"']);
}

function hellotext(){
    window.flutter_inappwebview.callHandler('fxc_api_call',['test','"Button Clicked!"']);
}