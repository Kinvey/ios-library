//
//  KCSKinveyTest.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-24.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "KinveyKit.h"
#import "TestUtils2.h"

@interface KCSKinveyTest : XCTestCase

@property (nonatomic, strong) KCSCollection* collection;
@property (nonatomic, strong) KCSCachedStore* store;

@end

@implementation KCSKinveyTest

- (void)setUp {
    [super setUp];
    
    [self setupKCS:YES];
    
    self.collection = [KCSCollection collectionFromString:@"user" ofClass:[KCSUser class]];
    self.store = [KCSCachedStore storeWithCollection:self.collection
                                             options:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadUser100Times
{
    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    __block KCSUser* user = nil;
    
    [KCSUser userWithUsername:[@"user" stringByAppendingFormat:@"%@", @(arc4random())]
                     password:@""
              fieldsAndValues:nil
          withCompletionBlock:^(KCSUser *_user, NSError *errorOrNil, KCSUserActionResult result)
     {
         user = _user;
         
         [expectationSave fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error)
    {
    }];
    
    XCTAssertNotNil(user);
    
    NSMutableArray *expectationsLoad = [NSMutableArray arrayWithCapacity:100];
    
    for (NSUInteger i = 0; i < 100; i++) {
        [expectationsLoad addObject:[self expectationWithDescription:[@"load_" stringByAppendingFormat:@"%@", @(i + 1)]]];
    }
    
    for (XCTestExpectation* expectationLoad in expectationsLoad) {
        [self.store loadObjectWithID:user.userId
                 withCompletionBlock:^(NSArray *users, NSError *errorOrNil)
         {
             XCTAssertNotNil(users);
             XCTAssertEqual(users.count, 1);
             
             [expectationLoad fulfill];
         }
                   withProgressBlock:nil];
    }
    
    [self waitForExpectationsWithTimeout:300
                                 handler:^(NSError *error)
    {
    }];
}

- (void)testPerformanceLoad {
    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    __block KCSUser* user = nil;
    
    [KCSUser userWithUsername:[@"user" stringByAppendingFormat:@"%@", @(arc4random())]
                     password:@""
              fieldsAndValues:nil
          withCompletionBlock:^(KCSUser *_user, NSError *errorOrNil, KCSUserActionResult result)
     {
         user = _user;
         
         [expectationSave fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:30
                                 handler:^(NSError *error)
     {
     }];
    
    XCTAssertNotNil(user);
    
    [self measureBlock:^{
        XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
        
        [self.store loadObjectWithID:user.userId
                 withCompletionBlock:^(NSArray *users, NSError *errorOrNil)
         {
             XCTAssertNotNil(users);
             XCTAssertEqual(users.count, 1);
             
             [expectationLoad fulfill];
         }
                   withProgressBlock:nil];
        
        [self waitForExpectationsWithTimeout:30
                                     handler:^(NSError *error)
        {
        }];
    }];
}

@end
