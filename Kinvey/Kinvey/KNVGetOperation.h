//
//  KNVGetOperation.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KNVReadOperation.h"

@interface KNVGetOperation<T : NSObject<KNVPersistable>*> : KNVReadOperation<T, T>

@end
