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
    [self showRefreshButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.refreshButton.hidden = YES;
}

- (void)showRefreshButton {
    if (!UIAppDelegate.phHueSDK.localConnected) {
        if (!UIAppDelegate.loadingView) {
            self.refreshButton.hidden = NO;
        }
    }
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
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil){
            // Check if we are connected to the bridge right now
            if (UIAppDelegate.phHueSDK.localConnected) {
                [self transformRefreshButtonToSwitch];
            } else {
            //self.bridgeLastHeartbeatLabel.text = @"Waiting...";
            //[self.randomLightsButton setEnabled:NO];
        }
    }
}

#pragma mark LIGHT SWITCH

- (void)transformRefreshButtonToSwitch {
    self.refreshButton.hidden = NO;
    [self.refreshButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    if ([self ligthsState]) {
        [self prepareButtonOff];
    } else {
        [self prepareButtonOn];
    }
}

- (void)prepareButtonOff {
    [self.refreshButton setTitle:@"OFF" forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    [self.refreshButton addTarget:self action:@selector(turnOffLights:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

- (void)prepareButtonOn {
    [self.refreshButton setTitle:@"ON" forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    [self.refreshButton addTarget:self action:@selector(turnOnLights:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

- (void)turnOnLights:(id)selector {
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [PHBridgeSendAPI new];
    
    for (PHLight *light in cache.lights.allValues) {
        PHLightState *lightState = [PHLightState new];
        lightState.on = @YES;
        [lightState setOnBool:YES];
        // Send lightstate to light
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                NSLog(@"Response: %@",message);
            } else {
                [self prepareButtonOff];
                
                lightState.brightness = [NSNumber numberWithInt:254];
                lightState.saturation = [NSNumber numberWithInt:254];
                
                [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
                    if (errors != nil) {
                        NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                        NSLog(@"Response: %@",message);
                    }
                }];
            }
        }];
    }
}

- (void)turnOffLights:(id)selector {
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [PHBridgeSendAPI new];
    
    for (PHLight *light in cache.lights.allValues) {
        PHLightState *lightState = [PHLightState new];
        lightState.on = @NO;
        [lightState setOnBool:NO];
        
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                NSLog(@"Response: %@",message);
            } else {
                [self prepareButtonOn];
                
                lightState.brightness = [NSNumber numberWithInt:0];
                lightState.saturation = [NSNumber numberWithInt:0];
                
                [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
                    if (errors != nil) {
                        NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                        NSLog(@"Response: %@",message);
                    }
                }];
            }
        }];
    }
    
    [self transformRefreshButtonToSwitch];
}

- (BOOL)ligthsState {
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    
    for (PHLight *light in cache.lights.allValues) {
        NSNumber *lightState = [[light valueForKey:@"lightState"] valueForKey:@"on"];
        
        if ([lightState intValue] == 1) {
            return YES;
        }
    }
    
    return NO;
}

- (void)noLocalConnection {
//    self.bridgeLastHeartbeatLabel.text = @"Not connected";
//    [self.bridgeLastHeartbeatLabel setEnabled:NO];
//    self.bridgeIpLabel.text = @"Not connected";
//    [self.bridgeIpLabel setEnabled:NO];
//    self.bridgeIdLabel.text = @"Not connected";
//    [self.bridgeIdLabel setEnabled:NO];
//    
//    [self.randomLightsButton setEnabled:NO];
}

- (IBAction)didTapOnRefresh:(id)sender {
    [UIAppDelegate searchForBridgeLocal];
}

@end
