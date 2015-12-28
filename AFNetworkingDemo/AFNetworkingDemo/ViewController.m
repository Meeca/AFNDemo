//
//  ViewController.m
//  AFNetworkingDemo
//
//  Created by 冯洪建 on 15/12/17.
//  Copyright © 2015年 冯洪建. All rights reserved.
//

#import "ViewController.h"
#import "MCHttp.h"

#import "ADViewController.h"
#import "LxDBAnything.h"


#define kBaseUrl @"http://daxia.bjbwgh.com/app.php"
#define kImglist [NSString stringWithFormat:@"%@/User/imglist",kBaseUrl]

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self get];
    [self getCache];


}


/*!
 *  不带缓存的get请求
 */
- (void)get{
    
    
    [MCHttp getRequestURLStr:kImglist success:^(NSDictionary *requestDic, NSString *msg) {
    } failure:^(NSString *errorInfo) {
    }];
    
}
//  带缓存的get请求
- (void)getCache{
    [MCHttp getRequestCacheURLStr:kImglist success:^(NSDictionary *requestDic, NSString *msg) {
        LxDBAnyVar(requestDic);
    } failure:^(NSString *errorInfo) {
    }];
}







- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{


    ADViewController * adVc = [[ADViewController alloc]init];
    
    
    [self.navigationController pushViewController:adVc animated:YES];

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
