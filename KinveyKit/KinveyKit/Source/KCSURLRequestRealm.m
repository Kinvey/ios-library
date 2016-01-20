//
//  KCSURLRequestRealm.m
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KCSURLRequestRealm.h"
#import "KinveyPersistable.h"

#define kHeaderRequestId @"X-Kinvey-Request-Id"

@implementation KCSURLRequestRealm

-(instancetype)initWithURLRequest:(NSURLRequest *)urlRequest
                   collectionName:(NSString*)collectionName
                         objectId:(NSString*)objectId
{
    self = [super init];
    if (self) {
        self.date = [NSDate date];
        
        NSString* requestId = urlRequest.allHTTPHeaderFields[kHeaderRequestId];
        self.requestId = requestId ? requestId : [[NSUUID UUID] UUIDString];
        
        self.collectionName = collectionName;
        self.objectId = objectId;
        
        self.method = urlRequest.HTTPMethod;
        self.url = urlRequest.URL.absoluteString;
        if (urlRequest.allHTTPHeaderFields) {
            self.headers = [NSJSONSerialization dataWithJSONObject:urlRequest.allHTTPHeaderFields
                                                           options:0
                                                             error:nil];
        }
        if (urlRequest.HTTPBody) {
            self.body = urlRequest.HTTPBody;
        } else if (urlRequest.HTTPBodyStream) {
            NSUInteger total = 0, read = 0, maxLength = 4096;
            uint8_t buffer[maxLength];
            NSMutableData* data = [NSMutableData dataWithCapacity:maxLength];
            NSInputStream* is = urlRequest.HTTPBodyStream;
            [is open];
            while (is.hasBytesAvailable) {
                read = [is read:buffer maxLength:maxLength];
                [data appendBytes:buffer length:read];
                total += read;
            }
            [is close];
            self.body = data;
        }
    }
    return self;
}

+(NSString *)primaryKey
{
    return @"requestId";
}

+(NSArray<NSString *> *)requiredProperties
{
    return @[@"requestId", @"date", @"collectionName", @"method", @"url", @"headers"];
}

-(NSDictionary<NSString *,id> *)toJson
{
    return @{@"requestId" : self.requestId,
             @"date" : self.date ? self.date : [NSNull null],
             @"collectionName" : self.collectionName,
             @"objectId" : self.objectId ? self.objectId : [NSNull null],
             @"method" : self.method,
             @"url" : self.url,
             @"headers" : self.headers,
             @"body" : self.body};
}

+(NSDictionary<NSString *, NSString *> *)kinveyPropertyMapping
{
    return @{@"requestId" : KCSEntityKeyId,
             @"date" : @"date",
             @"collectionName" : @"collectionName",
             @"objectId" : @"objectId",
             @"method" : @"method",
             @"url" : @"url",
             @"headers" : @"headers",
             @"body" : @"body"};
}

-(NSURLRequest *)buildRequest
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    request.HTTPMethod = self.method;
    request.allHTTPHeaderFields = [NSJSONSerialization JSONObjectWithData:self.headers
                                                                  options:0
                                                                    error:nil];
    if (self.body) {
        request.HTTPBody = self.body;
    }
    return request;
}

@end
