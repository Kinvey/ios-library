//
//  KCSPendingOperation.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KCSPendingOperation

-(NSURLRequest*)buildRequest;

@end
