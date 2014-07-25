//
//  PFBaseRequest.h
//  PFRequestKit
//
//  Created by PFei_He on 14-7-18.
//  Copyright (c) 2014年 PFei_He. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PFHTTPMethodDelete = 0,  // DELETE方法
    PFHTTPMethodGet,         // GET方法
    PFHTTPMethodHead,        // HEAD方法
    PFHTTPMethodPost,        // POST方法
    PFHTTPMethodPut,         // PUT方法
}PFHTTPMethod;

@interface PFBaseRequest : NSOperation <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

///请求
@property (nonatomic, strong)       NSMutableURLRequest     *request;
///url地址
@property (nonatomic, copy)         NSString                *baseURL;
///接口
@property (nonatomic, copy)         NSString                *urlPath;
///url
@property (nonatomic, strong)       NSURL                   *url;
///请求方法
@property (nonatomic, assign)       PFHTTPMethod             HTTPMethod;
///请求参数
@property (nonatomic, strong)       NSDictionary            *params;
///是否JSON数据
@property (nonatomic, assign)       BOOL                     isJSON;
///文件路径
@property (nonatomic, copy)         NSString                *savePath;
///超时时间
@property (nonatomic, assign)       NSTimeInterval           timeoutInterval;
///缓存协议
@property (nonatomic, assign)       NSURLRequestCachePolicy  cachePolicy;
///参数
@property (nonatomic, strong)       NSMutableData           *data;
///文件管理
@property (nonatomic, strong)       NSFileHandle            *fileHandle;
///错误
@property (nonatomic, strong)       NSError                 *error;

#pragma mark - PFRequest Methods

/**
 *  @brief DELETE方法
 *  @param params:      请求参数
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)deletePath:(NSString *)urlPath
                       params:(NSDictionary *)params
                   completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief GET方法
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)getPath:(NSString *)urlPath
                completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief GET方法
 *  @param params:      请求参数
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)getPath:(NSString *)urlPath
                    params:(NSDictionary *)params
                completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief GET方法
 *  @param params:      请求参数
 *  @param savePath:    文件路径
 *  @param progress:    进度条
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)getPath:(NSString *)urlPath
                    params:(NSDictionary *)params
                  savePath:(NSString *)savePath
                  progress:(void (^)(float progress))progress
                completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief HEAD方法
 *  @param params:      请求参数
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)headPath:(NSString *)urlPath
                     params:(NSDictionary *)params
                 completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief POST方法
 *  @param params:      请求参数
 *  @param isJSON:      请求参数是否JSON类型
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)postPath:(NSString *)urlPath
                     params:(NSDictionary *)params
                     isJSON:(BOOL)isJSON
                 completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief POST方法
 *  @param params:      请求参数
 *  @param isJSON:      请求参数是否JSON类型
 *  @param savePath:    文件路径
 *  @param progress:    进度条
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)postPath:(NSString *)urlPath
                     params:(NSDictionary *)params
                     isJSON:(BOOL)isJSON
                   savePath:(NSString *)savePath
                   progress:(void (^)(float progress))progress
                 completion:(void (^)(id result, NSError *error))completion;

/**
 *  @brief PUT方法
 *  @param params:      请求参数
 *  @param completion:  请求完成
 */
+ (PFBaseRequest *)putPath:(NSString *)urlPath
                    params:(NSDictionary *)params
                completion:(void (^)(id result, NSError *error))completion;

//#pragma mark - Response Management Methods
//
///**
// *  @brief 将请求结果转为NSData类型
// */
//- (NSData *)Data;
//
///**
// *  @brief 将请求结果转为JSON类型
// */
//- (id)JSON;

@end

#pragma mark - PFRequestSingleton

@interface PFRequestSingleton : NSObject

///url地址
@property (nonatomic, copy)     NSString        *baseURL;
///超时时间
@property (nonatomic, assign)   NSTimeInterval   timeoutInterval;

+ (instancetype)sharedInstance;

@end
