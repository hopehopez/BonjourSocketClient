//
//  BonjourSocketClient.h
//  BonjourSocketClient
//
//  Created by 张树青 on 2017/5/24.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BonjourSocketClient : NSObject

+ (instancetype)shareInstance;
- (void)findServer:(NSString *)serverName;
- (void)stop;
- (void)sendMessage:(NSString *)message;

@end
