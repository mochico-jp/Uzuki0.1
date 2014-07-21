//
//  FirstViewController.m
//  konashiSensorShield
//
//  Created by Kenji Ohno on 2014/03/28.
//  Copyright (c) 2014年 Macnica. All rights reserved.
//

#import "FirstViewController.h"
#import "Konashi.h"
#import "Uzuki.h"


@interface FirstViewController ()

@end

@implementation FirstViewController

NSTimer *checkSensorTimer;
int     count=0;

double rh;
double temp;
double dcindex;
int uvi;
unsigned char *acc;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _stopAlarm.hidden = true;
    [Konashi initialize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - Konashi-iPhone Pairing

- (IBAction)tapDevicePairing:(id)sender
{
    if(![Konashi isConnected])
    {
        [Konashi addObserver:self selector:@selector(konashiNotFound) name:KONASHI_EVENT_KONASHI_NOT_FOUND];
        [Konashi addObserver:self selector:@selector(konashiIsReady) name:KONASHI_EVENT_READY];
        [Konashi addObserver:self selector:@selector(konashiFindCanceled) name:KONASHI_EVENT_CANCEL_KONASHI_FIND];
        [Konashi find];
    }
    else
    {
        [Konashi addObserver:self selector:@selector(konashiIsDisconnected) name:KONASHI_EVENT_DISCONNECTED];
        [Konashi disconnect];
        //_silabsLogo.hidden = NO;
    }
}

- (IBAction)stopAlarm:(id)sender {
    _stopAlarm.hidden = true;
    _weatherImage.hidden = false;
    AudioServicesDisposeSystemSoundID(soundID);
}

- (void)konashiNotFound
{
    [Konashi removeObserver:self];
}

- (void)konashiFindCanceled
{
    [Konashi removeObserver:self];
}

- (void)konashiIsDisconnected
{
    [Konashi removeObserver:self];
    
    [_devicePairingButton setTitle:@"Connect" forState:UIControlStateNormal];
    //[[_devicePairingButton layer] setBackgroundColor:[[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] CGColor]];
    
    [self stopCheckSensor];
}

- (void)konashiIsReady
{
    [Konashi removeObserver:self];
    
    [_devicePairingButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    
    //Konash I/O setting
    //[Konashi pinModeAll:0b00001110];
    [Konashi i2cMode:KONASHI_I2C_ENABLE];
    
    //flash device's LED
    [Konashi digitalWrite:PIO0 value:HIGH];
    [NSThread sleepForTimeInterval:0.2];
    [Konashi digitalWrite:PIO0 value:LOW];
    [Konashi digitalWrite:PIO1 value:HIGH];
    [NSThread sleepForTimeInterval:0.2];
    [Konashi digitalWrite:PIO1 value:LOW];
    [Konashi digitalWrite:PIO2 value:HIGH];
    [NSThread sleepForTimeInterval:0.2];
    [Konashi digitalWrite:PIO2 value:LOW];
    
    [self startCheckSensor];
}

#pragma mark - Konashi Input Control

- (void)startCheckSensor
{
    
    NSLog(@"Start check sensor.");
    
    
    [Uzuki initialize];
    
    
    
    //initialize
    //Sensor Event Handler
    [Konashi addObserver:self selector:@selector(readSensor) name:KONASHI_EVENT_I2C_READ_COMPLETE];
    
    checkSensorTimer = [NSTimer scheduledTimerWithTimeInterval:CHECK_SENSOR_INTERVAL
                                                        target:self
                                                      selector:@selector(checkSensor:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopCheckSensor
{
    [Konashi removeObserver:self];
    if([checkSensorTimer isValid]) [checkSensorTimer invalidate];
    //[self resetParameterDisplay];
    //[self hideParameterDisplay];
}

//TODO: to check the Relative Humidity Sensor and the Temperature Sensor on the I2C bus.
- (void)checkSensor:(NSTimer *)timer
{
    switch (count){
            
        case 0:
            [Uzuki checkRelativeHumidity];
            break;
            
        case 1:
            [Uzuki checkTemperature];
            break;
            
        case 2:
            [Uzuki checkAmbientLight];
            break;
            
        case 3:
            [Uzuki checkAccelerometer];
            break;
    }
}

- (void)readSensor // Read RH & Temperature
{
    switch (count){
        case 0:
            
            rh = [Uzuki readRelativeHumidity];
            
            _rhLabel.text = [NSString stringWithFormat:@"%.1f", rh];
            
            NSLog(@"RH: %f", rh);
            
            //_silabsLogo.hidden = NO;
            _rhLabel.hidden = NO;
            _rhUnit.hidden = NO;
            
            count++;
            break;
            
        case 1:
            
            temp = [Uzuki readTemperature];
            
            _tempUnit.hidden = NO;
            _tempLabel.text = [NSString stringWithFormat:@"%.1f", temp];
            
            NSLog(@"Temp:%f", temp);
            
            //_silabsLogo.hidden = YES;
            _tempLabel.hidden = NO;
            
            // 不快指数(Discomfort Index)の計算
            int dcindex = [Uzuki calculateDiscomfortIndex:temp relativeHumidity:rh];
            
            _dciLabel.text = [NSString stringWithFormat:@"%d", dcindex];
            
            //NSLog(@"DCI:%d", dcindex);
            
            _dciTitle.hidden = NO;
            
            if (dcindex<55){ // 寒い
                _dciLabel.textColor = [UIColor cyanColor];
                _dciTitle.textColor = [UIColor cyanColor];
            }
            else if(dcindex>=55 && dcindex<60){ // 肌寒い
                _dciLabel.textColor = [UIColor blueColor];
                _dciTitle.textColor = [UIColor blueColor];
            }
            else if(dcindex>=60 && dcindex<65) { // 何も感じない
                _dciLabel.textColor = [UIColor greenColor];
                _dciTitle.textColor = [UIColor greenColor];
            }
            else if (dcindex>=65 && dcindex<70) { // 快い
                _dciLabel.textColor = [UIColor greenColor];
                _dciTitle.textColor = [UIColor greenColor];
            }
            else if (dcindex>=70 && dcindex<75) { // 暑くない
                _dciLabel.textColor = [UIColor yellowColor];
                _dciTitle.textColor = [UIColor yellowColor];
            }
            else if (dcindex>=75 && dcindex<80) { // やや暑い
                _dciLabel.textColor = [UIColor orangeColor];
                _dciTitle.textColor = [UIColor orangeColor];
            }
            else if (dcindex>=80 && dcindex<85) { // 暑くて汗がでる
                _dciLabel.textColor = [UIColor redColor];
                _dciTitle.textColor = [UIColor redColor];
            }
            else{ // 暑くてたまらない
                _dciLabel.textColor = [UIColor purpleColor];
                _dciTitle.textColor = [UIColor purpleColor];
            }
            
            count++;
            break;
            
        case 2:
            
            uvi = [Uzuki readAmbientLight];
            
            _ambientLight.text = [NSString stringWithFormat:@"%d", uvi];
            
            NSLog(@"UVI: %d", uvi);
            //NSLog(@" ");
            
            //_silabsLogo.hidden = NO;
            _ambientLight.hidden = NO;
            
            
            if (uvi<4){ // 曇り
                NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"weather_ca_005" ofType:@"png"];
                _weatherImage.image = [UIImage imageWithContentsOfFile:imagePath];
            }
            else if(uvi>=4 && uvi<10){ // 曇り・晴れ
                NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"weather_ca_007" ofType:@"png"];
                _weatherImage.image = [UIImage imageWithContentsOfFile:imagePath];
            }
            else if(uvi>=10 && uvi<30) { // 晴れ
                NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"weather_ca_001" ofType:@"png"];
                _weatherImage.image = [UIImage imageWithContentsOfFile:imagePath];
            }
            else{ // 快晴
                NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"weather_ca_003" ofType:@"png"];
                _weatherImage.image = [UIImage imageWithContentsOfFile:imagePath];
            }
            
            count++;
            break;
            
        case 3:
            
            acc = [Uzuki readAccelerometer];
            //FIXME: magic number
            if (acc[0]== 0x93){
                
                _stopAlarm.hidden = false;
                _weatherImage.hidden = true;
                
                CFBundleRef mainBundle;
                mainBundle = CFBundleGetMainBundle();
                soundURL = CFBundleCopyResourceURL(mainBundle, CFSTR("Fire_Alarm"),CFSTR("mp3"),NULL);
                AudioServicesCreateSystemSoundID(soundURL, &soundID);
                CFRelease(soundURL);
                AudioServicesPlaySystemSound(soundID);
                
            }
            
            
            
            count=0;
            break;
    }
}
@end
