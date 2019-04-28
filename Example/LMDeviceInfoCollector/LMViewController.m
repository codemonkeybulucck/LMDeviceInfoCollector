//
//  LMViewController.m
//  LMDeviceInfoCollector
//
//  Created by 545390087@qq.com on 04/26/2019.
//  Copyright (c) 2019 545390087@qq.com. All rights reserved.
//

#import "LMViewController.h"
#import <LMDeviceInfoCollector/LMDeviceInfo.h>
#import <LMDeviceInfoCollector/LMSimInfo.h>
#import <objc/runtime.h>


@interface LMViewController ()
- (IBAction)showSimInfo:(id)sender;
- (IBAction)showDeviceInfo:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end

@implementation LMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)showSimInfo:(id)sender {
    LMSimInfo *simInfo = [LMSimInfo shareSimInfo];
    NSArray *keys = @[@"国际移动用户识别码",@"Sim卡运营商类型",@"sim卡数量",@"当前网络环境",@"移动网络类型",@"ipV4地址",@"ipv6地址",@"ipv4列表",@"ipv6列表",@"wifi名称"];
    NSString *description = [self propertyDescription:simInfo offset:1 kes:keys];
    self.infoLabel.text = description;
}

- (IBAction)showDeviceInfo:(id)sender {
    LMDeviceInfo *deviceInfo = [LMDeviceInfo shareDeviceInfo];
    NSArray *keys = @[@"设备唯一ID",@"vendorID",@"是否越狱",@"设备别名",@"设备类型",@"设备型号",@"系统名称",@"系统版本",@"app版本",@"appBuild版本",@"appBundleID",@"app名字"];
    NSString *description = [self propertyDescription:deviceInfo offset:3 kes:keys];
    self.infoLabel.text = description;
}

- (NSString *)propertyDescription:(NSObject*)obj offset:(int)offset kes:(NSArray*)keys{
    unsigned int outCount;
    NSMutableString *mStr = [NSMutableString string];
    objc_property_t*properties = class_copyPropertyList([obj class], &outCount);
    for (int i = 0; i<outCount-offset; i++) {
        objc_property_t property = properties[i+offset];
        const char* charProperty = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:charProperty];
        id propertyValue = [obj valueForKey:propertyName];
        NSString *key = keys[i];
        [mStr appendString:[NSString stringWithFormat:@"%@:%@\n\n",key,propertyValue]];
    }
    return [mStr copy];
}





@end
