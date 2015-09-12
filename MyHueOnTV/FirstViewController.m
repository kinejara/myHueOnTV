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

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    // Register for the local heartbeat notifications
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)localConnection{
    [self loadConnectedBridgeValues];
}

- (void)loadConnectedBridgeValues{
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    
    // Check if we have connected to a bridge before
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil){
        
        // Set the ip address of the bridge
        //self.bridgeIpLabel.text = cache.bridgeConfiguration.ipaddress;
        
        // Set the identifier of the bridge
        //self.bridgeIdLabel.text = cache.bridgeConfiguration.bridgeId;
        
        // Check if we are connected to the bridge right now
        if (UIAppDelegate.phHueSDK.localConnected) {
            
            // Show current time as last successful heartbeat time when we are connected to a bridge
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            
            //self.bridgeLastHeartbeatLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
            
            //[self.randomLightsButton setEnabled:YES];
        } else {
            //self.bridgeLastHeartbeatLabel.text = @"Waiting...";
            //[self.randomLightsButton setEnabled:NO];
        }
    }
}

- (void)noLocalConnection{
//    self.bridgeLastHeartbeatLabel.text = @"Not connected";
//    [self.bridgeLastHeartbeatLabel setEnabled:NO];
//    self.bridgeIpLabel.text = @"Not connected";
//    [self.bridgeIpLabel setEnabled:NO];
//    self.bridgeIdLabel.text = @"Not connected";
//    [self.bridgeIdLabel setEnabled:NO];
//    
//    [self.randomLightsButton setEnabled:NO];
}

@end
