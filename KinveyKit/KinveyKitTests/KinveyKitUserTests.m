//
//  KinveyKitUserTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2014 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KinveyKitUserTests.h"
#import "KinveyUser.h"
#import "KCSClient.h"
#import "KinveyHTTPStatusCodes.h"
#import "KCS_SBJson.h"
#import "KinveyPing.h"
#import "KCSLogManager.h"
#import "KCSAuthCredential.h"
#import "KinveyCollection.h"
#import "NSString+KinveyAdditions.h"
#import "KCSObjectMapper.h"
#import "KCSDataModel.h"

#import "KCSHiddenMethods.h"

#import "TestUtils.h"
#import "KCSKeychain.h"

typedef BOOL(^KCSUserSuccessAction)(KCSUser *, KCSUserActionResult);
typedef BOOL(^KCSUserFailureAction)(KCSUser *, NSError *);
typedef BOOL(^KCSEntitySuccessAction)(id, NSObject *);
typedef BOOL(^KCSEntityFailureAction)(id, NSError *);


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@interface KinveyKitUserTests () <KCSUserActionDelegate>
#pragma clang diagnostic pop

@property (nonatomic) BOOL testPassed;
@property (nonatomic, copy) KCSUserSuccessAction onSuccess;
@property (nonatomic, copy) KCSUserFailureAction onFailure;
@property (nonatomic, copy) KCSEntitySuccessAction onEntitySuccess;
@property (nonatomic, copy) KCSEntityFailureAction onEntityFailure;
@property (nonatomic, retain) KCS_SBJsonParser *parser;
@property (nonatomic, retain) KCS_SBJsonWriter *writer;

@end


@implementation KinveyKitUserTests

- (void)setUp
{
    _testPassed = NO;
    _onSuccess = [^(KCSUser *u, KCSUserActionResult result){ return NO; } copy];
    _onFailure = [^(KCSUser *u, NSError *error){ return NO; } copy];
    _onEntitySuccess = [^(id u, NSObject *obj){ return NO; } copy];
    _onEntityFailure = [^(id u, NSError *error){ return NO; } copy];
    [TestUtils justInitServer];

    _parser = [[KCS_SBJsonParser alloc] init];
    _writer = [[KCS_SBJsonWriter alloc] init];
}

- (void)tearDown
{
    [[KCSUser activeUser] logout];
}

- (KCSUser*) currentOrAutogen
{
    if ([KCSUser activeUser] == nil) {
        self.done = NO;
        [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
            STAssertNoError;
            KTAssertEqualsInt(result, KCSUserNoInformation, @"should no longer provide this info");
            self.done = YES;
        }];
        [self poll];
    }
    KCSUser* user = [KCSUser activeUser];
    XCTAssertNotNil(user, @"should have active user");
    return user;
}

// These tests are ordered and must be run first, hence the AAAXX

- (void) testLoadUserObjectFromCache
{
    KCSUser* activeUser = [KCSUser activeUser];
    XCTAssertNil(activeUser, @"start from a known state");
    
    NSString* _id = [NSString UUID];
    NSString* username = [NSString UUID];
    KCSUser* newUser = [[KCSUser alloc] init];
    newUser.userId = _id;
    newUser.username = username;
    [[KCSAppdataStore caches] cacheActiveUser:(id)newUser];
    
    activeUser = [KCSUser activeUser];
    XCTAssertEqualObjects(activeUser.userId, _id, @"should restore id");
    XCTAssertEqualObjects(activeUser.username, username, @"should restore username");
}

- (void) testLoadAuthFromKeychain
{
    KCSUser* activeUser = [KCSUser activeUser];
    XCTAssertNil(activeUser, @"start from a known state");
    
    NSString* _id = [NSString UUID];
    NSString* username = [NSString UUID];
    KCSUser* newUser = [[KCSUser alloc] init];
    newUser.userId = _id;
    newUser.username = username;

    NSString* token = [NSString UUID];
    [KCSKeychain2 setKinveyToken:token user:newUser.userId];
    
    NSString* auth = [(id<KCSCredentials>)newUser authString];
    XCTAssertNotNil(auth, @"should be not nil");
    
}

- (void)testLogoutLogsOutCurrentUser
{
    KCSUser *cUser = [self currentOrAutogen];
    XCTAssertNotNil(cUser, @"need an active user for this test to work");
    [cUser logout];
    XCTAssertNil(cUser.username, @"uname should start nil");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil([cUser password], @"pw should start nil");
#pragma clang diagnostic pop
}

- (void)testRequestDoesNotCreateImplictUser
{
    [[KCSUser activeUser] logout];
    
    KCSUser *cUser = [KCSUser activeUser];
    XCTAssertNil(cUser.username, @"uname should start nil");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(cUser.password, @"pw should start nil");
#pragma clang diagnostic pop
    
    self.done = NO;
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:@"foo" ofClass:[NSDictionary class]] options:nil];
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(objectsOrNil, @"no objects");
        XCTAssertNotNil(errorOrNil, @"should get an error");
        KTAssertEqualsInt(errorOrNil.code, 401, @"should be a no creds");
        XCTAssertNil([KCSUser activeUser], @"should still have no user");
        
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void)testCanLogoutUser
{
    KCSUser* s = [self currentOrAutogen];
    XCTAssertNotNil(s, @"Should have a user");
    [[KCSUser activeUser] logout];

    // Check to make sure user is nil
    XCTAssertNil([KCSUser activeUser], @"cuser should be nilled");
    XCTAssertFalse([KCSUser hasSavedCredentials], @"Should have no creds");
}

- (void)testAnonymousUser
{
    [[KCSUser activeUser] logout];
    
    XCTAssertNil([KCSUser activeUser], @"should have no user");
    
    __block NSString* uname = nil;
    self.done = NO;
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        XCTAssertNotNil(user, @"should have a user");
        XCTAssertEqualObjects(user, [KCSUser activeUser], @"user should be set");
        uname = user.username;
        self.done = YES;
    }];
    [self poll];
    XCTAssertNotNil([KCSUser activeUser], @"should have an active User");
    
    
    self.done = NO;
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:@"foo" ofClass:[NSDictionary class]] options:nil];
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(0);
        
        XCTAssertEqualObjects([KCSUser activeUser].username, uname, @"should still be the same anon user");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void)testCanAddArbitraryDataToUser
{
    [[KCSUser activeUser] logout];
    
    // Make sure we have a user
    if ([KCSUser activeUser] == nil){
        KCSUser* user = [[KCSUser alloc] init];
        user.userId = [NSString UUID];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        [KCSClient sharedClient].currentUser = user;
#pragma clang diagnostic pop
        [KCSUser activeUser];
    }
    
    KCSUser *currentUser = [KCSUser activeUser];
    XCTAssertNotNil(currentUser, @"should have a user");
    
    [currentUser setValue:@32 forAttribute:@"age"];
    [currentUser setValue:@"Brooklyn, NY" forAttribute:@"birthplace"];
    [currentUser setValue:@YES forAttribute:@"isAlive"];
    
    XCTAssertEqual((int)[[currentUser getValueForAttribute:@"age"] intValue], (int)32, @"age should match");
    XCTAssertTrue([[currentUser getValueForAttribute:@"isAlive"] boolValue], @"isAlive should match");
    XCTAssertEqualObjects([currentUser getValueForAttribute:@"birthplace"], @"Brooklyn, NY", @"birthplace should match");
}

- (void) testComplexAttribute
{
    NSArray* loc = @[@100,@10];
    CLLocation* location = [CLLocation locationFromKinveyValue:loc];
    KCSUser* user = [[KCSUser alloc] init];
    [user setValue:location forAttribute:@"location"];
    
    NSError* errorOrNil = nil;
    KCSSerializedObject* obj = [KCSObjectMapper makeResourceEntityDictionaryFromObject:user forCollection:@"user" error:&errorOrNil];
    STAssertNoError;

    NSDictionary* serialized = obj.dataToSerialize;
    NSArray* objLoc = serialized[@"location"];
    XCTAssertEqualObjects(loc, objLoc, @"Should get location back properly");
                            
}

- (void) testAutogenUser
{
    [[KCSUser activeUser] logout];
    XCTAssertNil([KCSUser activeUser], @"start with no user");
    
    KCSUser* u = [self currentOrAutogen];
    XCTAssertNotNil(u, @"should be active user");
    XCTAssertNotNil(u.userId, @"should be active user");
    XCTAssertNotNil(u.username, @"should be active user");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(u.password, @"should be active user");
    XCTAssertNil(u.sessionAuth, @"should be active user");
#pragma clang diagnostic pop
}

- (void) setupUserCache
{
    KCSUser* user = [[KCSUser alloc] init];
    user.userId = [NSString UUID];
    user.username = [NSString UUID];
    [[KCSAppdataStore caches] cacheActiveUser:(id)user];
    [KCSKeychain2 setKinveyToken:[NSString UUID] user:user.userId];
}

- (void) testInitActive
{
    [[KCSUser activeUser] logout];
    [KCSUser clearSavedCredentials];
    
    KCSUser* user = [KCSUser initAndActivateWithSavedCredentials];
    XCTAssertNil(user, @"should have a nil user");
    [self setupUserCache];
    
    user = [KCSUser initAndActivateWithSavedCredentials];
    XCTAssertNotNil(user, @"Should be set by keychain");
    XCTAssertNotNil(user.username, @"Should be set by keychain");
}

- (void) testNeedUsernameAndPassword
{
    XCTAssertThrowsSpecificNamed([KCSUser userWithUsername:nil password:@"foo" fieldsAndValues:nil withCompletionBlock:nil], NSException, NSInvalidArgumentException, @"need invalid arg");
    XCTAssertThrowsSpecificNamed([KCSUser userWithUsername:@"foo" password:nil fieldsAndValues:nil withCompletionBlock:nil], NSException, NSInvalidArgumentException, @"need invalid arg");
}


- (void)testCanTreatUsersAsCollection
{
    [[KCSUser activeUser] logout];
    
    // Make sure we have a user
    if ([KCSUser activeUser] == nil){
        [self setupUserCache];
        [KCSUser activeUser];
    }
    XCTAssertTrue([[KCSCollection userCollection] isKindOfClass:[KCSCollection class]], @"user collection should be a collection");
}

- (void)user:(KCSUser *)user actionDidCompleteWithResult:(KCSUserActionResult)result
{
    self.done = YES;
    self.testPassed = self.onSuccess(user, result);
}

- (void)user:(KCSUser *)user actionDidFailWithError:(NSError *)error
{
    self.done = YES;
    self.testPassed = self.onFailure(user, error);
}

- (void)entity:(id<KCSPersistable>)entity fetchDidCompleteWithResult:(NSObject *)result
{
    self.done = YES;
    self.testPassed = self.onEntitySuccess(entity, result);
}

- (void)entity:(id<KCSPersistable>)entity fetchDidFailWithError:(NSError *)error
{
    self.done = YES;
    self.testPassed = self.onEntityFailure(entity, error);
}

- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    self.done = YES;
    self.testPassed = self.onEntitySuccess(entity, result);
    self.done = YES;
}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    self.testPassed = self.onEntityFailure(entity, error);
    self.done = YES;
}


static NSString* access_token = @"CAACEdEose0cBAIMFZAoNuuNmjJKkxVmdaqzRXobI6obdAXkjAjb9G4yQNgtMZC3ZAUOkuNgwY1I01ZBw1rZBaJRpxoQaacPJiDSVfZCB7l2BZBZBDxP164mw0EqQb5wmyV6gGzW0RgjeG4R57nbb9DtEw04UDt31gaAUWatIs8aznZCDzZCIPZAPaVFN9ZCM0icWMVEZD";

- (void) testLoginWithFacebookOld
{
    [TestUtils justInitServer];
    // Ensure user is logged out
    [[KCSUser activeUser] logout];
    self.done = NO;
    [KCSUser loginWithSocialIdentity:KCSSocialIDFacebook accessDictionary:@{KCSUserAccessTokenKey : access_token} withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        XCTAssertNotNil(user, @"user should not be nil");
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        XCTAssertTrue(result.pingWasSuccessful, @"should have been a success.");
        self.done = YES;
    }];
    [self poll];
}

- (void) testLoginWithFacebookNew
{
    [TestUtils justInitServer];
    // Ensure user is logged out
    [[KCSUser activeUser] logout];
    self.done = NO;
    [KCSUser loginWithSocialIdentity:KCSSocialIDFacebook accessDictionary:@{KCSUserAccessTokenKey : access_token} withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        XCTAssertNotNil(user, @"user should not be nil");
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        XCTAssertTrue(result.pingWasSuccessful, @"should have been a success.");
        self.done = YES;
    }];
    [self poll];
}

/* function named this way to follow the login with FB */
//TODO: get this to work in the simulator
#if NEVER
- (void) testLoginWithFacebookPersists
{
    [TestUtils justInitServer];
    
    self.done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        STAssertTrue(result.pingWasSuccessful, @"should have been a success.");
        STAssertEqualObjects(lastUser, [KCSClient sharedClient].currentUser.username, @"user names should match");
        STAssertNotNil([KCSClient sharedClient].currentUser.sessionAuth, @"should have a valid session token");
        self.done = YES;
    }];
    [self poll];
}
#endif

- (void) testLoginWithTwitter
{
    [TestUtils justInitServer];
    // Ensure user is logged out
    [[KCSUser activeUser] logout];

    self.done = NO;
    [KCSUser loginWithSocialIdentity:KCSSocialIDTwitter accessDictionary:@{@"access_token" : @"823982046-Z0OrwAWQO3Ys2jtGM1k7hDnD6Ty9f54T1JRaDHHi",         @"access_token_secret" : @"3yIDGXVZV67m3G480stFgYk5eHZ7UCOSlOVHxh5RQ3g"}
     withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
         XCTAssertNotNil(user, @"user should not be nil");
         self.done = YES;
     }];
    
    [self poll];
    
    self.done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        XCTAssertTrue(result.pingWasSuccessful, @"should have been a success.");
        self.done = YES;
    }];
    [self poll];
}

- (void) testUserCollection
{
    self.done = NO;
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        self.done = YES;
    }];
    [self poll];
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
    self.done = NO;
    [store loadObjectWithID:[KCSUser activeUser].kinveyObjectId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if(errorOrNil) {
            NSLog(@"Failed to load users... %@", errorOrNil);
        } else {
            NSLog(@"%@", objectsOrNil);
        }
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

#pragma mark - User lifecycle
- (void) testUser
{
    [[KCSUser activeUser] logout];
    
    __block KCSUser* bUser = nil;
    self.done = NO;
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError
        XCTAssertNotNil(user, @"shuld have a user");
        bUser = user;
        
        self.done = YES;
    }];
    [self poll];
    
    KCSCollection* aC = [KCSCollection userCollection];
    aC.objectTemplate = [NSMutableDictionary class];
    KCSAppdataStore* us = [KCSAppdataStore storeWithCollection:aC options:nil];
    
    NSMutableDictionary* ur = [@{KCSEntityKeyId : bUser.userId, @"username" : bUser.username} mutableCopy];
    ur[@"TEST_PROP"] = @"TEST_VALUE";
    
    self.done = NO;
    [us saveObject:ur withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    NSString* savedProp = [[KCSUser activeUser] getValueForAttribute:@"TEST_PROP"];
    XCTAssertNil(savedProp, @"should not have updated the user");
    
    self.done = NO;
    [[KCSUser activeUser] refreshFromServer:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertEqualObjects(objectsOrNil[0], [KCSUser activeUser], @"should get back activeUser");
        self.done = YES;
    }];
    [self poll];

    NSString* loadedProp = [[KCSUser activeUser] getValueForAttribute:@"TEST_PROP"];
    XCTAssertNotNil(loadedProp, @"should have updated the user");

}

#pragma mark - Password reset

- (void) testPasswordReset
{
    //need to use a premade user
    self.done = NO;
    NSString* testUser = @"testino";
    [KCSUser loginWithUsername:testUser password:@"12345" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        self.done = YES;
    }];
    [self poll];
        
    self.done = NO;
    [KCSUser sendPasswordResetForUser:testUser withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(emailSent, @"Should send email");
        self.done = YES;
    }];
    [self poll];
}

- (void) testPasswordResetWithNoEmailDoesNotError
{
    //need to use a premade user
    self.done = NO;
    NSString* testUser = @"testino2";
    [KCSUser loginWithUsername:testUser password:@"12345" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [KCSUser sendPasswordResetForUser:testUser withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(emailSent, @"Should have send email, anyway");
        self.done = YES;
    }];
    [self poll];
}

- (void) testPasswordResetWithBadUserEmailDoesNotError
{
    NSString* testUser = @"BADUSER";
    self.done = NO;
    [KCSUser sendPasswordResetForUser:testUser withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(emailSent, @"Should have send email, anyway");
        self.done = YES;
    }];
    [self poll];

}

- (void) testEscapeUser
{
    NSString* testUser = @"abc . foo@foo.com";
    self.done = NO;
    [KCSUser sendPasswordResetForUser:testUser withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(emailSent, @"Should have send email, anyway");
        self.done = YES;
    }];
    [self poll];
}

- (void) testSendEmailConfirm
{
    self.done = NO;
    NSString* testUser = @"testino";
    [KCSUser loginWithUsername:testUser password:@"12345" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [KCSUser sendEmailConfirmationForUser:testUser withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(emailSent, @"Should send email");
        self.done = YES;
    }];
    [self poll];

}

#if NEVER
//TODO: fix this test -- no way to test passwords actually change w/o login and 401s
- (void) testChangePassword
{
    KCSUser* u = [self currentOrAutogen];
    STAssertNotNil(u, @"should have a user");
    NSString* currentPassword = u.password;
    NSString* newPasword = [NSString UUID];
    
    STAssertNotNil(currentPassword, @"current password should not be nil");
    STAssertFalse([currentPassword isEqualToString:newPasword], @"should be old password");
    
    self.done = NO;
    [u changePassword:newPasword completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertEqualObjects(newPasword, [[KCSUser activeUser] password], @"password should be updated");
//        NSString* newKeychainPwd = [KCSKeyChain getStringForKey:@"password"];
//        STAssertTrue([newKeychainPwd isEqualToString:newPasword], @"should be old password");
        
        self.done = YES;
    }];
    [self poll];
}
#endif

- (void) testForgotUsername
{
    self.done = NO;
    NSString* testUser = @"testino";
    [KCSUser loginWithUsername:testUser password:@"12345" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError;
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [KCSUser sendForgotUsername:[KCSUser activeUser].email withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(emailSent, @"Should send email");
        self.done = YES;
    }];
    [self poll];
}

#pragma mark - test custom items
//Assembla #3125
#warning todo-test check taht createAuto returns same object as [KCSUser activeUser]
- (void) testCustomAttributeIsPersisted
{
    //kk2: use dedicated user
    
    __block KCSUser* _user = nil;
    self.done = NO;
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError
        self.done = YES;
        
        _user = user;
    }];
    [self poll];
    
    NSString* val = [NSString UUID];
    [_user setValue:val forAttribute:@"custom"];
    
    self.done = NO;
    [_user saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        self.done = YES;
    }];
    [self poll];
    
    [[KCSUser activeUser] logout];
    
    KCSUser* newUser = [KCSUser activeUser];
    XCTAssertNotNil(newUser, @"a user");
    XCTAssertEqual(newUser, _user, @"should get back user");
    
    XCTAssertEqualObjects([newUser getValueForAttribute:@"custom"], val, @"should get the val back");
}

#pragma mark - check username
- (void) testCheckUsername
{
    [KCSUser checkUsername:@"not exist" withCompletionBlock:^(NSString *username, BOOL usernameAlreadyTaken, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertFalse(usernameAlreadyTaken, @"should not have the user");
        self.done = YES;
    }];
    [self poll];
    
    KCSUser* active = [self currentOrAutogen];
    XCTAssertNotNil(active, @"Should have a user");
    
    self.done = NO;
    [active saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        self.done = YES;
    }];
    [self poll];

    self.done = NO;
    [KCSUser checkUsername:active.username withCompletionBlock:^(NSString *username, BOOL usernameAlreadyTaken, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertTrue(usernameAlreadyTaken, @"should have the user");
        self.done = YES;
    }];
    [self poll];
}

#pragma mark - Others
- (void) testUsesSessionAuthCredentials
{
//    //create the user
//    self.done = NO;
//    [KCSUser userWithUsername:@"foo" password:@"bar" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
//        STAssertNoError;
//        self.done = YES;
//    }];
//    [self poll];
//    
    [[KCSUser activeUser] logout];
    NSString* token = [KCSKeychain2 kinveyTokenForUserId:@"foo"];
    XCTAssertNil(token, @"start clean");
    
    self.done = NO;
    [KCSUser loginWithUsername:@"foo" password:@"bar" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError
        self.done = YES;
    }];
    [self poll];
    
    token = [KCSKeychain2 kinveyTokenForUserId:@"foo"];
    XCTAssertNil(token, @"have a token");
}

@end
