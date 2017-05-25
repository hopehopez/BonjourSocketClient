//
//  BonjourSocketClient.m
//  BonjourSocketClient
//
//  Created by 张树青 on 2017/5/24.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import "BonjourSocketClient.h"
#import "AsyncSocket.h"
@interface BonjourSocketClient () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, strong) AsyncSocket *clientSocket;
@property (nonatomic, strong) NSNetServiceBrowser *serverBroeser;
@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, strong) NSMutableArray *serverAddresses;
@property (nonatomic, strong) NSNetService *netService;
@end

@implementation BonjourSocketClient

+ (instancetype)shareInstance{
    static BonjourSocketClient *_socketClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _socketClient = [[BonjourSocketClient alloc] init];
        _socketClient.socketQueue = dispatch_queue_create("ClientSocketQueue", NULL);
    });
    return _socketClient;
}

- (void)findServer:(NSString *)serverName{
    [self stop];
    
    self.serverName = serverName;
    self.serverBroeser = [[NSNetServiceBrowser alloc] init];
    self.serverBroeser.delegate = self;
    [self.serverBroeser searchForServicesOfType:@"_chatty._tcp." inDomain:@"local."];
   
    
}

- (void)stop{
    [self.clientSocket disconnect];
    self.clientSocket = nil;
    
    [self.serverBroeser stop];
    self.serverBroeser = nil;
}

- (void)connect:(NSNetService *)service{

    self.clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
    [self.clientSocket readDataWithTimeout:-1 tag:100];
    
    BOOL done = NO;
    
    while (!done && ([self.serverAddresses count] > 0))
    {
        NSData *addr;
        
        // Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
        //
        // If your server is also using GCDAsyncSocket then you don't have to worry about it,
        // as the socket automatically handles both protocols for you transparently.
        
        if (YES) // Iterate forwards
        {
            addr = [self.serverAddresses objectAtIndex:0];
            [self.serverAddresses removeObjectAtIndex:0];
        }
        else // Iterate backwards
        {
            addr = [self.serverAddresses lastObject];
            [self.serverAddresses removeLastObject];
        }
        
        NSLog(@"Attempting connection to %@", addr);
        
        NSError *err = nil;
        if ([self.clientSocket connectToAddress:addr error:&err])
        {
            done = YES;
        }
        else
        {
            NSLog(@"Unable to connect: %@", err);
        }
        
    }
    
    if (!done)
    {
        NSLog(@"Unable to connect to any resolved address");
    }

    
//    NSError *error = nil;
//    [self.clientSocket connectToHost:service.hostName onPort:service.port error:&error];
//    if (error) {
//        NSLog(@"client连接失败: %@", error);
//        self.clientSocket.delegate = nil;
//        self.clientSocket = nil;
//        [self performSelector:@selector(findServer:) withObject:self.serverName afterDelay:2];
//    } else {
//        NSLog(@"client连接成功");
//    }
//    
//    [[NSRunLoop currentRunLoop] run];

}
- (void)sendMessage:(NSString *)message{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:100];
}


#pragma mark NSNetServiceBrowser 代理
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser{
     NSLog(@"开始查找服务: %@", self.serverName);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser{
    NSLog(@"停止查找服务");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict{
    NSLog(@"查找服务失败: %@", errorDict);
    [self performSelector:@selector(findServer:) withObject:self.serverName afterDelay:2.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing{
    if ([service.name isEqualToString:self.serverName]) {
        NSLog(@"发现服务: %@, 停止扫描", service.name);
        self.netService = service;
        service.delegate = self;
        [service resolveWithTimeout:5.0];
        [self.serverBroeser stop];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing{
    if ([service.name isEqualToString:self.serverName]) {
        NSLog(@"服务%@, 取消发布", service.name);
        [self findServer:self.serverName];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    if (self.serverAddresses == nil)
    {
        self.serverAddresses = [[sender addresses] mutableCopy];
    }
    
    [self connect:sender];
    
}


#pragma mark - GCDAsyncSocket 代理
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"socket连接到host: %@, %d", host, port);
    NSData *data1 = [@"123" dataUsingEncoding:NSUTF8StringEncoding];
    
    [sock writeData:data1 withTimeout:-1 tag:100];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"BonjourSocket收到消息: %@", str);
    NSData *data1 = [@"500" dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:data1 withTimeout:-1 tag:500];

}
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag{
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    NSLog(@"socket断开连接");
    
    [self findServer:self.serverName];

}


@end
