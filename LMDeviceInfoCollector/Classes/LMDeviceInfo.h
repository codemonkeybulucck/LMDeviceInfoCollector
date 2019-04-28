//
//  LMDeviceInfo.h
//  LMDeviceAndSimInfoDemo
//
//  Created by lemon on 2019/4/25.
//  Copyright © 2019年 Lemon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMDeviceInfo : NSObject
@property (nonatomic, copy, readonly) NSString *deviceUniqueID;    //设备唯一ID，保存在keychain
@property (nonatomic, copy, readonly) NSString *deviceIdfv;        //vendorID，同一个账号下的APP的vendor是相同的。
@property (nonatomic, assign, readonly) BOOL   isJailBreak;        ///设备是否越狱

@property (nonatomic, copy, readonly) NSString *name;              //用户设置iPhone的名字，如"My iPhone"
@property (nonatomic, copy, readonly) NSString *model;             //设备类型，如 @"iPhone", @"iPod touch"
@property (nonatomic, copy, readonly) NSString *detailModel;       //iPhone具体型号，如@"iPhone 6S"
@property (nonatomic, copy, readonly) NSString *systemName;        //系统名称， @"iOS"
@property (nonatomic, copy, readonly) NSString *systemVersion;     //系统版本

@property (nonatomic, copy, readonly) NSString *appVersion;        //app版本
@property (nonatomic, copy, readonly) NSString *appBuildVersion;   //app构建版本
@property (nonatomic, copy, readonly) NSString *appBundleID;       //appBundleID
@property (nonatomic, copy, readonly) NSString *appDisplayName;    //app名称

+ (instancetype)shareDeviceInfo;
@end

NS_ASSUME_NONNULL_END
