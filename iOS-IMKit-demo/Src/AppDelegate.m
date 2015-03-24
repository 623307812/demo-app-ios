//
//  AppDelegate.m
//  iOS-IMKit-Demo
//
//  Created by Heq.Shinoda on 14-4-30.
//  Copyright (c) 2014年 iOS-IMKit-Demo. All rights reserved.
//

#import "AppDelegate.h"
#import "SigninViewController.h"
#import "DemoUIConstantDefine.h"
#import "DemoCommonConfig.h"
#import  <libNBSAppAgent/NBSAppAgent.h>


//使用DEMO注意：更换appkey，一定要更换对应的连接token，如果token未做变化，默认会从融云测试环境获取，照成appkey和token不一致
#define RONGCLOUD_IM_APPKEY    @"e0x9wycfx7flq"
//使用DEMO注意：更换appkey，一定要更换对应的连接token，如果token未做变化，默认会从融云测试环境获取，照成appkey和token不一致

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //注册听云
    [NBSAppAgent  startWithAppID:@"a546c342ba704acf91b27e9603b6860d"];
    NSString* appKey = [self readAppKeyFromConfig];
    [RCIM initWithAppKey:appKey deviceToken:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    SigninViewController* loginVC = [[SigninViewController alloc] init];
    
    //注册百度地图
    self.mapManager = [[BMKMapManager alloc] init];
    BOOL ret = [self.mapManager start:@"1GNhg2fYLdCKfjcOtnADRMa1" generalDelegate:self];
    if (!ret) {
        DebugLog(@"百度地图启动失败");
    }

    [loginVC.view setFrame:self.window.frame];

    UINavigationController *rootNavi = [[UINavigationController alloc] initWithRootViewController:loginVC];

    [rootNavi.navigationBar setBackgroundImage:[self createImageWithColor:RGBCOLOR(43, 132, 210)] forBarMetrics:UIBarMetricsDefault];
    self.window.rootViewController = rootNavi;

    [self.window.rootViewController.view addSubview:loginVC.view];
    [self.window makeKeyAndVisible];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    return YES;
}


//#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}
//#endif



- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = [[RCIM sharedRCIM] getTotalUnreadCount];
    
    //勿扰时段内关闭本地通知
    [[RCIM sharedRCIM] getConversationNotificationQuietHours:^(NSString *startTime, int spansMin) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        if (startTime && startTime.length != 0) {
            NSDate *startDate = [dateFormatter dateFromString:startTime];
            NSDate *endDate = [startDate dateByAddingTimeInterval:spansMin * 60];
            NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
            NSDate *nowDate = [dateFormatter dateFromString:nowDateString];


            NSDate *earDate = [startDate earlierDate:nowDate];
            NSDate *laterDate = [endDate laterDate:nowDate];
            
            if (([startDate isEqualToDate:earDate] && [endDate isEqualToDate:laterDate]) || [nowDate isEqualToDate:startDate] || [nowDate isEqualToDate:earDate]) {
                
                //设置本地通知状态为关闭
                [[RCIM sharedRCIM] setMessageNotDisturb:YES];
                
            }else{
                
                [[RCIM sharedRCIM] setMessageNotDisturb:NO];
            }

        }
        
    } errorCompletion:^(RCErrorCode status) {
        
    }];

    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    DebugLog(@"error:%@",error);
    
    
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    DebugLog(@"RemoteNote userInfo:%@",userInfo);
    DebugLog(@" 收到推送消息： %@",userInfo[@"aps"][@"alert"]);
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{

    DebugLog(@"deviceToken:%@",deviceToken);
    [[RCIM sharedRCIM]setDeviceToken:deviceToken];
//    if (deviceToken) {
//        NSString* token = [[[[deviceToken description]
//                   stringByReplacingOccurrencesOfString:@"<" withString:@""]
//                  stringByReplacingOccurrencesOfString:@">" withString:@""]
//                 stringByReplacingOccurrencesOfString:@" " withString:@""];
//        
//        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"测试获取token" message:token delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil];
//        [alertView show];
//    }else
//    {
//        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"测试获取token" message:@"fail"delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil];
//        [alertView show];
//    }
    
}

-(UIImage *)createImageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}

-(NSString*)readAppKeyFromConfig
{
//    return RONGCLOUD_IM_APPKEY;
    
    NSString *pAppKeyPath = [[NSBundle mainBundle] pathForResource:RC_APPKEY_CONFIGFILE ofType:@""];//[documentsDir stringByAppendingPathComponent:RC_APPKEY_CONFIGFILE];
    NSError *error;
    NSString *valueOfKey = [NSString stringWithContentsOfFile:pAppKeyPath encoding:NSUTF8StringEncoding error:&error];
    NSString* appKey;
    if([valueOfKey intValue] == 0)  //开发环境：0 生产环境：1
        appKey = RONGCLOUD_IM_APPKEY;//@"uwd1c0sxdlx91";
    else
//        appKey = @"3argexb6rnlre";
        appKey = @"z3v5yqkbv8v30";//@"8luwapkvuxvel";
    return appKey;
}

#pragma mark -
#pragma mark BMKGeneralDelegate
- (void)onGetNetworkState:(int)iError {
    DebugLog(@"百度地图：网络状态 %i", iError);
}

- (void)onGetPermissionState:(int)iError {
    DebugLog(@"百度地图：授权状态 %i", iError);
}

@end
