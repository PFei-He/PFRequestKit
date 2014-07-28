//
//  Demo.m
//  PFRequestKit
//
//  Created by PFei_He on 14-7-18.
//  Copyright (c) 2014年 PFei_He. All rights reserved.
//

#import "Demo.h"
#import "PFRequestKit.h"

@interface Demo ()

@end

@implementation Demo

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //设置请求的主机地址
    [PFRequestSingleton sharedInstance].baseURL = @"http://www.weather.com.cn/data/sk";

    //设置超时，单位为秒（默认为8秒）
    [PFRequestSingleton sharedInstance].timeoutInterval = 30;

    NSArray *array = @[@"GET", @"GET&PARAMS", @"HEAD", @"POST"];
    for (int i = 0; i < array.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        if (i < 3) button.frame = CGRectMake(10 + (100 * i), 100, 100, 100);
        else button.frame = CGRectMake(10 + (100 * (i - 3)), 100 * 2, 100, 100);
        [button setTitle:array[i] forState:UIControlStateNormal];
        [button setTag:i];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

#pragma mark - Event

//button点击事件
- (void)buttonClick:(UIButton *)button
{
    switch (button.tag) {
        case 0:
            [self baseRequestGet];
            break;
        case 1:
            [self baseRequestGetWithParams];
            break;
        case 2:
            [self baseRequestHead];
            break;
        case 3:
            [self baseRequestPost];
        default:
            break;
    }
}

#pragma mark - PFBaseRequest Methods

//get请求（不带参数）
- (void)baseRequestGet
{
    [PFBaseRequest getPath:@"101281101.html" params:nil completion:^(id result, NSError *error) {
        NSLog(@"Completion: %@", result);
        NSLog(@"Error: %@", error);
    }];
}

//get请求（带参数）
- (void)baseRequestGetWithParams
{
    //设置请求参数
    if (params == nil) params = @{@"": @"", @"": @""};

    [PFBaseRequest getPath:@"接口地址" params:params completion:^(id result, NSError *error) {
        NSLog(@"Completion: %@", result);
        NSLog(@"Error: %@", error);
    }];
}

//head请求（请求HTTP头文件，也叫请求头）
- (void)baseRequestHead
{
    [PFBaseRequest headPath:@"101281101.html" params:nil completion:^(id result, NSError *error) {
        NSLog(@"Completion: %@", result);
        NSLog(@"Error: %@", error);
    }];
}

//post请求
- (void)baseRequestPost
{
    //设置请求参数
    if (params == nil) params = @{@"": @"", @"": @""};

    [PFBaseRequest postPath:@"接口地址" params:params completion:^(id result, NSError *error) {
        NSLog(@"Completion: %@", result);
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Memory Management Methods

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
