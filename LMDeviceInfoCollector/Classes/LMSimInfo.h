//
//  LMSimInfo.h
//  LMDeviceAndSimInfoDemo
//
//  Created by lemon on 2019/4/25.
//  Copyright © 2019年 Lemon. All rights reserved.
//

#import <Foundation/Foundation.h>

 //运营商类型
typedef NS_ENUM(NSInteger, LMCarrierType) {
    LMCarrierTypeUnknown = 0,   //未知
    LMCarrierTypeCMCC = 1,     //中国移动
    LMCarrierTypeUnicom = 2,   //中国联通
    LMCarrierTypeTelecom = 3   //中国电信
};

//网络类型
typedef NS_ENUM(NSInteger,LMNetworkType) {
    LMNetworkTypeNoNetwork = 0, //无网络
    LMNetworkTypeCellular = 1,  //蜂窝网络
    LMNetworkTypeWifi = 2,      //wifi网络
};

//蜂窝网络类型
typedef NS_ENUM(NSInteger,LMCellularType) {
    LMCellularTypeUnknown = 0,  //无蜂窝网络
    LMCellularType2G = 1,      //2G
    LMCellularType3G = 2,      //3G
    LMCellularType4G = 3,      //4G
};


NS_ASSUME_NONNULL_BEGIN

@interface LMSimInfo : NSObject
@property (nonatomic, copy,   readonly) NSString       *imsi;               //国际移动用户识别码，mcc+mnc
@property (nonatomic, assign, readonly) LMCarrierType  carrierType;         //当前上网sim卡运营商类型
@property (nonatomic, assign, readonly) NSUInteger     simCount;            //sim卡数量

@property (nonatomic, assign, readonly) LMNetworkType  networkType;         //当前网络环境（无网络/蜂窝网络/wifi网络）
@property (nonatomic, assign, readonly) LMCellularType cellularType;        //当前移动网络类型（未知/2G/3G/4G）
@property (nonatomic, copy,   readonly) NSString       *currentIPv4Address; //当前的ipV4地址，wifi或者蜂窝网络
@property (nonatomic, copy,   readonly) NSString       *currentIPv6Address; //当前的ipV6地址，wifi或者蜂窝网络
@property (nonatomic, strong, readonly) NSArray        *ipv4List;           //IPV4 地址列表，包含wifi和蜂窝
@property (nonatomic, strong, readonly) NSArray        *ipv6List;           //IPV6 地址列表，包含wifi和蜂窝
@property (nonatomic, copy,   readonly) NSString       *wifiName;    //wifi名称


+ (instancetype)shareSimInfo;
@end

NS_ASSUME_NONNULL_END
