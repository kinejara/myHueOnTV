//
//  BridgeSelectionViewController.h
//  MyHueOnTV
//
//  Created by Jorge Villa on 9/11/15.
//  Copyright © 2015 Jorge Villa. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PHBridgeSelectionViewControllerDelegate <NSObject>

/**
 Informs the delegate which bridge was selected
 @param ipAddress the ip address of the selected bridge
 @param macAddress the mac address of the selected bridge
 */
- (void)bridgeSelectedWithIpAddress:(NSString *)ipAddress andBridgeId:(NSString *)bridgeId;

@end

/**
 This is the bridge selection sdk wizard. You can plug this viewcontroller into your application
 to allow selection of the bridge to use in your app. You should change this class
 to include memory management if you are not using ARC.
 */
@interface BridgeSelectionViewController : UITableViewController

/**
 The delegate object
 */
@property (nonatomic, unsafe_unretained) id<PHBridgeSelectionViewControllerDelegate> delegate;

/**
 The bridges shown in the list
 */
@property (nonatomic, strong) NSDictionary *bridgesFound;

/**
 Creates a new instance of this bridge selection view controller.
 @param bridges the bridges to show in the list
 @param delegate the delegate to inform when a bridge is selected
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil bridges:(NSDictionary *)bridges delegate:(id<PHBridgeSelectionViewControllerDelegate>)delegate;


@end
