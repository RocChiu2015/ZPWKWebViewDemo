//
//  ViewController.m
//  WKWebViewDemo
//
//  Created by 赵鹏 on 2017/12/15.
//  Copyright © 2017年 赵鹏. All rights reserved.
//

/**
 * iOS 8以后才推出了WKWebView控件，用来取代UIWebView控件，所以对于不用适配iOS 8的APP可以采用WKWebView来显示网页；
 * 蓝色的进度条在最顶端，需要注意看才能看的到。
 */

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIProgressView *progressBar;
@property (nonatomic, strong)WKUserContentController *userContentController;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%s", __func__);
    [self configWebView];
    [self configProgressBar];
}

- (void)configWebView
{
    //配置环境
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc]init];
    self.userContentController =[[WKUserContentController alloc] init];
    
    /**
     * 注册方法；
     * 在下面的代码中设置执行WKScriptMessageHandler协议的类为自己；
     * name:后面的参数为注册的一个方法名，是js调用OC时候的桥梁，在网页中的js代码中也要写这个方法名，当调用js的时候一检测到这个方法名，系统就会调用WKScriptMessageHandler协议的代理方法，并且给OC传送参数，从而完成了js调用OC的目的。
     */
    [self.userContentController addScriptMessageHandler:self name:@"jsCallOC"];
    configuration.userContentController = self.userContentController;
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    
    //加载本地网页
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JSCallOC.html" ofType:nil];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    [webView loadFileURL:url allowingReadAccessToURL:url];
//    [webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    
    //webView的进度条
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.view addSubview:webView];
    self.webView = webView;
}

- (void)configProgressBar
{
    UIProgressView *progressgBar = [[UIProgressView alloc] init];
    progressgBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 3);
    progressgBar.progress = 0.0;
    progressgBar.tintColor = [UIColor blueColor];
    [self.view addSubview:progressgBar];
    self.progressBar = progressgBar;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath  isEqual: @"estimatedProgress"]) {
        self.progressBar.alpha = 1.0;
        [self.progressBar setProgress:self.webView.estimatedProgress animated:true];
        //进度条的值最大为1.0
        if (self.webView.estimatedProgress >= 1) {
            [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.progressBar.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.progressBar.progress = 0;
            }];
        }
    }
}

#pragma WKNavigatonDelegate
/**
 *  在发送请求之前，决定是否跳转
 *
 *  @param webView          实现该代理的webview
 *  @param navigationAction 当前navigation
 *  @param decisionHandler  是否调转block
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
//    //如果请求的是百度地址，则延迟5s以后跳转
//    if ([navigationAction.request.URL.host.lowercaseString isEqual:@"www.baidu.com"])
//    {
//        //延迟5s之后跳转
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            //允许跳转
//            decisionHandler(WKNavigationActionPolicyAllow);
//        });
//
//        return;
//    }else  //如果请求的不是百度的地址，则不允许跳转
//    {
//        //不允许跳转
//        decisionHandler(WKNavigationActionPolicyCancel);
//    }
    
    NSLog(@"%@",navigationAction.request.URL.absoluteString);
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
}

/**
 *  页面开始加载时调用
 *  在网页（外部或者内部）的时候，诸如百度、新浪之类的，程序在调用完下面的方法之后会过三四秒钟的时间才再调用decidePolicyForNavigationResponse方法了，原因是网站的响应时间有个三四秒钟。
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s", __FUNCTION__);
}

/**
 *  在收到响应后，决定是否跳转
 *
 *  @param webView            实现该代理的webview
 *  @param navigationResponse 当前navigation
 *  @param decisionHandler    是否跳转block
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    // 允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
}

/**
 *  当内容开始返回时调用
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s", __FUNCTION__);
}

/**
 *  页面加载完成之后调用(OC调用JS)；
 *  比如我们的h5页面有个全局的js方法叫ocCallJs()，该方法返回一个字符串。因为js代码调用是异步的，所以使用block做为回调就可以拿到js方法返回的数据，这一点UIWebView是做不到的。
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s", __func__);
    
    [webView evaluateJavaScript:@"window.ocCallJs()" completionHandler:^(id _Nullable resualt, NSError * _Nullable error) {
        NSLog(resualt);
    }];
}

/**
 *  加载失败时调用
 *
 *  @param webView    实现该代理的webview
 *  @param navigation 当前navigation
 *  @param error      错误
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%s", __FUNCTION__);
}

/**
 页面加载失败之后调用
 
 @param webView 实现该代理的webview
 @param navigation 当前navigation
 @param error 错误
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%s", __func__);
}

/**
 *  接收到服务器跳转请求之后调用
 *
 *  @param webView      实现该代理的webview
 *  @param navigation   当前navigation
 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma WKUIDelegate
/**
 * 这个代理主要处理一些界面弹出提示框相关的；
 * 针对于web界面的三种提示框（警告框、确认框、输入框）分别对应三种代理方法。
 */

//创建一个新的WebView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    return [[WKWebView alloc]init];
}

//输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler
{
    completionHandler(@"http");
}

//确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    completionHandler(YES);
}

//警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"%@",message);
    completionHandler();
}

#pragma WKScriptMessageHandler
/**
 * js调用OC的时候会调用此方法，并且把js中的参数传递过来；
 * 比如我们的h5页面有个按钮，按钮点击回调OC的这个方法，其中点击按钮的js代码需要按照"window.webkit.messageHandlers.注册的方法名.postMessage({body:传输的数据})"这种固定格式进行撰写，其中“注册的方法名”就是在configWebView方法中name:参数后面写的那个方法名"jsCallOC"（方法名不一定非得这么写，只要js和APP里面的名称统一就行），小括号里面的内容就是js传递给OC的参数，如果是需要传递复杂的数据，可以利用字典或者json格式进行传输。
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    WKScriptMessage *message1 = message;
    NSLog(@"%@", message1);
    
    NSLog(@"name:%@\\\\n body:%@\\\\n",message.name,message.body);
}

- (void)dealloc
{
    //这里需要注意，前面增加过的方法一定要remove掉。
    [self.userContentController removeScriptMessageHandlerForName:@"jsCallOC"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

@end
