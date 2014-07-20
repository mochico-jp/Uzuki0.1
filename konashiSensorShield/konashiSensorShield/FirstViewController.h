//
//  FirstViewController.h
//  konashiSensorShield
//
//  Created by Kenji Ohno on 2014/03/28.
//  Copyright (c) 2014年 Macnica. All rights reserved.
//

#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

@interface FirstViewController : UIViewController
{
    CFURLRef soundURL;
    SystemSoundID soundID;
}

@property (weak, nonatomic) IBOutlet UILabel *dciTitle;
@property (weak, nonatomic) IBOutlet UILabel *tempUnit;
@property (weak, nonatomic) IBOutlet UILabel *rhUnit;
@property (weak, nonatomic) IBOutlet UIImageView *weatherImage;
@property (weak, nonatomic) IBOutlet UILabel *ambientLight;
@property (weak, nonatomic) IBOutlet UIButton *stopAlarm;


@property (weak, nonatomic) IBOutlet UILabel *rhLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempLabel;
@property (weak, nonatomic) IBOutlet UILabel *dciLabel;
@property (weak, nonatomic) IBOutlet UIButton *devicePairingButton;

- (IBAction)tapDevicePairing:(id)sender;
- (IBAction)stopAlarm:(id)sender;

@end
