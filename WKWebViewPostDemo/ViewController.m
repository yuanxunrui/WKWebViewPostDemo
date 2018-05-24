//
//  ViewController.m
//  WKWebViewPostDemo
//
//  Created by 袁训锐 on 2018/5/24.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "ViewController.h"
#import "XRWebviewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:btn];
    [btn setBackgroundColor:[UIColor redColor]];
    [btn setTitle:@"点击进行wk-post请求" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(0, 0, 200, 50);
    btn.center = self.view.center;
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)buttonClick{
    XRWebviewController *vc = [[XRWebviewController alloc]init];
    //此处需填写请求url及请求body数据
    vc.htmlString = @"";
    vc.httpBodyInfo = @"";
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
