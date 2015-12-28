//
//  TomatoHttpRequest.m
//  AFNetworkingDemo
//
//  Created by 冯洪建 on 15/12/17.
//  Copyright (c) 2015年 冯洪建. All rights reserved.
//

#import "MCHttp.h"
#import "AFNetworking.h"
#import "FMDB.h"
#import "LxDBAnything.h"

#ifdef DEBUG
#define MCLog(...) NSLog(__VA_ARGS__) //如果不需要打印数据，把这__  NSLog(__VA_ARGS__) ___注释了
#else
#define MCLog(...)
#endif
/*!
 *  缓存的策略：(如果 cacheTime == 0，将永久缓存数据) 也就是缓存的时间 以 秒 为单位计算
 *  分钟 ： 60
 *  小时 ： 60 * 60
 *  一天 ： 60 * 60 * 24
 *  星期 ： 60 * 60 * 24 * 7
 *  一月 ： 60 * 60 * 24 * 30
 *  一年 ： 60 * 60 * 24 * 365
 *  永远 ： 0
 */
static NSInteger const cacheTime = 0 ;
//  是否需要请求数据的时候显示进度/* 如果需要进度，那么你需要在方法中添加对应的  block  */
static BOOL kRequestProgress = NO;

// 缓存路径  缓存到Caches目录  统一做计算缓存大小，以及删除缓存操作
// NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
#define cachePath  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

// 请求方式
typedef NS_ENUM(NSInteger, RequestType) {
    RequestTypeGet,
    RequestTypePost,
    RequestTypeUpLoad
};

@implementation MCHttp
#pragma mark -- POST请求 不缓存数据
+ (void)postRequestURLStr:(NSString *)urlStr
                     withDic:(NSDictionary *)parameters
                     success:(SuccessBlock)success
                     failure:(ErrorBlock)failure{
    [[self alloc] requestWithUrl:urlStr parameters:parameters requsetType:RequestTypePost isCache:NO imageKey:nil withData:nil loadProgress:^(float progress)  {
        
    } success:^(NSDictionary *responseObject,NSString * msg) {
        success(responseObject,msg);
    } failure:^(NSString *errorInfo) {
        failure(errorInfo);
    }];
}
#pragma mark -- POST请求 缓存数据
+ (void)postRequestCacheURLStr:(NSString *)urlStr
                          withDic:(NSDictionary *)parameters
                          success:(SuccessBlock)success
                          failure:(ErrorBlock)failure{
    [[self alloc] requestWithUrl:urlStr parameters:nil requsetType:RequestTypePost isCache:YES imageKey:nil withData:nil  loadProgress:^(float progress)  {
        
    } success:^(NSDictionary *responseObject,NSString * msg) {
        success(responseObject,msg);
    } failure:^(NSString *errorInfo) {
        failure(errorInfo);
    }];
}
#pragma mark -- GET请求 不缓存数据
+ (void)getRequestURLStr:(NSString *)urlStr
                    success:(SuccessBlock)success
                    failure:(ErrorBlock)failure{
    [[self alloc] requestWithUrl:urlStr parameters:nil requsetType:RequestTypeGet isCache:NO imageKey:nil withData:nil loadProgress:^(float progress)  {
        
    } success:^(NSDictionary *responseObject,NSString * msg) {
        success(responseObject,msg);
    } failure:^(NSString *errorInfo) {
        failure(errorInfo);
    }];
}
#pragma mark -- GET请求 缓存数据
+ (void)getRequestCacheURLStr:(NSString *)urlStr
                         success:(SuccessBlock)success
                         failure:(ErrorBlock)failure{
    [[self alloc] requestWithUrl:urlStr parameters:nil requsetType:RequestTypeGet isCache:YES imageKey:nil withData:nil  loadProgress:^(float progress)  {
        
    } success:^(NSDictionary *responseObject,NSString * msg) {
        success(responseObject,msg);
    } failure:^(NSString *errorInfo) {
        failure(errorInfo);
    }];
}

#pragma mark -- 上传单个文件
+ (void)uploadDataWithURLStr:(NSString *)urlStr
                        withDic:(NSDictionary *)pasameters
                       imageKey:(NSString *)attach
                       withData:(NSData *)data
                 uploadProgress:(loadProgress)loadProgress
                        success:(SuccessBlock)success
                        failure:(ErrorBlock)failure{
    [[self alloc] requestWithUrl:urlStr parameters:pasameters requsetType:RequestTypeUpLoad isCache:NO imageKey:attach withData:data loadProgress:^(float progress) {
        loadProgress(progress);
    } success:^(NSDictionary *responseObject,NSString * msg) {
        success(responseObject,msg);
    } failure:^(NSString *errorInfo) {
        failure(errorInfo);
    }];
}
#pragma mark -- 网络请求统一处理
- (void)requestWithUrl:(NSString *)url
           parameters:(NSDictionary *)parameters
          requsetType:(RequestType)requestType
              isCache:(BOOL)isCache
              imageKey:(NSString *)attach
              withData:(NSData *)data
        loadProgress:(loadProgress)loadProgress
              success:(SuccessBlock)success
              failure:(ErrorBlock)failure{
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]; // ios9
    NSString * cacheUrl = [self urlDictToStringWithUrlStr:url WithDict:parameters];
    MCLog(@"\n\n-网址--\n\n       %@--->     %@\n\n-网址--\n\n",(requestType ==RequestTypeGet)?@"Get":@"POST",cacheUrl);
    NSData * cacheData;
    if (isCache) {
        cacheData = [self cachedDataWithUrl:cacheUrl];
        if(cacheData.length != 0){
            [self returnDataWithRequestData:cacheData Success:^(NSDictionary *requestDic, NSString *msg) {
                MCLog(@"缓存数据\n\n    %@   \n\n",requestDic);
                success(requestDic,msg);
            } failure:^(NSString *errorInfo) {
                failure(errorInfo);
            }];
        }
    }
    //请求前网络检查
    if(![self requestBeforeCheckNetWork]){
        failure(@"大哥，没有网络");MCLog(@"\n\n---%@----\n\n",@"没有网络呀");
        return;
    }
    AFHTTPRequestOperationManager *  manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",nil];
    [manager.requestSerializer setTimeoutInterval:10];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation * op;
    if (requestType == RequestTypeGet) {
       op = [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self dealwithResponseObject:responseObject cacheUrl:cacheUrl cacheData:cacheData isCache:isCache success:^(NSDictionary *responseObject,NSString * msg) {
                success(responseObject,msg);
            } failure:^(NSString *errorInfo) {
                failure(errorInfo);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            failure(@"程序媛MM正在努力抢救");
        }];
    }
    if (requestType == RequestTypePost) {
        
       op = [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self dealwithResponseObject:responseObject cacheUrl:cacheUrl cacheData:cacheData isCache:isCache success:^(NSDictionary *responseObject,NSString * msg) {
                success(responseObject,msg);
            } failure:^(NSString *errorInfo) {
                failure(errorInfo);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            failure(@"程序媛MM正在努力抢救");
        }];
    }
    if (requestType == RequestTypeUpLoad) {
        
        op =  [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            // 给上传的文件命名
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
            NSString * fileName =[NSString stringWithFormat:@"%@.png",@(timeInterval)];
            //添加要上传的文件，此处为图片   1.
//            NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"123.ipa" withExtension:nil];
//            [formData appendPartWithFileURL:fileURL name:fileName error:NULL];
            //添加图片，并对其进行压缩（0.0为最大压缩率，1.0为最小压缩率）  2.
            [formData appendPartWithFileData:data name:attach fileName:fileName mimeType:@"image/png"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [self dealwithResponseObject:responseObject cacheUrl:cacheUrl cacheData:cacheData isCache:NO success:^(NSDictionary *responseObject,NSString * msg) {
                success(responseObject,msg);
            } failure:^(NSString *errorInfo) {
                failure(errorInfo);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            failure(@"程序媛MM正在努力抢救");
            MCLog(@"上传文件发生错误\n\n    %@   \n\n", error);
        }];
    }
    if (requestType == RequestTypeUpLoad) {
        [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            MCLog(@"上传的进度参数...\n\n上传速度  %lu \n已上传    %lld \n文件大小  %lld\n\n", (unsigned long)bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
            float myProgress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
            loadProgress(myProgress);
        }];
    }else{
        if (kRequestProgress) {
            [op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                float myProgress = (float)totalBytesRead / (float)totalBytesExpectedToRead;
                loadProgress(myProgress);
                MCLog(@"下载的进度参数...\n\n上传速度  %lu \n已上传    %lld \n文件大小  %lld\n\n", (unsigned long)bytesRead, totalBytesRead, totalBytesExpectedToRead);
            }];
        }
    }
}

#pragma mark -- 统一处理请求到得数据
/*!
 *  @param responseObject 网络请求的数据
 *  @param cacheUrl       缓存的url标识
 *  @param cacheData      缓存的数据
 *  @param isCache        是否需要缓存
 */
- (void)dealwithResponseObject:(NSData *)responseData
                        cacheUrl:(NSString *)cacheUrl
                       cacheData:(NSData *)cacheData
                         isCache:(BOOL)isCache
                         success:(SuccessBlock)success
                         failure:(ErrorBlock)failure{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;// 关闭网络指示器
    });
    NSString * dataString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    dataString = [self deleteSpecialCodeWithStr:dataString];
    NSData *requstData=[dataString dataUsingEncoding:NSUTF8StringEncoding];
    if (isCache) {/**更新缓存数据*/
        [self saveData:requstData url:cacheUrl];
    }
    if (!isCache || ![cacheData isEqual:requstData]) {
        [self returnDataWithRequestData:requstData Success:^(NSDictionary *requestDic, NSString *msg) {
            MCLog(@"网络数据\n\n    %@   \n\n",requestDic);
            success(requestDic,msg);
        } failure:^(NSString *errorInfo) {
            failure(errorInfo);
        }];
    }
}
#pragma mark --根据返回的数据进行统一的格式处理  ----requestData 网络或者是缓存的数据----
- (void)returnDataWithRequestData:(NSData *)requestData Success:(SuccessBlock)success failure:(ErrorBlock)failure{
    id myResult = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableContainers error:nil];
    if ([myResult isKindOfClass:[NSDictionary  class]]) {
        NSDictionary *  requestDic = (NSDictionary *)myResult;
        NSString * succ = requestDic[@"result"];
        if ([succ isEqualToString:@"succ"]) {
            success(requestDic[@"info"],requestDic[@"msg"]);
        }else{
            failure(requestDic[@"msg"]);
        }
    }
}
#pragma mark -- 数据库实例
static FMDatabase *_db;
+ (void)initialize{
    NSString * bundleName =[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey];
    NSString *dbName=[NSString stringWithFormat:@"%@%@",bundleName,@".sqlite"];
    NSString *filename = [cachePath stringByAppendingPathComponent:dbName];
    _db = [FMDatabase databaseWithPath:filename];
    if ([_db open]) {
       BOOL res = [_db tableExists:@"MCData"];
        if (!res) {
            // 4.创表
            BOOL result = [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS MCData (id integer PRIMARY KEY AUTOINCREMENT, url text NOT NULL, data blob NOT NULL,savetime date);"];
            MCLog(@"\n\n---%@----\n\n",result?@"成功创表":@"创表失败");
        }
    }
    [_db close];
}
#pragma mark --通过请求参数去数据库中加载对应的数据
- (NSData *)cachedDataWithUrl:(NSString *)url{
    NSData * data = [[NSData alloc]init];
    [_db open];
    FMResultSet *resultSet = nil;
    resultSet = [_db executeQuery:@"SELECT * FROM MCData WHERE url = ?", url];
    // 遍历查询结果
    while (resultSet.next) {
     NSDate *  time = [resultSet dateForColumn:@"savetime"];
    NSTimeInterval timeInterval = -[time timeIntervalSinceNow];
        if(timeInterval > cacheTime &&  cacheTime!= 0){
            MCLog(@"\n\n     %@     \n\n",@"缓存的数据过期了");
        }else{
            data = [resultSet objectForColumnName:@"data"];
        }
    }
    [_db close];
    return data;
}
#pragma mark -- 缓存数据到数据库中
- (void)saveData:(NSData *)data url:(NSString *)url{
    [_db open];
    FMResultSet *rs = [_db executeQuery:@"select * from MCData where url = ?",url];
    if([rs next]){
        BOOL res  =[_db executeUpdate: @"update MCData set data =?,savetime =? where url = ?",data,[NSDate date],url];
        MCLog(@"\n\n%@     %@\n\n",url,res?@"数据更新成功":@"数据更新失败");
    }
    else{
        BOOL res =  [_db executeUpdate:@"INSERT INTO MCData (url,data,savetime) VALUES (?,?,?);",url, data,[NSDate date]];
        MCLog(@"\n\n%@     %@\n\n",url,res?@"数据插入成功":@"数据插入失败");
    }
    [_db close];
}

#pragma mark  请求前统一处理：如果是没有网络，则不论是GET请求还是POST请求，均无需继续处理
- (BOOL)requestBeforeCheckNetWork {
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    SCNetworkReachabilityRef defaultRouteReachability =
    SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags =
    SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        printf("Error. Count not recover network reachability flags\n");
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL isNetworkEnable  =(isReachable && !needsConnection) ? YES : NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible =isNetworkEnable;/*  网络指示器的状态： 有网络 ： 开  没有网络： 关  */
    });
    return isNetworkEnable;
}
#pragma mark ---   计算一共缓存的数据的大小
+ (NSString *)cacheSize{
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSArray *subpaths = [mgr subpathsAtPath:cachePath];
    long long ttotalSize = 0;
    for (NSString *subpath in subpaths) {
        NSString *fullpath = [cachePath stringByAppendingPathComponent:subpath];
        BOOL dir = NO;
        [mgr fileExistsAtPath:fullpath isDirectory:&dir];
        if (dir == NO) {// 文件
            ttotalSize += [[mgr attributesOfItemAtPath:fullpath error:nil][NSFileSize] longLongValue];
        }
    }//  M
    ttotalSize = ttotalSize/1024;
    return ttotalSize<1024?[NSString stringWithFormat:@"%lld KB",ttotalSize]:[NSString stringWithFormat:@"%.2lld MB",ttotalSize/1024];
}
/**
 *  获取文件大小
 */
+ (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}
#pragma mark ---   清空缓存的数据
+ (void)deleateCache{
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:cachePath error:nil];
}
#pragma mark -- 拼接 post 请求的网址
- (NSString *)urlDictToStringWithUrlStr:(NSString *)urlStr WithDict:(NSDictionary *)parameters{
    if (!parameters) {
        return urlStr;
    }
    NSMutableArray *parts = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id<NSObject> obj, BOOL *stop) {
        NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *encodedValue = [obj.description stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject: part];
    }];
    NSString *queryString = [parts componentsJoinedByString: @"&"];
    queryString =  queryString ? [NSString stringWithFormat:@"?%@", queryString] : @"";
    NSString * pathStr =[NSString stringWithFormat:@"%@?%@",urlStr,queryString];
    return pathStr;
}
#pragma mark -- 处理json格式的字符串中的换行符、回车符
- (NSString *)deleteSpecialCodeWithStr:(NSString *)str {
    NSString *string = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
    return string;
}
@end
