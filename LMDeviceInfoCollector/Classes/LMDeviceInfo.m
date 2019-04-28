//
//  LMDeviceInfo.m
//  LMDeviceAndSimInfoDemo
//
//  Created by lemon on 2019/4/25.
//  Copyright © 2019年 Lemon. All rights reserved.
//

#import "LMDeviceInfo.h"
#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIDevice.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>


static NSString *const kLMSecurityUniqueID = @"com.lemon.unique.uniqueID";
static NSString *const kLMSecurityAccount  = @"com.lemon.unique.account";
static NSString *const kLMShortVersionString = @"CFBundleShortVersionString";
static NSString *const kLMBundleVersion = @"CFBundleVersion";
static NSString *const kLMBundleIdentifier = @"CFBundleIdentifier";
static NSString *const kLMDisplayName = @"CFBundleDisplayName";


@interface LMDeviceInfo()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIDevice *currentDevice;
@property (nonatomic, strong) NSDictionary *appInfo;
@property (nonatomic, copy) NSString *deviceUniqueID;
@property (nonatomic, copy) NSString *deviceIdfv;
@property (nonatomic, assign) BOOL   isJailBreak;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *detailModel;
@property (nonatomic, copy) NSString *systemName;
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *appBuildVersion;
@property (nonatomic, copy) NSString *appBundleID;
@property (nonatomic, copy) NSString *appDisplayName;
@end

@implementation LMDeviceInfo

#pragma mark - life cycle
+ (instancetype)shareDeviceInfo{
    static LMDeviceInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMDeviceInfo alloc]init];
    });
    return instance;
}

#pragma mark - DeviceInfo

- (BOOL)isJailBreak{
    //如果越狱机器安装了xCon这个插件，那么下面的方法就会检测不出来机器是否越狱。
    BOOL isJailBreak = NO;
    NSArray *paths = @[@"/Applications/Cydia.app",
                       @"/private/var/lib/apt/",
                       @"/private/var/lib/cydia",
                       @"/private/var/stash"];
    for (NSString *path in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return YES;
    }
    FILE *bash = fopen("/bin/bash", "r");
    if (bash != NULL) {
        fclose(bash);
        isJailBreak = YES;
    }
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    isJailBreak = (env != NULL);
    return isJailBreak;
}

- (NSString *)deviceUniqueID{
    if (!_deviceUniqueID) {
        _deviceUniqueID = [self fetchUniqueID];
    }
    return _deviceUniqueID;
}

- (NSString *)fetchUniqueID{
    NSDictionary *uniqueIdInfo = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge_transfer id)kSecClassGenericPassword,(__bridge_transfer id)kSecClass,kLMSecurityUniqueID, (__bridge_transfer id)kSecAttrService,kLMSecurityUniqueID, (__bridge_transfer id)kSecAttrAccount,(__bridge_transfer id)kSecAttrAccessibleAfterFirstUnlock,(__bridge_transfer id)kSecAttrAccessible,nil];
    //1.从keychain读取uniqueID
    NSMutableDictionary *queryUniqueId = [NSMutableDictionary dictionaryWithDictionary:uniqueIdInfo];
    NSDictionary *result = nil;
    [queryUniqueId setObject:(__bridge_transfer id)kCFBooleanTrue forKey:(__bridge_transfer id)kSecReturnData];
    [queryUniqueId setObject:(__bridge_transfer id)kSecMatchLimitOne forKey:(__bridge_transfer id)kSecMatchLimit];
    CFDictionaryRef queryUniqueIdRef = (__bridge_retained CFDictionaryRef)queryUniqueId;
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching(queryUniqueIdRef, (CFTypeRef *)&keyData) == noErr) {
        if (@available(iOS 12.0, *)) {
            NSError *error;
            result = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:(__bridge_transfer NSData *)keyData error:&error];
            if (error) {
                NSLog(@"解挡失败");
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            result = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)keyData];
#pragma clang diagnostic pop
        }
    }
    if (queryUniqueIdRef) {
        CFRelease(queryUniqueIdRef);
        queryUniqueIdRef = NULL;
    }
    NSString *uniqueId = result[kLMSecurityAccount];
    //2.读取失败，生成一个唯一id并且记录到keychain
    if (uniqueId == nil) {
        uniqueId = [self md5_32Bit:[self uuid]].lowercaseString;
        NSMutableDictionary *newUniqueIdInfo = [NSMutableDictionary dictionary];
        newUniqueIdInfo[kLMSecurityAccount] = uniqueId;
        NSMutableDictionary *newQueries = uniqueIdInfo.mutableCopy;
        SecItemDelete((__bridge CFMutableDictionaryRef)newQueries);
        id object;
        if (@available(iOS 12.0, *)) {
            NSError *error;
            object = [NSKeyedArchiver archivedDataWithRootObject:newUniqueIdInfo requiringSecureCoding:YES error:&error];
            if (error) {
                NSLog(@"存档失败");
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            object = [NSKeyedArchiver archivedDataWithRootObject:newUniqueIdInfo];
#pragma clang diagnostic pop
        }
        [newQueries setObject:object forKey:(__bridge id)kSecValueData];
        SecItemAdd((__bridge CFMutableDictionaryRef)newQueries, NULL);
    }
    return uniqueId;
}

- (NSString *)uuid {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [[uuid lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""]?:@"";
}

- (NSString *)deviceIdfv{
    if (!_deviceIdfv) {
        _deviceIdfv = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    return _deviceIdfv;
}

- (NSString *)detailModel
{
    if (!_detailModel) {
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *deviceModel = [NSString stringWithCString:systemInfo.machine
                                         encoding:NSUTF8StringEncoding];
        _detailModel = [self fetchiPhoneTypeWithDeviceModel:deviceModel];
    }
    return _detailModel;
}

- (NSString *)name{
    return [UIDevice currentDevice].name;
}
- (NSString *)model{
    return [UIDevice currentDevice].model;
}

- (NSString*)systemName{
    return [UIDevice currentDevice].systemName;
}

- (NSString *)systemVersion{
    return [UIDevice currentDevice].systemVersion;
}

#pragma mark - APPInfo
- (NSString *)appVersion{
    return self.appInfo[kLMBundleVersion];
}

- (NSString *)appBuildVersion{
    return self.appInfo[kLMBundleVersion];
}

- (NSString *)appBundleID{
    return self.appInfo[kLMBundleIdentifier];
}

- (NSString *)appDisplayName{
    return self.appInfo[kLMDisplayName];
}

#pragma mark - private method

- (NSString *)md5_32Bit:(NSString *)src {
    if (!src || [src isKindOfClass:[NSNull class]]) {
        return  @"";
    }
    const char *cStr = [src UTF8String];
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (int)strlen(cStr), md5);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [result appendFormat:@"%02x", md5[i]];
    }
    return result;
}

- (NSString*)fetchiPhoneTypeWithDeviceModel:(NSString*)deviceModel{
    if([deviceModel  isEqualToString:@"iPhone7,1"])  return @"iPhone 6 Plus";
    if([deviceModel  isEqualToString:@"iPhone7,2"])  return @"iPhone 6";
    if([deviceModel  isEqualToString:@"iPhone8,1"])  return @"iPhone 6s";
    if([deviceModel  isEqualToString:@"iPhone8,2"])  return @"iPhone 6s Plus";
    if([deviceModel  isEqualToString:@"iPhone8,4"])  return @"iPhone SE";
    if([deviceModel  isEqualToString:@"iPhone9,1"])  return @"iPhone 7";
    if([deviceModel  isEqualToString:@"iPhone9,2"])  return @"iPhone 7 Plus";
    if([deviceModel  isEqualToString:@"iPhone10,1"]) return @"iPhone 8";
    if([deviceModel  isEqualToString:@"iPhone10,4"]) return @"iPhone 8";
    if([deviceModel  isEqualToString:@"iPhone10,2"]) return @"iPhone 8 Plus";
    if([deviceModel  isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";
    if([deviceModel  isEqualToString:@"iPhone10,3"]) return @"iPhone X";
    if([deviceModel  isEqualToString:@"iPhone10,6"]) return @"iPhone X";
    if([deviceModel  isEqualToString:@"iPhone11,8"]) return @"iPhone XR";
    if([deviceModel  isEqualToString:@"iPhone11,2"]) return @"iPhone XS";
    if([deviceModel  isEqualToString:@"iPhone11,4"]) return @"iPhone XS Max";
    if([deviceModel  isEqualToString:@"iPhone11,6"]) return @"iPhone XS Max";
    if([deviceModel  isEqualToString:@"iPhone6,2"])  return @"iPhone 5s";
    if([deviceModel  isEqualToString:@"iPhone6,1"])  return @"iPhone 5s";
    if([deviceModel  isEqualToString:@"iPhone5,4"])  return @"iPhone 5c";
    if([deviceModel  isEqualToString:@"iPhone5,3"])  return @"iPhone 5c";
    if([deviceModel  isEqualToString:@"iPhone5,2"])  return @"iPhone 5";
    if([deviceModel  isEqualToString:@"iPhone5,1"])  return @"iPhone 5";
    if([deviceModel  isEqualToString:@"iPhone4,1"])  return @"iPhone 4S";
    if([deviceModel  isEqualToString:@"iPhone3,3"])  return @"iPhone 4";
    if([deviceModel  isEqualToString:@"iPhone3,2"])  return @"iPhone 4";
    if([deviceModel  isEqualToString:@"iPhone3,1"])  return @"iPhone 4";
    if([deviceModel  isEqualToString:@"iPhone2,1"])  return @"iPhone 3GS";
    if([deviceModel  isEqualToString:@"iPhone1,2"])  return @"iPhone 3G";
    if([deviceModel  isEqualToString:@"iPhone1,1"])  return @"iPhone 2G";
    // simulator 模拟器
    if ([deviceModel isEqualToString:@"i386"])   return @"Simulator";
    if ([deviceModel isEqualToString:@"x86_64"])  return @"Simulator";
    return deviceModel;
}

- (NSDictionary *)appInfo{
    if (!_appInfo) {
        NSBundle *currentBundle = [NSBundle mainBundle];
        _appInfo = [currentBundle infoDictionary];
    }
    return _appInfo;
}

- (UIDevice *)currentDevice{
    return [UIDevice currentDevice];
}

@end
