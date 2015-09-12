//
//  AppDelegate.m
//  MyHueOnTV
//
//  Created by Jorge Villa on 9/11/15.
//  Copyright © 2015 Jorge Villa. All rights reserved.
//

#import "AppDelegate.h"

#import "BridgePushLinkViewController.h"
#import "BridgeSelectionViewController.h"
#import "LoadingViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) PHBridgeSearching *bridgeSearch;
@property (nonatomic, strong) LoadingViewController *loadingView;
@property (nonatomic, strong) BridgePushLinkViewController *pushLinkViewController;
@property (nonatomic, strong) BridgeSelectionViewController *bridgeSelectionViewController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self enableHueSdk];
    [self registerToHueNotifications];
    [self enableLocalHeartbeat];
    
    self.tapBarController = (UITabBarController *)self.window.rootViewController.childViewControllers.lastObject;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self enableLocalHeartbeat];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)enableHueSdk {
    // Create sdk instance
    self.phHueSDK = [[PHHueSDK alloc] init];
    [self.phHueSDK startUpSDK];
    [self.phHueSDK enableLogging:YES];
}

- (void)registerToHueNotifications {
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(notAuthenticated) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
}

#pragma mark - HueSDK

/**
 Notification receiver for successful local connection
 */
- (void)localConnection {
    // Check current connection state
    [self checkConnectionState];
}

/**
 Notification receiver for failed local connection
 */
- (void)noLocalConnection {
    // Check current connection state
    [self checkConnectionState];
}

/**
 Notification receiver for failed local authentication
 */
- (void)notAuthenticated {
    /***************************************************
     We are not authenticated so we start the authentication process
     *****************************************************/
    // Move to main screen (as you can't control lights when not connected)
    //[self.navigationController popToRootViewControllerAnimated:YES];
    
    // Dismiss modal views when connection is lost
//    if (self.navigationController.presentedViewController) {
//        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
//    }
    
    // Remove no connection alert
//    if (self.noConnectionAlert != nil) {
//        [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:YES];
//        self.noConnectionAlert = nil;
//    }
    
    /***************************************************
     doAuthentication will start the push linking
     *****************************************************/
    
    // Start local authenticion process
    [self performSelector:@selector(doAuthentication) withObject:nil afterDelay:0.5];
}

- (void)checkConnectionState {
    if (!self.phHueSDK.localConnected) {
//        // Dismiss modal views when connection is lost
//        if (self.navigationController.presentedViewController) {
//            [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
//        }
        
        // No connection at all, show connection popup
        
//        if (self.noConnectionAlert == nil) {
//            [self.navigationController popToRootViewControllerAnimated:YES];
//            
//            // Showing popup, so remove this view
          [self removeLoadingView];
//            [self showNoConnectionDialog];
//        }
        
    }
    else {
        // One of the connections is made, remove popups and loading views
        
//        if (self.noConnectionAlert != nil) {
//            [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:YES];
//            self.noConnectionAlert = nil;
//        }
        
        [self removeLoadingView];
    }
}

/**
 Start the local authentication process
 */
- (void)doAuthentication {
    // Disable heartbeats
    [self disableLocalHeartbeat];
    /***************************************************
     To be certain that we own this bridge we must manually
     push link it. Here we display the view to do this.
     *****************************************************/
    // Create an interface for the pushlinking

    self.pushLinkViewController = [[BridgePushLinkViewController alloc] initWithNibName:@"BridgePushLinkViewController" bundle:[NSBundle mainBundle] hueSDK:UIAppDelegate.phHueSDK delegate:self];
    
    [self.tapBarController presentViewController:self.pushLinkViewController animated:YES completion:^{
                /***************************************************
                 Start the push linking process.
                 *****************************************************/
                [self.pushLinkViewController startPushLinking];
    }];
    
//    [self.navigationController presentViewController:self.pushLinkViewController animated:YES completion:^{
//        /***************************************************
//         Start the push linking process.
//         *****************************************************/
//        
//        // Start pushlinking when the interface is shown
//        [self.pushLinkViewController startPushLinking];
//    }];
}

#pragma mark - Heartbeat control
/**
 Starts the local heartbeat with a 10 second interval
 */
- (void)enableLocalHeartbeat {
    /***************************************************
     The heartbeat processing collects data from the bridge
     so now try to see if we have a bridge already connected
     *****************************************************/
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil) {
        //
        [self showLoadingViewWithText:NSLocalizedString(@"Connecting...", @"Connecting text")];
        
        // Enable heartbeat with interval of 10 seconds
        [self.phHueSDK enableLocalConnection];
    } else {
        // Automaticly start searching for bridges
        [self searchForBridgeLocal];
    }
}

/**
 Stops the local heartbeat
 */
- (void)disableLocalHeartbeat {
    [self.phHueSDK disableLocalConnection];
}


#pragma mark - Bridge searching and selection

/**
 Search for bridges using UPnP and portal discovery, shows results to user or gives error when none found.
 */
- (void)searchForBridgeLocal {
    // Stop heartbeats
    [self disableLocalHeartbeat];
    // Show search screen
   [self showLoadingViewWithText:NSLocalizedString(@"Searching...", @"Searching for bridges text")];
    /***************************************************
     A bridge search is started using UPnP to find local bridges
     *****************************************************/
    // Start search
    self.bridgeSearch = [[PHBridgeSearching alloc] initWithUpnpSearch:YES andPortalSearch:YES andIpAdressSearch:YES];
   
    [self.bridgeSearch startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
        // Done with search, remove loading view
        [self removeLoadingView];

        /***************************************************
         The search is complete, check whether we found a bridge
         *****************************************************/
        
        // Check for results
        if (bridgesFound.count > 0) {
            // Results were found, show options to user (from a user point of view, you should select automatically when there is only one bridge found)
            self.bridgeSelectionViewController = [[BridgeSelectionViewController alloc] initWithNibName:@"BridgeSelectionViewController" bundle:[NSBundle mainBundle] bridges:bridgesFound delegate:self];
            /***************************************************
             Use the list of bridges, present them to the user, so one can be selected.
             *****************************************************/
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.bridgeSelectionViewController];
           
            //navController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            [self.tapBarController presentViewController:navController animated:YES completion:nil];
        }
        else {
            /***************************************************
             No bridge was found was found. Tell the user and offer to retry..
             *****************************************************/
            
            // No bridges were found, show this to the user
            /*
            self.noBridgeFoundAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No bridges", @"No bridge found alert title")
                                                                 message:NSLocalizedString(@"Could not find bridge", @"No bridge found alert message")
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"Retry", @"No bridge found alert retry button"),NSLocalizedString(@"Cancel", @"No bridge found alert cancel button"), nil];
            self.noBridgeFoundAlert.tag = 1;
            [self.noBridgeFoundAlert show];
             */
        }
    }];
}

/**
 Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was successfull
 */
- (void)pushlinkSuccess {
    /***************************************************
     Push linking succeeded we are authenticated against
     the chosen bridge.
     *****************************************************/
    // Remove pushlink view controller
    [self.pushLinkViewController dismissViewControllerAnimated:YES completion:nil];
    self.pushLinkViewController = nil;
    
    // Start local heartbeat
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

- (void)pushlinkFailed:(PHError *)error {
    /*
    // Remove pushlink view controller
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    self.pushLinkViewController = nil;
    
    // Check which error occured
    if (error.code == PUSHLINK_NO_CONNECTION) {
        // No local connection to bridge
        [self noLocalConnection];
        
        // Start local heartbeat (to see when connection comes back)
        [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
    }
    else {
        // Bridge button not pressed in time
        self.authenticationFailedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Authentication failed", @"Authentication failed alert title")
                                                                    message:NSLocalizedString(@"Make sure you press the button within 30 seconds", @"Authentication failed alert message")
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:NSLocalizedString(@"Retry", @"Authentication failed alert retry button"), NSLocalizedString(@"Cancel", @"Authentication failed cancel button"), nil];
        [self.authenticationFailedAlert show];
    }
     */
}

/**
 Delegate method for PHbridgeSelectionViewController which is invoked when a bridge is selected
 */
- (void)bridgeSelectedWithIpAddress:(NSString *)ipAddress andBridgeId:(NSString *)bridgeId {
    /***************************************************
     Removing the selection view controller takes us to
     the 'normal' UI view
     *****************************************************/
    
    // Remove the selection view controller
    self.bridgeSelectionViewController = nil;
    //[self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    // Show a connecting view while we try to connect to the bridge
    [self showLoadingViewWithText:NSLocalizedString(@"Connecting...", @"Connecting text")];
    
    // Set SDK to use bridge and our default username (which should be the same across all apps, so pushlinking is only required once)
    //NSString *username = [PHUtilities whitelistIdentifier];
    
    /***************************************************
     Set the ipaddress and bridge id,
     as the bridge properties that the SDK framework will use
     *****************************************************/
    
    [self.phHueSDK setBridgeToUseWithId:bridgeId ipAddress:ipAddress];
    
    /***************************************************
     Setting the hearbeat running will cause the SDK
     to regularly update the cache with the status of the
     bridge resources
     *****************************************************/
    
    // Start local heartbeat again
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

#pragma mark - Loading view

/**
 Shows an overlay over the whole screen with a black box with spinner and loading text in the middle
 @param text The text to display under the spinner
 */
- (void)showLoadingViewWithText:(NSString *)text {
    // First remove
    [self removeLoadingView];
    
    self.loadingView = [[LoadingViewController alloc] initWithNibName:@"LoadingViewController" bundle:[NSBundle mainBundle]];
   
    //self.loadingView.view.frame = self.tapBarController.view.bounds;
    
    //[self.tapBarController.view addSubview:self.loadingView.view];
    
    [[[[UIApplication sharedApplication] delegate] window] addSubview:self.loadingView.view];
    
    self.loadingView.loadingLabel.text = text;
}

/**
 Removes the full screen loading overlay.
 */
- (void)removeLoadingView {
    if (self.loadingView != nil) {
        [self.loadingView.view removeFromSuperview];
        self.loadingView = nil;
    }
}


@end
