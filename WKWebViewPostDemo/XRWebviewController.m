//
//  XRWebviewController.m
//
//  Created by yuanxunrui on 18/5/22.
//  Copyright © 2018年 yuanxunrui. All rights reserved.
//

#import "XRWebviewController.h"
#import <WebKit/WebKit.h>

#define POST_JS @"function my_post(path, params) {\
var method = \"POST\";\
var form = document.createElement(\"form\");\
form.setAttribute(\"method\", method);\
form.setAttribute(\"action\", path);\
for(var key in params){\
if (params.hasOwnProperty(key)) {\
var hiddenFild = document.createElement(\"input\");\
hiddenFild.setAttribute(\"type\", \"hidden\");\
hiddenFild.setAttribute(\"name\", key);\
hiddenFild.setAttribute(\"value\", params[key]);\
}\
form.appendChild(hiddenFild);\
}\
document.body.appendChild(form);\
form.submit();\
}"
#define func()  NSLog(@"%s", __FUNCTION__);

@interface XRWebviewController () <WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate,UIWebViewDelegate>

@property (nonatomic, strong) WKWebView *wk_webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIWebView *ui_webView;

@end

@implementation XRWebviewController

- (void)loadView{
    [super loadView];
    [self.view setBackgroundColor:[UIColor cyanColor]];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 添加进入条
    self.progressView = [[UIProgressView alloc] init];
    self.progressView.frame = self.view.bounds;
    [self.view addSubview:self.progressView];
    self.progressView.backgroundColor = [UIColor redColor];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStyleDone target:self action:@selector(goback)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"前进" style:UIBarButtonItemStyleDone target:self action:@selector(gofarward)];

    //拼装请求post数据
    if(!self.httpBodyInfo){
        NSLog(@"self.httpbody = nil,执行中断");
        return;
    }
    NSString *requestData = [NSString stringWithFormat:@"jsonRequestData=%@",self.httpBodyInfo];
    NSLog(@"");
#if 1
    //WKWebView
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    // 设置偏好设置
    config.preferences = [[WKPreferences alloc] init];
    // 默认为0
    config.preferences.minimumFontSize = 10;
    // 默认认为YES
    config.preferences.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示不能自动通过窗口打开
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    // web内容处理池
    config.processPool = [[WKProcessPool alloc] init];
    
    // 通过JS与webview内容交互
    config.userContentController = [[WKUserContentController alloc] init];
    // 注入JS对象名称AppModel，当JS通过AppModel来调用时，
    // 我们可以在WKScriptMessageHandler代理中接收到
    [config.userContentController addScriptMessageHandler:self name:@"jsonRequestData"];
    [config.userContentController addScriptMessageHandler:self name:@"commitinfo"];
    self.wk_webView = [[WKWebView alloc] initWithFrame:self.view.bounds
                                      configuration:config];
    
    
    // 导航代理
    self.wk_webView.navigationDelegate = self;
    // 与webview UI交互代理
    self.wk_webView.UIDelegate = self;
    
    // 添加KVO监听
    [self.wk_webView addObserver:self
                   forKeyPath:@"loading"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self.wk_webView addObserver:self
                   forKeyPath:@"title"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self.wk_webView addObserver:self
                   forKeyPath:@"estimatedProgress"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self.view addSubview:self.wk_webView];

    //WKWebView方式集成
    
    NSData *postData = [requestData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)postData.length];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.htmlString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.wk_webView loadRequest:request];
    
#else
    NSLog(@"##########UIWebView方式集成###############");
    //UIWebView
    
    [self.view addSubview:self.web];
    self.ui_webView.frame = self.view.bounds;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: [NSURL URLWithString:self.htmlString]];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [requestData dataUsingEncoding: NSUTF8StringEncoding]];
    [self.ui_webView loadRequest: request];
#endif
    
    
}
#pragma mark 懒加载
- (UIWebView *)web{
    if(!_ui_webView){
        _ui_webView = [[UIWebView alloc]init];
        _ui_webView.delegate = self;
        
        _ui_webView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        _ui_webView.suppressesIncrementalRendering = YES;
        
        _ui_webView.opaque = YES;
    }
    return _ui_webView;
}
- (NSString *)htmlString{
    
    if([_htmlString isKindOfClass:[NSNull class]]||_htmlString.length==0||!_htmlString||![_htmlString containsString:@"http"]){
        return nil;
    }
    return _htmlString;
}
- (NSString *)httpBodyInfo{
    if(!_httpBodyInfo||_httpBodyInfo.length==0||[_httpBodyInfo isKindOfClass:[NSNull class]]){
        return nil;
    }
    return _httpBodyInfo;
}
#pragma mark wk 前进/后退
- (void)goback {
    if ([self.wk_webView canGoBack]) {
        [self.wk_webView goBack];
    }
}

- (void)gofarward {
    if ([self.wk_webView canGoForward]) {
        [self.wk_webView goForward];
    }
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
}
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"jsonRequestData"]) {
        // 打印所传过来的参数，只支持NSNumber, NSString, NSDate, NSArray,
        // NSDictionary, and NSNull类型
        NSLog(@"%@", message.body);
    }
    else if ([message.name isEqualToString:@"commitinfo"]){
        NSLog(@"%@",message.body);
    }
}
/**
 测试数据*/
- (NSString *)requestData{
    NSDictionary *jsDict = @{
                             @"charset": @"UTF-8",
                             @"reqData": @{
                                     @"agrNo": @"20180522883775289001228282",
                                     @"amount": @"1.00",
                                     @"branchNo": @"0010",
                                     @"cardType": @"A",
                                     @"date": @"20180522",
                                     @"dateTime": @"20180522180115",
                                     @"expireTimeSpan": @"30",
                                     @"merchantNo": @"000417",
                                     @"merchantSerialNo": @"20180522945955272593754388",
                                     @"orderNo": @"180522844246175",
                                     @"payNoticeUrl": @"http://hur2au.natappfree.cc/gateway/recharge/zsnotifypay",
                                     @"signNoticeUrl": @"http://hur2au.natappfree.cc/gateway/recharge/zsnotifysign"
                                     },
                             @"sign": @"E49EA6B382668EC1D9AA862DF61CE7F82470AF03379B588CAC83D41A7360F7C0",
                             @"signType": @"SHA-256",
                             @"version": @"1.0",
                             @"Content-Type" : @"application/json"
                             };
    NSError *error;
    NSString *jsStr;
    NSData *jsData = [NSJSONSerialization dataWithJSONObject:jsDict options:NSJSONWritingPrettyPrinted  error:&error];
    if(jsData){
        jsStr = [[NSString alloc]initWithData:jsData encoding:NSUTF8StringEncoding];
    }
    return jsStr;
    
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"loading"]) {
        NSLog(@"loading");
    } else if ([keyPath isEqualToString:@"title"]) {
        self.title = self.wk_webView.title;
    } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"progress: %f", self.wk_webView.estimatedProgress);
        self.progressView.progress = self.wk_webView.estimatedProgress;
    }
    
    // 加载完成
    if (self.wk_webView.loading) {
        [UIView animateWithDuration:0.5 animations:^{
            self.progressView.alpha = 0;
        }];
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *hostname = navigationAction.request.URL.host.lowercaseString;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated
        && ![hostname containsString:@".baidu.com"]) {
        // 对于跨域，需要手动跳转
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        
        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        self.progressView.alpha = 1.0;
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    
    func()
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
    func()
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    func()
    
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    func()
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    func()
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    func()
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    func()
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler {
    func()
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    func()
}

#pragma mark - WKUIDelegate
- (void)webViewDidClose:(WKWebView *)webView {
    func()
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    func()
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:@"JS调用alert" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
    NSLog(@"%@", message);
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    func()
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"confirm" message:@"JS调用confirm" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
    
    NSLog(@"%@", message);
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    func()
    
    NSLog(@"%@", prompt);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"textinput" message:@"JS调用输入框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

@end
