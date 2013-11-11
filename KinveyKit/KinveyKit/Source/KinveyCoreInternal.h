//
//  KinveyCoreInternal.h
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, un0derstand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

#ifndef KinveyKit_KinveyCoreInternal_h
#define KinveyKit_KinveyCoreInternal_h

#import "KinveyCore.h"

#pragma mark - Network

#import "KCSRequest2.h"
#import "KCSNetworkOperation.h"
#import "KCSNetworkResponse.h"
#import "KCSCredentials.h"

#pragma mark - Configuration

#import "KCSClient2+KCSInternal.h"
#import "KCSClientConfiguration+KCSInternal.h"

#pragma mark - Utils

#import "KCSPlatformUtils.h"
#import "KCSFileUtils.h"
#import "KCSLog.h"
#import "KCSLogFormatter.h"
#import "NSArray+KinveyAdditions.h"
#import "NSDictionary+KinveyAdditions.h"
#import "NSError+KinveyKit.h"
#import "NSString+KinveyAdditions.h"
#import "KCSBase64.h"
#import "KCSTimedQueue.h"

#pragma mark - helpers

#import "EXTScope.h"
#import "KCS_SBJson.h"

#define KCS_CONST_IMPL NSString* const
#define KCS_BREAK NSAssert(NO, @"BROKEN");

#endif
