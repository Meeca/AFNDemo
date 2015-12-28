//
//  TomatoHttpRequest.h
//  AFNetworkingDemo
//
//  Created by 冯洪建 on 15/12/17.
//  Copyright (c) 2015年 冯洪建. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SuccessBlock)(NSDictionary * requestDic,NSString * msg);
typedef void(^ErrorBlock)(NSString *errorInfo);
typedef void(^loadProgress)(float progress);

@interface MCHttp : NSObject

/*!
 *  POST请求 不缓存数据
 *
 *  @param urlStr     url
 *  @param parameters post参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
+ (void)postRequestURLStr:(NSString *)urlStr
                         withDic:(NSDictionary *)parameters
                         success:(SuccessBlock)success
                         failure:(ErrorBlock)failure;

/*!
 *  POST请求 缓存数据
 *
 *  @param urlStr     url
 *  @param parameters post参数
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
+ (void)postRequestCacheURLStr:(NSString *)urlStr
                              withDic:(NSDictionary *)parameters
                              success:(SuccessBlock)success
                              failure:(ErrorBlock)failure;

/*!
 *  GET请求 不缓存数据
 *
 *  @param urlStr     url
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
+ (void)getRequestURLStr:(NSString *)urlStr
                        success:(SuccessBlock)success
                        failure:(ErrorBlock)failure;

/*!
 *  GET请求 缓存数据
 *
 *  @param urlStr     url
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
+ (void)getRequestCacheURLStr:(NSString *)urlStr
                             success:(SuccessBlock)success
                             failure:(ErrorBlock)failure;

#pragma mark --  上传单个文件
/*!
 *  上传单个文件
 *
 *  @param urlStr     服务器地址
 *  @param pasameters 参数
 *  @param attach     上传文件的 key
 *  @param data       上传的文件
 *  @param uploadProgress 上传进度
 *  @param success    成功的回调
 *  @param failure    失败的回调
 */
+ (void)uploadDataWithURLStr:(NSString *)urlStr
                        withDic:(NSDictionary *)pasameters
                       imageKey:(NSString *)attach
                       withData:(NSData *)data
                 uploadProgress:(loadProgress)loadProgress
                        success:(SuccessBlock)success
                        failure:(ErrorBlock)failure;


#pragma mark ---
#pragma mark ---   计算一共缓存的数据的大小
+ (NSString *)cacheSize;

#pragma mark ---
#pragma mark ---   清空缓存的数据
+ (void)deleateCache;

/**
 *  获取文件大小
 *
 *  @param path 本地路径
 *
 *  @return 文件大小
 */
+ (unsigned long long)fileSizeForPath:(NSString *)path;



@end
