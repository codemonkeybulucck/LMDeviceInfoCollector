//
//  LMSimInfo.m
//  LMDeviceAndSimInfoDemo
//
//  Created by lemon on 2019/4/25.
//  Copyright © 2019年 Lemon. All rights reserved.
//

#import "LMSimInfo.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTCarrier.h>
#import <UIKit/UIKit.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <objc/runtime.h>

static NSString *const kLMSimInfoKeyIPV4 = @"ipv4";
static NSString *const kLMSimInfoKeyIPV6 = @"ipv6";
static NSString *const kLMSimInfoKeyIPV4List = @"ipv4List";
static NSString *const kLMSimInfoKeyIPV6List = @"ipv6List";
static NSString *const kLMSimInfoKeyWIFIIPV4 = @"en0/ipv4";
static NSString *const kLMSimInfoKeyWIFIIPV6 = @"en0/ipv6";
static NSString *const kLMSimInfoKeyCellularIPV4 = @"pdp_ip0/ipv4";
static NSString *const kLMSimInfoKeyCellularIPV6 = @"pdp_ip0/ipv6";

@interface LMSimInfo()
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
@property (nonatomic, copy) NSString *imsi;
@property (nonatomic, assign) LMCarrierType carrierType;
@property (nonatomic, assign) NSUInteger simCount;
@property (nonatomic, assign) LMNetworkType networkType;
@property (nonatomic, assign) LMCellularType cellularType;
@property (nonatomic, copy)   NSString *currentIPv4Address;
@property (nonatomic, copy)   NSString *currentIPv6Address;
@property (nonatomic, strong) NSArray *ipv4List;
@property (nonatomic, strong) NSArray *ipv6List;
@property (nonatomic, copy) NSString *wifiName;
@end

@implementation LMSimInfo

#pragma mark - LIFE CYCLE
+ (instancetype)shareSimInfo{
    static LMSimInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMSimInfo alloc]init];
    });
    return instance;
}


#pragma mark - SIMINFO
- (NSString *)imsi{
    NSArray<CTCarrier *> *carriers = [self carriers];
    if (carriers.count == 0) {
        return nil;
    }
    CTCarrier *carrier = carriers.firstObject;
    NSString *mnc = carrier.mobileNetworkCode;
    NSString *mcc = carrier.mobileCountryCode;
    return [NSString stringWithFormat:@"%@%@",mcc,mnc];
}

- (NSUInteger)simCount{
    NSArray<CTCarrier *> *carriers = [self carriers];
    return [carriers count];
}

- (LMCarrierType)carrierType{
    NSArray<CTCarrier *> *carriers = [self carriers];
    NSString *carrierName = @"unknown";
    //如果是双卡
    if (carriers.count == 2) {
        NSArray *subViewArray = @[@"_statusBar", @"_statusBar",
                                  @"_currentData", @"_cellularEntry",
                                  @"_string"];;
        id target = [UIApplication sharedApplication];
        NSUInteger totolViewCount = subViewArray.count;//全部层级数
        NSUInteger currentViewIndex = 0; //当前遍历的层级数
        for (NSString *subView in subViewArray) {
            NSArray *ivarList = [self ivarsInObject:target];
            if ([ivarList containsObject:subView]) {
                currentViewIndex ++;
                target = [target valueForKeyPath:subView];//找到下一层级继续遍历
            }
        }
        if (totolViewCount == currentViewIndex) {
            carrierName = target;
        }
    }else if(carriers.count == 1){
        carrierName = carriers.firstObject.carrierName;
    }
    LMCarrierType carrierType = [self carrierTypeWithCarrierName:carrierName];
    return carrierType;
}



#pragma mark - NETWORK INFO
- (LMNetworkType)networkType{
    NSString *url = @"www.baidu.com";
    SCNetworkReachabilityRef _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [url UTF8String]);
    SCNetworkReachabilityFlags flags = 0;
    LMNetworkType networkType = LMNetworkTypeNoNetwork;
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
        BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
        BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
        BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
        BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
        if (isNetworkReachable == NO) {
            networkType = LMNetworkTypeNoNetwork;
        }
#if    TARGET_OS_IPHONE
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
            networkType = LMNetworkTypeCellular;
        }
#endif
        else {
            networkType = LMNetworkTypeWifi;
        }
    }
    CFRelease(_reachabilityRef);
    return networkType;
}

- (NSArray *)ipv4List{
    return [self ipAddress][kLMSimInfoKeyIPV4List];
}

- (NSArray *)ipv6List{
    return [self ipAddress][kLMSimInfoKeyIPV6List];
}

- (NSString *)currentIPv4Address{
    NSString *address = [self ipAddress][kLMSimInfoKeyIPV4];
    return address;
}

- (NSString *)currentIPv6Address{
    NSString *address = [self ipAddress][kLMSimInfoKeyIPV6];
    return address;

}

- (NSString *)wifiName{
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    NSString *wifiNameStr = @"unknown";
    if (wifiInterfaces) {
        CFIndex wifiInterfaceCount = CFArrayGetCount(wifiInterfaces);
        for (CFIndex cf_i = 0; cf_i < wifiInterfaceCount; cf_i += 1) {
            CFStringRef interfaceName = CFArrayGetValueAtIndex(wifiInterfaces, cf_i);
            CFDictionaryRef interfaceDict = CNCopyCurrentNetworkInfo(interfaceName);
            if (interfaceDict) {
                CFStringRef wifiName = CFDictionaryGetValue(interfaceDict, kCNNetworkInfoKeySSID);
                wifiNameStr = (__bridge NSString *)wifiName;
                CFRelease(interfaceDict);
            }
        }
        CFRelease(wifiInterfaces);
    }
    return wifiNameStr;
}


- (NSDictionary*)ipAddress{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = kLMSimInfoKeyIPV4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = kLMSimInfoKeyIPV6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    if (addresses.count) {
        NSMutableString *ipv4List = [NSMutableString string];
        NSMutableString *ipv6List = [NSMutableString string];
        NSString *ipv4Address = @"";
        NSString *ipv6Address = @"";
        LMNetworkType networkType = self.networkType;
        [addresses enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *ipKey = (NSString*)key;
            NSString *value = (NSString*)obj;
            if ([ipKey containsString:kLMSimInfoKeyIPV4]) {
                [ipv4List appendString:[NSString stringWithFormat:@"%@,",value]];
            }else if ([ipKey containsString:kLMSimInfoKeyIPV6]){
                [ipv6List appendString:[NSString stringWithFormat:@"%@,",value]];
            }
        }];
        NSMutableDictionary *ipDict = [NSMutableDictionary dictionary];
        if (networkType == LMNetworkTypeWifi) {
            ipv4Address = addresses[kLMSimInfoKeyWIFIIPV4];
            ipv6Address = addresses[kLMSimInfoKeyWIFIIPV6];
        }else if (networkType == LMNetworkTypeCellular) {
            ipv4Address = addresses[kLMSimInfoKeyCellularIPV4];
            ipv6Address = addresses[kLMSimInfoKeyCellularIPV6];
        }
        ipDict[kLMSimInfoKeyIPV4List] = ipv4List;
        ipDict[kLMSimInfoKeyIPV6List] = ipv6List;
        ipDict[kLMSimInfoKeyIPV4] = ipv4Address;
        ipDict[kLMSimInfoKeyIPV6] = ipv6Address;
        return ipDict;
    }
    return nil;
}

#pragma mark - PRIVATE METHOD
//由于可能用户会切换上网卡或者换卡，所以需要实时获取
- (void)updateSimInfo{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    if (!info) {
        self.simCount = 0;
        self.carrierType = LMCarrierTypeUnknown;
        self.imsi = @"";
        return;
    }
    NSString *mnc= @"";
    NSString *mcc = @"";
    if (@available(iOS 12.0, *)) {
        NSDictionary<NSString *, CTCarrier *> *serviceCarrierInfo = [info serviceSubscriberCellularProviders];
        NSArray <CTCarrier *>* carriers = [serviceCarrierInfo allValues];
        //单卡
        if (carriers.count == 1) {
            CTCarrier *carrier = carriers.firstObject;
            NSString *carrierName = carrier.carrierName;
            mnc = carrier.mobileNetworkCode;
            mcc = carrier.mobileCountryCode;
            self.simCount = 1;
            self.carrierType = [self carrierTypeWithCarrierName:carrierName];
            self.imsi = [NSString stringWithFormat:@"%@%@",mcc,mnc];
        }else if(carriers.count == 2){
        //双卡,获取上网卡
            id target = [UIApplication sharedApplication];
            NSString *carrierName = @"";
            NSArray<NSString *> *revereTargetKeys = @[@"_statusBar", @"_statusBar",
                                                      @"_currentData", @"_cellularEntry",
                                                      @"_string"];
            NSUInteger totalLevel = revereTargetKeys.count; //总遍历层级
            NSUInteger enumLevel = 0; //当前已遍历状态栏层级
            for (NSString *targetKey in revereTargetKeys) {
                NSArray<NSString *> *arr = [self ivarsInObject:target];
                if ([arr containsObject:targetKey]) {
                    target = [target valueForKeyPath:targetKey];
                    enumLevel += 1;
                }
            }
            if (totalLevel == enumLevel) { //如果遍历完成所有层级
                carrierName = target;
            }
        }else{
            
        }
    }else{
    }

}

- (NSArray<CTCarrier*>*)carriers{
    NSMutableArray<CTCarrier *> *carrierArray = [NSMutableArray array];
    if (@available(iOS 12.0, *)) {
        NSDictionary<NSString *, CTCarrier *> *serviceCarrierInfo = [self.networkInfo serviceSubscriberCellularProviders];
        NSArray <CTCarrier *>* carriers = [serviceCarrierInfo allValues];
        [carrierArray addObjectsFromArray:carriers];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CTCarrier *carrier = [self.networkInfo subscriberCellularProvider];
#pragma clang diagnostic pop
        if (!carrier) {
            [carrierArray addObject:carrier];
        }
    }
    return carrierArray;
}

- (NSArray<NSString *> *)ivarsInObject:(id)object {
    //创建成员变量数组
    NSMutableArray *ivars = [NSMutableArray array];
    if (object) {
        unsigned int count = 0;
        Ivar *ivarsList = class_copyIvarList([object class],&count);
        //遍历数组
        for (int i = 0; i < count; i++) {
            // 1. 根据下标获取成员变量
            Ivar ivar = ivarsList[i];
            // 2. 获取成员变量的名称
            const char *cName = ivar_getName(ivar);
            // 3. 转换成 NSString
            NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
            [ivars addObject:name];
        }
        //释放对象 free
        free(ivarsList);
        ivarsList = NULL;
    }
    
    return ivars.copy;
}

- (LMCarrierType)carrierTypeWithCarrierName:(NSString*)carrierName{
    NSDictionary <NSString *, NSNumber*>*carrierInfo = @{@"中国移动":@(LMCarrierTypeCMCC),
                     @"中国联通":@(LMCarrierTypeUnicom),
                     @"中国电信":@(LMCarrierTypeTelecom),};
    LMCarrierType carrierType = carrierInfo[carrierName].integerValue;
    return carrierType;
}


#pragma mark - LAZY LOAD
- (CTTelephonyNetworkInfo *)networkInfo{
    if (!_networkInfo) {
        _networkInfo = [[CTTelephonyNetworkInfo alloc]init];
    }
    return _networkInfo;
}

@end
