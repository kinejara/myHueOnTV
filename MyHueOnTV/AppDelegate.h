//
//  AppDelegate.h
//  MyHueOnTV
//
//  Created by Jorge Villa on 9/11/15.
//  Copyright © 2015 Jorge Villa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HueSDK_iOS/HueSDK.h>
#import "BridgePushLinkViewController.h"
#import "BridgeSelectionViewController.h"
#import "LoadingViewController.h"

#define UIAppDelegate  ((AppDelegate *)[[UIApplication sharedApplication] delegate])

@class FirstViewController;
@class PHHueSDK;

@interface AppDelegate : UIResponder <UIApplicationDelegate, PHBridgePushLinkViewControllerDelegate, PHBridgeSelectionViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tapBarController;
@property (nonatomic, strong) LoadingViewController *loadingView;
@property (strong, nonatomic) PHHueSDK *phHueSDK;

#pragma mark - HueSDK

/**
 Starts the local heartbeat
 */
- (void)enableLocalHeartbeat;

/**
 Stops the local heartbeat
 */
- (void)disableLocalHeartbeat;

/**
 Starts a search for a bridge
 */
- (void)searchForBridgeLocal;

- (void)removeLoadingView;


@end

