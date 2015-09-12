//
//  BridgePushLinkViewController.m
//  MyHueOnTV
//
//  Created by Jorge Villa on 9/11/15.
//  Copyright © 2015 Jorge Villa. All rights reserved.
//
#import <HueSDK_iOS/HueSDK.h>
#import "BridgePushLinkViewController.h"

@interface BridgePushLinkViewController ()

@end

@implementation BridgePushLinkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil hueSDK:(PHHueSDK *)hueSdk delegate:(id<PHBridgePushLinkViewControllerDelegate>)delegate {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Make it a form on iPad
        //self.modalPresentationStyle = UIModalPresentationFormSheet;
        
        self.phHueSDK = hueSdk;
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/**
 Starts the pushlinking process
 */
- (void)startPushLinking {
    /***************************************************
     Set up the notifications for push linkng
     *****************************************************/
    
    // Register for notifications about pushlinking
    PHNotificationManager *phNotificationMgr = [PHNotificationManager defaultManager];
    
    [phNotificationMgr registerObject:self withSelector:@selector(authenticationSuccess) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION];
    [phNotificationMgr registerObject:self withSelector:@selector(authenticationFailed) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION];
    [phNotificationMgr registerObject:self withSelector:@selector(noLocalConnection) forNotification:PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION];
    [phNotificationMgr registerObject:self withSelector:@selector(noLocalBridge) forNotification:PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION];
    [phNotificationMgr registerObject:self withSelector:@selector(buttonNotPressed:) forNotification:PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION];
    
    // Call to the hue SDK to start pushlinking process
    /***************************************************
     Call the SDK to start Push linking.
     The notifications sent by the SDK will confirm success
     or failure of push linking
     *****************************************************/
    
    [self.phHueSDK startPushlinkAuthentication];
}

/**
 Notification receiver which is called when the pushlinking was successful
 */
- (void)authenticationSuccess {
    /***************************************************
     The notification PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION
     was received. We have confirmed the bridge.
     De-register for notifications and call
     pushLinkSuccess on the delegate
     *****************************************************/
    // Deregister for all notifications
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    
    // Inform delegate
    [self.delegate pushlinkSuccess];
}

/**
 Notification receiver which is called when the pushlinking failed because the time limit was reached
 */
- (void)authenticationFailed {
    // Deregister for all notifications
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    
    // Inform delegate
    [self.delegate pushlinkFailed:[PHError errorWithDomain:SDK_ERROR_DOMAIN
                                                      code:PUSHLINK_TIME_LIMIT_REACHED
                                                  userInfo:[NSDictionary dictionaryWithObject:@"Authentication failed: time limit reached." forKey:NSLocalizedDescriptionKey]]];
}

/**
 Notification receiver which is called when the pushlinking failed because the local connection to the bridge was lost
 */
- (void)noLocalConnection {
    // Deregister for all notifications
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    
    // Inform delegate
    [self.delegate pushlinkFailed:[PHError errorWithDomain:SDK_ERROR_DOMAIN
                                                      code:PUSHLINK_NO_CONNECTION
                                                  userInfo:[NSDictionary dictionaryWithObject:@"Authentication failed: No local connection to bridge." forKey:NSLocalizedDescriptionKey]]];
}

/**
 Notification receiver which is called when the pushlinking failed because we do not know the address of the local bridge
 */
- (void)noLocalBridge {
    // Deregister for all notifications
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    
    // Inform delegate
    [self.delegate pushlinkFailed:[PHError errorWithDomain:SDK_ERROR_DOMAIN code:PUSHLINK_NO_LOCAL_BRIDGE userInfo:[NSDictionary dictionaryWithObject:@"Authentication failed: No local bridge found." forKey:NSLocalizedDescriptionKey]]];
}

/**
 This method is called when the pushlinking is still ongoing but no button was pressed yet.
 @param notification The notification which contains the pushlinking percentage which has passed.
 */
- (void)buttonNotPressed:(NSNotification *)notification {
    // Update status bar with percentage from notification
    NSDictionary *dict = notification.userInfo;
    NSNumber *progressPercentage = [dict objectForKey:@"progressPercentage"];
    
    // Convert percentage to the progressbar scale
    float progressBarValue = [progressPercentage floatValue] / 100.0f;
    self.progressView.progress = progressBarValue;
}

@end
