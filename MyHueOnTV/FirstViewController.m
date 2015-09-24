//
//  FirstViewController.m
//  MyHueOnTV
//
//  Created by Jorge Villa on 9/11/15.
//  Copyright © 2015 Jorge Villa. All rights reserved.
//
#import <HueSDK_iOS/HueSDK.h>
#import "FirstViewController.h"
#import "AppDelegate.h"

#define MAX_HUE 65535

@interface FirstViewController ()

@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshingButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.refreshButton.hidden = YES;
}

- (void)setUpNotifications {
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    // Register for the local heartbeat notifications
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalBridge) forNotification:PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)noLocalBridge {
    // Authentication failed because the SDK has not been configured yet to connect to a specific bridge adress. This is a coding error, make sure you have called [PHHueSDK setBridgeToUseWithIpAddress:macAddress:] before starting the pushlink process
    self.refreshButton.hidden = NO;
}

- (void)localConnection{
    [self loadConnectedBridgeValues];
}

- (void)loadConnectedBridgeValues {
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    // Check if we have connected to a bridge before
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil) {
            // Check if we are connected to the bridge right now
            if (UIAppDelegate.phHueSDK.localConnected) {
                [self refreshingButton];
                [self transformRefreshButtonToSwitch];
            } else {
            //self.bridgeLastHeartbeatLabel.text = @"Waiting...";
            //[self.randomLightsButton setEnabled:NO];
        }
    }
}

#pragma mark LIGHT SWITCH

- (void)transformRefreshButtonToSwitch {
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    BOOL lightIsOn = NO;
    
    if (cache.lights.allValues.count == 0) {
        [self refreshingButton];
        
        return;
    }
    
    for (PHLight *light in cache.lights.allValues) {
        NSNumber *lightState = [[light valueForKey:@"lightState"] valueForKey:@"on"];
        
        if ([lightState intValue] == 1) {
            lightIsOn = YES;
            break;
        } else {
            lightIsOn = NO;
        }
    }
    
    if (lightIsOn) {
        [self prepareButtonOff];
    } else {
        [self prepareButtonOn];
    }
}

- (void)createGroupOfLightsKine:(void (^)(NSMutableArray *lights))success {
    PHBridgeSendAPI *bridgeSendAPI = [PHBridgeSendAPI new];
    NSArray *lightIdentifiers = @[@"1", @"2", @"3"];
    
    [bridgeSendAPI createGroupWithName:@"group name" lightIds:lightIdentifiers completionHandler:^(NSString *groupIdentifier, NSArray *errors){
        if (errors.count > 0) {
            // Error handling
        }
        else {
            // Get group object from the cache
            PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
            PHGroup *group = [cache.groups objectForKey:groupIdentifier];
            NSLog(@"desc ---> %@",group.description);
            
            // Other logic
            // ...
        }
    }];
}


//- (void)createGroupOfLights:(void (^)(NSMutableArray *lights))success {
//    if (self.allLights.count == 0) {
//        [self refreshingButton];
//        
//        PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
//        
//        if (cache.lights.allValues.count > 0) {
//            for (PHLight *light in cache.lights.allValues) {
//                self.allLights = [NSMutableArray new];
//                
//                [self.allLights addObject:light];
//            }
//            success(self.allLights);
//        }
//    } else {
//        success(self.allLights);
//    }
//}

- (void)refreshingButton {
    self.refreshButton.hidden = NO;
    
    [self.refreshButton setTitle:@"..." forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    [self.refreshButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)prepareButtonOff {
    [self.refreshButton setTitle:@"OFF" forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    [self.refreshButton addTarget:self action:@selector(turnOffLights:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

- (void)prepareButtonOn {
    [self.refreshButton setTitle:@"ON" forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    [self.refreshButton addTarget:self action:@selector(turnOnLights:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

/*
 "on":false,
 "bri":1,
 "hue":65535,
 "sat":0,
 "effect":"none"
*/

- (void)turnOnLights:(id)selector {
    PHBridgeSendAPI *bridgeSendAPI = [PHBridgeSendAPI new];
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    
    for (PHLight *light in cache.lights.allValues) {
        PHLightState *lightState = [PHLightState new];
        lightState.on = @YES;
        lightState.brightness = [NSNumber numberWithInt:254];
        lightState.hue = @65535;
        lightState.saturation = [NSNumber numberWithInt:0];
        
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                NSLog(@"Response: %@",message);
            } else {
                [self prepareButtonOff];
            }
        }];
    }
}

//OFF
/*
 "on":false,
 "bri":1,
 "hue":65535,
 "sat":0,
 "effect":"none"
 */
- (void)turnOffLights:(id)selector {
    PHBridgeSendAPI *bridgeSendAPI = [PHBridgeSendAPI new];
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    
    for (PHLight *light in cache.lights.allValues) {
        PHLightState *lightState = [PHLightState new];
        lightState.on = @NO;
        lightState.brightness = [NSNumber numberWithInt:1];
        lightState.hue = @65535;
        lightState.saturation = [NSNumber numberWithInt:0];
        
        
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                NSLog(@"Response: %@",message);
            } else {
                [self prepareButtonOn];
            }
        }];
    }
}

- (void)noLocalConnection {
    [self refreshButtonWithConnectionIssue];
}

- (void)refreshButtonWithConnectionIssue {
    self.refreshButton.hidden = NO;
    
    [self.refreshButton setTitle:@"NO CONNECTION" forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    [self.refreshButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (IBAction)didTapOnRefresh:(id)sender {
    [UIAppDelegate searchForBridgeLocal];
}

@end
