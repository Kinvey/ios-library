//
//  KNVMultiRequest.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KNVMultiRequest : NSObject <KNVRequest>

-(void)addRequest:(id<KNVRequest>)request;

@end
