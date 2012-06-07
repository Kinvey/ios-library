//
//  TestUtils.h
//  KinveyKit
//
//  Created by Michael Katz on 6/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>
#import <KinveyKit/KinveyKit.h>

@interface SenTestCase (TestUtils)
@property (nonatomic) BOOL done;
- (void) poll;
- (KCSCompletionBlock) pollBlock;
@end

@interface TestUtils : NSObject

+ (BOOL) setUpKinveyUnittestBackend;
+ (NSURL*) randomFileUrl:(NSString*)extension;

@end
