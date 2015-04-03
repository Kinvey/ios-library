//
//  KCSUser2+KinveyUserService.h
//  KinveyKit
//
//  Copyright (c) 2013 Kinvey. All rights reserved.
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

#import <KinveyKit/KinveyKit.h>

#import "KCSUser2.h"

typedef void (^KCSUser2CompletionBlock)(id<KCSUser2>user, NSError* error);

@interface KCSUser2 (KinveyUserService)

+ (id<KCSUser2>) activeUser;
+ (BOOL) hasSavedCredentials;
+ (BOOL) clearSavedCredentials;

+ (void) createAutogeneratedUser:(NSDictionary*)fieldsAndValues completion:(KCSUser2CompletionBlock)completionBlock;
+ (void) createUserWithUsername:(NSString*)username password:(NSString*)password fieldsAndValues:(NSDictionary*) fieldsAndValues completion:(KCSUser2CompletionBlock)completionBlock;

+ (void) loginWithUsername:(NSString *)username password:(NSString *)password completion:(KCSUser2CompletionBlock)completionBlock;
+ (void) connectWithAuthProvider:(KCSUserSocialIdentifyProvider)provider accessDictionary:(NSDictionary*)accessDictionary completion:(KCSUser2CompletionBlock)completionBlock;

+ (void) loginWithMICRedirectURI:(NSString*)redirectURI
          authorizationGrantType:(KCSMICAuthorizationGrantType)authorizationGrantType
                         options:(NSDictionary*)optons
                      completion:(KCSUser2CompletionBlock)completionBlock;

+ (NSURL*)URLforLoginWithMICRedirectURI:(NSString*)redirectURI;

+ (BOOL)isValidMICRedirectURI:(NSString*)redirectURI
                       forURL:(NSURL*)url;

+(void)parseMICRedirectURI:(NSString *)redirectURI
                    forURL:(NSURL *)url
       withCompletionBlock:(KCSUser2CompletionBlock)completionBlock;

+ (void) logoutUser:(id<KCSUser2>)user;


+ (void) changePasswordForUser:(id<KCSUser2>)user password:(NSString*)newPassword completion:(KCSUser2CompletionBlock)completionBlock;
+ (void) refreshUser:(id<KCSUser2>)user options:(NSDictionary*)options completion:(KCSUser2CompletionBlock)completionBlock;
+ (void) saveUser:(id<KCSUser2>)user options:(NSDictionary*)options completion:(KCSUser2CompletionBlock)completionBlock;
+ (void) deleteUser:(id<KCSUser2>)user options:(NSDictionary*)options completion:(KCSCountBlock)completionBlock;


+ (void) sendPasswordResetForUsername:(NSString*)username completion:(KCSUserSendEmailBlock)completionBlock;
+ (void) sendPasswordResetForEmail:(NSString*)email completion:(KCSUserSendEmailBlock)completionBlock;
+ (void) sendEmailConfirmationForUser:(NSString*)username completion:(KCSUserSendEmailBlock)completionBlock;
+ (void) sendForgotUsernameEmail:(NSString*)email completion:(KCSUserSendEmailBlock)completionBlock;
+ (void) checkUsername:(NSString*)potentialUsername completion:(KCSUserCheckUsernameBlock)completionBlock;

@end
