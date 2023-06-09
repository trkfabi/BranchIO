/**
 * BranchIO
 *
 * Created by Fabian Martinez
 * Copyright (c) 2023 Your Company. All rights reserved.
 */

#import "ComInzoriBranchioModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"
@import BranchSDK;
//@import AppTrackingTransparency;
//@import AdSupport;

@implementation ComInzoriBranchioModule

bool logEnabled = NO;
bool useTestKey = YES;

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"43bfaf6b-04b6-4e71-a1db-3d5c7ed5aaf6";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"com.inzori.branchio";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  NSLog(@"[INFO] %@ loaded", self);
}

#pragma Public APIs
- (void)setUseTestBranchKey:(BOOL)useTestBranchKey
{
    if (logEnabled) {
        NSLog(@"[INFO] setUseTestBranchKey: %@", useTestBranchKey ? @"Yes" : @"No");
    }
    [Branch setUseTestBranchKey:useTestBranchKey];
}

- (void)setIdentity:(id)args
{

    NSString *userId = nil;
    KrollCallback *callback = nil;
    
    // if a callback is passed as an argument
    if ([args isKindOfClass:[NSString class]]) {
        ENSURE_SINGLE_ARG(args, NSString);
        userId = (NSString *)args;
    } else if ([args isKindOfClass:[NSArray class]]){
        ENSURE_TYPE([args objectAtIndex:0], NSString);
        userId = [args objectAtIndex:0];
        
        ENSURE_TYPE([args objectAtIndex:1], KrollCallback);
        callback = [args objectAtIndex:1];
    } else {
        return;
    }
    
    if (logEnabled) {
        NSLog(@"[INFO] setIdentity: %@", userId);
    }
    
    if (!callback) {
        [[Branch getInstance] setIdentity:userId];
    }
    else {
        [[Branch getInstance] setIdentity:userId withCallback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                [callback call:@[params, NUMBOOL(YES)] thisObject:nil];
            }
            else {
                [callback call:@[params, NUMBOOL(NO)] thisObject:nil];
            }
        }];
    }
}
- (void)logout:(id)args
{
    ENSURE_ARG_COUNT(args, 0);
    
    [[Branch getInstance] logoutWithCallback:^(BOOL changed, NSError *error) {
        if ( ! error) {
            [self fireEvent:@"bio:logout" withObject:@{@"result":@"success"}];
        } else {
            [self fireEvent:@"bio:logout" withObject:@{@"result":@"error", @"message":[error localizedDescription]}];
        }
    }];
}

- (void)userCompletedAction:(id)args
{
    NSString *name;
    NSDictionary *state;
    // if a state dictionary is passed as an argument
    if ([args count]==2) {
        ENSURE_TYPE([args objectAtIndex:0], NSString);
        name = [args objectAtIndex:0];
        
        ENSURE_TYPE([args objectAtIndex:1], NSDictionary);
        state = [args objectAtIndex:1];
    }
    else {
        ENSURE_SINGLE_ARG(args, NSString);
        name = (NSString *)args;
    }
    if (logEnabled) {
        NSLog(@"[INFO] userCompletedAction: %@", name);
    }
    BranchEvent *event = [BranchEvent customEventWithName:name];
    if (state) {
        event.customData = state;
    }
    event.alias = name;
    [event logEvent];
}

- (NSDictionary *)getLatestReferringParams:(id)args
{
    // session parameters
    ENSURE_ARG_COUNT(args, 0);
    return [[Branch getInstance] getLatestReferringParams];
}

- (NSDictionary *)getFirstReferringParams:(id)args
{
    // install parameters
    ENSURE_ARG_COUNT(args, 0);
    return [[Branch getInstance] getFirstReferringParams];;
}


//- (void)requestIDFAPermission {
//    if (@available(iOS 14.0, *)) {
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
//                if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
//                    NSUUID *idfa = [[ASIdentifierManager sharedManager] advertisingIdentifier];
//                    NSLog(@"[INFO] IDFA: %@", idfa);
//                } else {
//                    NSLog(@"[INFO] Failed to get IDFA permission");
//                }
//                dispatch_semaphore_signal(semaphore);
//            }];
//        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    }
//}

- (BOOL)setTrackingDisabled:(NSNumber *)disabled
{
    BOOL myBool = [disabled boolValue];

    [Branch setTrackingDisabled:myBool];
    if (logEnabled) {
        NSLog(@"[INFO] setTrackingDisabled - trackingDisabled? - %d" , [Branch trackingDisabled]);
    }
    
    return [Branch trackingDisabled];
}

- (BOOL)trackingDisabled:(id)args
{
    if (logEnabled) {
        NSLog(@"[INFO] trackingDisabled - trackingDisabled? - %d" , [Branch trackingDisabled]);
    }
    
    return [Branch trackingDisabled];
}

- (void)initSession:(id)args
{

    logEnabled = [TiUtils boolValue:@"logEnabled" properties:args def:YES];
    useTestKey = [TiUtils boolValue:@"useTestKey" properties:args def:YES];
    
    NSLog(@"[INFO] initSession logEnabled: %@ - useTestKey: %@", logEnabled ? @"YES": @"NO", useTestKey ? @"YES": @"NO");
    
    if (useTestKey) {
        [Branch setUseTestBranchKey:YES];
    }
    
    if (logEnabled) {
        [[Branch getInstance] enableLogging];
    }

    NSDictionary *launchOptions = [[TiApp app] launchOptions];
    
    [[Branch getInstance] initSessionWithLaunchOptions:launchOptions
                automaticallyDisplayDeepLinkController:NO
                                       deepLinkHandler:^(NSDictionary *params, NSError *error) {
        if (!error) {
            if (logEnabled) {
                NSLog(@"[INFO] initSession succeeded with params: %@", params);
            }
            [self fireEvent:@"bio:initSession" withObject:params];
        } else {
            if (logEnabled) {
                NSLog(@"[ERROR] initSession failed %@", error);
            }
            [self fireEvent:@"bio:initSession" withObject:@{@"error":[error localizedDescription]}];
        }
    }];
}

@end

@implementation TiApp (Branch)

//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    //if (logEnabled) {
//        NSLog(@"[INFO] didFinishLaunchingWithOptions");
//    //}
//
//    // listener for Branch Deep Link data
//    [[Branch getInstance] initSessionWithLaunchOptions:launchOptions
//                automaticallyDisplayDeepLinkController:NO
//                                       deepLinkHandler:^(NSDictionary * _Nonnull params, NSError * _Nullable error) {
//        // do stuff with deep link data (nav to page, display content, etc)
//        if (!error) {
//             //Referring params
//            //if (logEnabled) {
//                NSLog(@"[INFO] initSession succeded - Referring link params %@", params);
//            //}
//        } else {
//            //if (logEnabled) {
//                NSLog(@"[ERROR] initSession failed %@", error);
//            //}
//        }
//
//    }];
//
//    return YES;
//}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (logEnabled) {
        NSLog(@"[INFO] openURL");
    }
    if ([url.absoluteString containsString:@"link_click_id"])  {
      return [[Branch getInstance] application:app openURL:url options:options];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application
        continueUserActivity:(NSUserActivity *)userActivity
        restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    if (logEnabled) {
        NSLog(@"[INFO] continueUserActivity");
    }
    // handler for Universal Links
    if ([userActivity.webpageURL.absoluteString containsString:@"app.link"]) {
      return [[Branch getInstance] continueUserActivity:userActivity];
    }
    return YES;
}

@end
