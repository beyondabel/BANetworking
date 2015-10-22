//
//  BAMacros.h
//  BANetworking
//
//  Created by abel on 15/9/6.
//  Copyright © 2015年 abel. All rights reserved.
//

#define BA_STRONG(obj) __typeof__(obj)
#define BA_WEAK(obj) __typeof__(obj) __weak
#define BA_WEAK_SELF BA_WEAK(self)

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#define BA_IOS_SDK_AVAILABLE 1
#else
#define BA_IOS_SDK_AVAILABLE 0
#endif
