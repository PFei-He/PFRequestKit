//
//  PFBaseRequest.m
//  PFRequestKit
//
//  Created by PFei_He on 14-7-18.
//  Copyright (c) 2014年 PFei_He. All rights reserved.
//

#import "PFBaseRequest.h"

#define kPFRequestTimeoutInterval 8

@interface NSString (PFBaseRequest)

- (NSString *)encodedParamsString;

@end

@implementation NSString (PFBaseRequest)

- (NSString*)encodedParamsString
{
    NSString *result = (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, NULL, CFSTR(":/=,!$&'()*+;[]@#?"), kCFStringEncodingUTF8);
	return result;
}

@end

@interface NSData (PFBaseRequest)

- (NSString *)base64;

@end

@implementation NSData (PFBaseRequest)

//设置编码
static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSString *)base64
{
    if ([self length] == 0) return @"";

    char *characters = malloc((([self length] + 2) / 3) * 4);

	if (characters == NULL) return nil;

	NSUInteger length = 0;
	NSUInteger i = 0;

	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length]) buffer[bufferLength++] = ((char *)[self bytes])[i++];

		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];

		if (bufferLength > 1) characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';

		if (bufferLength > 2) characters[length++] = encodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';
	}

	return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] ;
}

@end

#pragma mark -
#pragma mark - PFBaseRequest

typedef enum {
    PFRequestStateIsReady = 0,  //请求已就绪
    PFRequestStateIsExecuting,  //请求正在执行
    PFRequestStateIsFinished    //请求已完成
}PFRequestState;

typedef void(^completion)(id result, NSError *error);

@interface PFBaseRequest ()
{
    NSHTTPURLResponse   *urlResponse;

    NSString            *userAgent;

    id                   resultObject;

    dispatch_queue_t     dispatchQueue;
    dispatch_group_t     dispatchGroup;
}

///状态
@property (nonatomic, readwrite)    PFRequestState           state;
///计时器
@property (nonatomic, strong)       NSTimer                 *timer;
///连接
@property (nonatomic, strong)       NSURLConnection         *connection;
///响应
@property (nonatomic, strong)       NSURLResponse           *response;
///请求完成代码块
@property (nonatomic, copy)         completion               completion;
///进度条
@property (nonatomic, copy)         void(^progress)(float progress);
///响应内容类型
@property (nonatomic, strong)       NSSet                   *contentType;
///接收数据总长度
@property (nonatomic, readwrite)    float                    expectedContentLength;
///已接收数据长度
@property (nonatomic, readwrite)    float                    receivedContentLength;

@end

@implementation PFBaseRequest

@synthesize request                     = _request;
@synthesize baseURL                     = _baseURL;
@synthesize urlPath                     = _urlPath;
@synthesize url                         = _url;
@synthesize HTTPMethod                  = _HTTPMethod;
@synthesize params                      = _params;
@synthesize savePath                    = _savePath;
@synthesize timeoutInterval             = _timeoutInterval;
@synthesize data                        = _data;
@synthesize cachePolicy                 = _cachePolicy;
@synthesize fileHandle                  = _fileHandle;
@synthesize error                       = _error;

@synthesize state                       = _state;
@synthesize connection                  = _connection;
@synthesize response                    = _response;
@synthesize completion                  = _completion;
@synthesize progress                    = _progress;
@synthesize contentType                 = _contentType;
@synthesize expectedContentLength       = _expectedContentLength;
@synthesize receivedContentLength       = _receivedContentLength;

#pragma mark - PFBaseRequest Methods

//delete
+ (PFBaseRequest *)deletePath:(NSString *)urlPath
                       params:(NSDictionary *)params
                   completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodDelete
                                                    params:params
                                                    isJSON:NO
                                                  savePath:nil
                                                  progress:nil
                                                completion:completion];
    [request start];
    return request;
}

//get
+ (PFBaseRequest *)getPath:(NSString *)urlPath
                completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodGet
                                                    params:nil
                                                    isJSON:NO
                                                  savePath:nil
                                                  progress:nil
                                                completion:completion];
    [request start];
    return request;
}

//get
+ (PFBaseRequest *)getPath:(NSString *)urlPath
                    params:(NSDictionary *)params
                completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodGet
                                                    params:params
                                                    isJSON:NO
                                                  savePath:nil
                                                  progress:nil
                                                completion:completion];
    [request start];
    return request;
}

//get
+ (PFBaseRequest *)getPath:(NSString *)urlPath
                    params:(NSDictionary *)params
                  savePath:(NSString *)savePath
                  progress:(void (^)(float progress))progress
                completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodGet
                                                    params:params
                                                    isJSON:NO
                                                  savePath:savePath
                                                  progress:progress
                                                completion:completion];
    [request start];
    return request;
}

//head
+ (PFBaseRequest *)headPath:(NSString *)urlPath
                     params:(NSDictionary *)params
                 completion:(void (^)(id result, NSError *error))completion;
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodHead
                                                    params:params
                                                    isJSON:NO
                                                  savePath:nil
                                                  progress:nil
                                                completion:completion];
    [request start];
    return request;
}

//post
+ (PFBaseRequest *)postPath:(NSString *)urlPath
                     params:(NSDictionary *)params
                     isJSON:(BOOL)isJSON
                 completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodPost
                                                    params:params
                                                    isJSON:isJSON
                                                  savePath:nil
                                                  progress:nil
                                                completion:completion];
    [request start];
    return request;
}

//post
+ (PFBaseRequest *)postPath:(NSString *)urlPath
                     params:(NSDictionary *)params
                     isJSON:(BOOL)isJSON
                   savePath:(NSString *)savePath
                   progress:(void (^)(float progress))progress
                 completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodPost
                                                    params:params
                                                    isJSON:isJSON
                                                  savePath:savePath
                                                  progress:progress
                                                completion:completion];
    [request start];
    return request;
}

//put
+ (PFBaseRequest *)putPath:(NSString *)urlPath
                    params:(NSDictionary *)params
                completion:(void (^)(id result, NSError *error))completion
{
    PFBaseRequest *request = [[self alloc] initWithURLPath:urlPath
                                                HTTPMethod:PFHTTPMethodPut
                                                    params:params
                                                    isJSON:NO
                                                  savePath:nil
                                                  progress:nil
                                                completion:completion];
    [request start];
    return request;
}

#pragma mark - initialization

//初始化请求
- (PFBaseRequest *)initWithURLPath:(NSString *)urlPath
                        HTTPMethod:(PFHTTPMethod)HTTPMethod
                            params:(NSDictionary *)params
                            isJSON:(BOOL)isJSON
                          savePath:(NSString *)savePath
                          progress:(void (^)(float))progress
                        completion:(void (^)(id result, NSError *error))completion
{
    self = [super init];

    //参数
    self.params     = params;

    //参数是否JSON类型
    self.isJSON     = isJSON;

    //缓存路径
    self.savePath   = savePath;

    //进度条
    self.progress   = progress;

    //请求操作响应代码块
    self.completion = completion;

    //创建线程
    dispatchQueue   = dispatch_queue_create("com.PF-Lib.PFRequestKit", DISPATCH_QUEUE_SERIAL);

    //创建组线程
    dispatchGroup   = dispatch_group_create();

    //URL
    if (!urlPath) urlPath = @"";
    self.urlPath = urlPath;
    self.url = nil;

    //创建请求
    self.request = [[NSMutableURLRequest alloc] initWithURL:self.url];

    //超时
    if (!self.timeoutInterval && ![PFRequestSingleton sharedInstance].timeoutInterval) self.timeoutInterval = kPFRequestTimeoutInterval;
    [self.request setTimeoutInterval:self.timeoutInterval];

    //HTTP管线化
    self.request.HTTPShouldUsePipelining = (HTTPMethod == PFHTTPMethodGet || HTTPMethod == PFHTTPMethodHead);

    //请求方法
    self.HTTPMethod = HTTPMethod;

    //更改请求状态为就绪
    self.state = PFRequestStateIsReady;

    return self;
}

//设置URL
- (void)setUrl:(NSURL *)url
{

    self.baseURL = [PFRequestSingleton sharedInstance].baseURL;
    NSURL *baseURL = [NSURL URLWithString:self.baseURL];

    //在URL后添加 / 符号
    if (baseURL.path.length > 0 && ![baseURL.absoluteString hasSuffix:@"/"]) baseURL = [baseURL URLByAppendingPathComponent:@""];

    //拼接URL
    url = [NSURL URLWithString:self.urlPath relativeToURL:baseURL];
    _url = url;
}

//设置请求方法
- (void)setHTTPMethod:(PFHTTPMethod)HTTPMethod
{
    //判断请求方法是否为空
    NSParameterAssert(HTTPMethod);
    if (HTTPMethod == PFHTTPMethodDelete) [self.request setHTTPMethod:@"DELETE"];
    else if (HTTPMethod == PFHTTPMethodGet) [self.request setHTTPMethod:@"GET"];
    else if (HTTPMethod == PFHTTPMethodHead) [self.request setHTTPMethod:@"HEAD"];
    else if (HTTPMethod == PFHTTPMethodPost) [self.request setHTTPMethod:@"POST"];
    else [self.request setHTTPMethod:@"PUT"];

    _HTTPMethod = HTTPMethod;
}

//设置参数
- (void)addParams:(NSDictionary *)params
{
    if (self.params == nil) return;

    //判断参数是否为空
    NSParameterAssert(params);
    //获取参数数量
    NSUInteger paramsCount = [[params allKeys] count];

    //NSString参数
    NSMutableArray *stringParams = [NSMutableArray arrayWithCapacity:paramsCount];
    //NSData参数
    NSMutableArray *dataParams = [NSMutableArray arrayWithCapacity:paramsCount];

    //获取请求方法
    NSString *HTTPMethod = self.request.HTTPMethod;

    //遍历参数的keys和objects
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
     {

         if ([obj isKindOfClass:[NSString class]]) {//参数为NSString
             //格式化参数
             NSString *paramsString = [obj encodedParamsString];
             //拼接参数
             [stringParams addObject:[NSString stringWithFormat:@"%@=%@", key, paramsString]];
         }
         else if ([obj isKindOfClass:[NSNumber class]]) {//参数为NSNumber
             [stringParams addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
         }
         else if ([obj isKindOfClass:[NSData class]]) {//参数为NSData
             if (![HTTPMethod isEqualToString:@"POST"] || ![HTTPMethod isEqualToString:@"PUT"]) {
                 NSLog(@"请求不能添加NSData类型参数");
                 return;
             }

             //设置请求参数的分界线
             NSString *boundary = @"PFRequestBoundaryString";

             //设置请求内容类型
             NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
             [self.request addValue:contentType forHTTPHeaderField:@"Content-Type"];

             //设置请求数据
             NSMutableData *data = [NSMutableData data];
             [data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
             [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"userfile\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
             [data appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
             [data appendData:[NSData dataWithData:obj]];
             [data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
         }
     }];

    if ([HTTPMethod isEqualToString:@"GET"] || [HTTPMethod isEqualToString:@"HEAD"])
    {
        //格式化URL
        NSString *finalURLString = self.request.URL.absoluteString;

        //拼接URL的请求参数
        finalURLString = [finalURLString stringByAppendingFormat:@"?%@", [stringParams componentsJoinedByString:@"&"]];

        //获取请求的URL
        [self.request setURL:[NSURL URLWithString:finalURLString]];
    }
    else if (self.isJSON)
    {
        //添加JSON到请求参数
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (error) self.error = error;
        if (data && self.error)
            [NSException raise:NSInvalidArgumentException format:@"JSON格式错误"];
        [self.request setHTTPBody:data];
    }
    else
    {
        //添加NSData到请求参数
        NSString *arrangeString = [stringParams componentsJoinedByString:@"&"];
        const char *stringData = [arrangeString UTF8String];
        NSMutableData *postData = [NSMutableData dataWithBytes:stringData length:strlen(stringData)];

        for (NSData *data in dataParams)
            [postData appendData:data];

        [self.request setHTTPBody:postData];
    }
}

//自定义属性state的get方法
- (PFRequestState)state
{
    @synchronized(self) {
        return _state;
    }
}

//自定义属性state的set方法
- (void)setState:(PFRequestState)state
{
    @synchronized(self) {
        //监听请求的状态
        [self willChangeValueForKey:@"state"];
        _state = state;
        [self didChangeValueForKey:@"state"];
    }
}

//设置计时器
- (void)setTimer:(NSTimer *)timer
{
    if (_timer) [_timer invalidate], _timer = nil;
    if (timer) _timer = timer;
}

//设置请求操作响应代码块
- (void)completionWithResponse:(id)result error:(NSError *)error
{
    self.timer = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        //回调请求结果
        if (self.completion && !self.isCancelled) {
            if ([self.request.HTTPMethod isEqualToString:@"HEAD"]) self.completion(self.response, error);
            else self.completion(result, error);
        }
        if (error) self.error = error;
        [self finish];
    });

    self.connection = nil;
}

//请求完成
- (void)finish
{
    //取消请求并致空
    [self.connection cancel], self.connection = nil;

    //监听请求状态并更改请求状态为完成
    [self willChangeValueForKey:@"isExecuting"], [self willChangeValueForKey:@"isFinished"];
    self.state = PFRequestStateIsFinished;
    [self didChangeValueForKey:@"isExecuting"], [self didChangeValueForKey:@"isFinished"];

}

#pragma mark - Response Management Methods

//设置响应内容类型
- (void)setContentType:(NSSet *)contentType
{
    contentType = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
}

//将请求结果转为NSData类型
- (NSData *)Data
{
    if ([self isFinished])
        return self.data;
    else
        return nil;
}

//将请求结果转为JSON类型
- (id)JSON
{
    if ([self Data] == nil) return nil;

    dispatch_group_notify(dispatchGroup, dispatchQueue, ^{
        NSError *error = nil;
        if (self.data && self.data.length > 0)
        {
            resultObject = [NSData dataWithData:self.data];
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:resultObject options:0 error:&error];

            if (jsonObject)
                resultObject = jsonObject;
        }
        if (error) self.error = error;
        [self completionWithResponse:resultObject error:self.error];
    });

    if (self.error) NSLog(@"解析JSON数据错误：\n%@", self.error);
    return resultObject;
}

#pragma mark - NSOperation Methods

//请求开始
- (void)start
{
    if ([self isCancelled])
    {
        NSDictionary *userInfo = nil;
        if ([self.request URL]) userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
        if (error) self.error = error;
        NSLog(@"请求已被取消：%@", self.error);

        [self finish];
        return;
    }

    //使用主线程加载请求
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }

    //添加参数
    if (self.params) [self addParams:self.params];

    //设置请求头
    if (userAgent) [self.request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    if (self.isJSON) [self.request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    //监听请求状态并更改请求状态为执行中
    [self willChangeValueForKey:@"isExecuting"];
    self.state = PFRequestStateIsExecuting;
    [self didChangeValueForKey:@"isExecuting"];

    //设置文件路径
    if (self.savePath)
    {
        [[NSFileManager defaultManager] createFileAtPath:self.savePath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.savePath];
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        self.data = [[NSMutableData alloc] init];
    }

    //请求策略
    [self.request setCachePolicy:self.cachePolicy];

    //请求连接
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];

    //请求开始
    [self.connection start];
}

//请求取消
- (void)cancel
{
    if ([self isFinished]) return;

    [super cancel];
    [self completionWithResponse:nil error:nil];
}

//请求是否并发
- (BOOL)isConcurrent
{
    return YES;
}

//请求是否在执行
- (BOOL)isExecuting
{
    return self.state = PFRequestStateIsExecuting;
}

//请求是否完成
- (BOOL)isFinished
{
    return self.state = PFRequestStateIsFinished;
}

//请求是否就绪
- (BOOL)isReady
{
    return self.state = PFRequestStateIsReady;
}

#pragma mark - NSURLConnectionDataDelegate Methods

//服务器响应
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.expectedContentLength = response.expectedContentLength;
    self.receivedContentLength = 0;
    self.response = (NSHTTPURLResponse *)response;
}

//服务器传输数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    dispatch_group_async(dispatchGroup, dispatchQueue, ^{
        if (self.savePath)
        {
            @try {[self.fileHandle writeData:data];}
            @catch (NSException *exception) {
                [self.connection cancel];
                NSError *error = [NSError errorWithDomain:@"文件写入错误：\n" code:0 userInfo:exception.userInfo];
                if (error) self.error = error;
                [self completionWithResponse:nil error:self.error];
            }
        } else {
            //接收数据
            [self.data appendData:data];
        }
    });

    //下载进度
    if (self.progress)
    {
        if (self.expectedContentLength != -1) {
            self.receivedContentLength += data.length;
            self.progress(self.receivedContentLength / self.expectedContentLength);
        } else {
            self.progress(-1);
        }
    }
}

//数据传输完成
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //若请求取消则跳出
    if ([self isCancelled]) return;

    //更改请求状态为完成
    self.state = PFRequestStateIsFinished;

    [self JSON];
}

#pragma mark - NSURLConnectionDelegate Methods

//请求失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (error) self.error = error;
    [self completionWithResponse:nil error:self.error];
}

@end

#pragma mark -
#pragma mark - PFRequestSingleton

@implementation PFRequestSingleton

@synthesize baseURL         = _baseURL;
@synthesize timeoutInterval = _timeoutInterval;

//单例
+ (instancetype)sharedInstance
{
    static PFRequestSingleton *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
