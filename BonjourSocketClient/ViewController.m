//
//  ViewController.m
//  BonjourSocketClient
//
//  Created by 张树青 on 2017/5/24.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import "ViewController.h"
#import "BonjourSocketClient.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[BonjourSocketClient shareInstance] findServer:@"zhangsan"];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [[BonjourSocketClient shareInstance] sendMessage:@"hello"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
