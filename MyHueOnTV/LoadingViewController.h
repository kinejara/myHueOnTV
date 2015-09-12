//
//  LoadingViewController.h
//  MyHueOnTV
//
//  Created by Jorge Villa on 9/11/15.
//  Copyright © 2015 Jorge Villa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingViewController : UIViewController

/**
 The label shown below the loading spinner
 */
@property (nonatomic,weak) IBOutlet UILabel *loadingLabel;
@property (nonatomic,weak) IBOutlet UIView *translucenLayer;


@end
