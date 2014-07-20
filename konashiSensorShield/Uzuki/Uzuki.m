//
//  Uzuki.m
//  konashiSensorShield
//
//  Created by mochico on 7/19/14.
//  Copyright (c) 2014 Macnica. All rights reserved.
//

#import "Uzuki.h"

@implementation Uzuki

unsigned char *data;

+ (void)initialize
{
    [self initializeProximityLuminescenseUVSensor];
}


+ (void)initializeProximityLuminescenseUVSensor
{

    //***********************************************************
    // Si114x Ambient Light / UV Index / Proximity Sensor Setting
    //***********************************************************
    //initialize: wait for 25ms or more.
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    
    // HW_KEYレジスタに0x17をWR　→オペレーション開始
    data[0] = REG_HW_KEY;
    data[1] = REG_HW_KEY_VALUE;
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    // REG_COEF0-3レジスタにSiLabs指定の補正値をWR
    data[0] = REG_COEF0;
    data[1] = REG_COEF0_VALUE;
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    data[0] = REG_COEF1;
    data[1] = REG_COEF1_VALUE;
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    data[0] = REG_COEF2;
    data[1] = REG_COEF2_VALUE;
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    data[0] = REG_COEF3;
    data[1] = REG_COEF3_VALUE;
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL_LONG];
    
    //*****************************************************
    // Si7013 Temperature / Related Humidity Sensor Setting
    //*****************************************************
    
    data[0] = REG_PARAM_WR; //パラメータレジスタに書き込む値をセットするレジスタ
    data[1] = EN_UV | EN_ALS_IR | EN_ALS_VIS; //パラメータレジスタに書き込む値
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    data[0] = REG_COMMAND;
    data[1] = 0xA0 | PARAM_CH_LIST; // 0xA0 is the PARAM_SET cmd.
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL_LONG];
    
    
}


+ (void)checkRelativeHumidity
{
    // Sequence to Start a Relative Humidity Conversion
    data[0] = 0xE5;
    [self _writeAndReadRequestToKonashi:1 data:data address:HUMID_TEMP_SENSOR_ADDRESS readRequest:3];
    
}

+ (void)checkTemperature
{
    // Sequence to Start a Temperature Conversion
    data[0] = 0xE0;
    [self _writeAndReadRequestToKonashi:1 data:data address:HUMID_TEMP_SENSOR_ADDRESS readRequest:3];
}

+ (void)checkAmbientLight
{
    // Sequence to Start a Ambient Light Conversion
    
    
    data[0] = REG_COMMAND;
    data[1] = ALS_FORCE; // Enter ALS Force Mode.
    //data[1] = ALS_AUTO;   // Enter ALS Autonomous Mode.
    [self _writeToKonashi:2 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS];
    
    //data[0] = 0x00; // Part ID : 0x45 for Si1145
    //data[0] = REG_UVI_DATA0;
    data[0] = REG_ALS_VIS_DATA0;
    [self _writeAndReadRequestToKonashi:1 data:data address:PROX_LIGHT_UV_SENSOR_ADDRESS readRequest:2];
    
}

+ (void)checkAccelerometer
{
    // Sequence to Start a Accerelometer Conversion
    
    data[0] = 0x31; // DATA FORMAT REGISTER
    data[1] = 0x0B; // Set Full Resolution, +/- 16g
    [self _writeToKonashi:2 data:data address:ACC_SENSOR_ADDRESS];
    
    data[0] = 0x2D; // POWER CONTROL REGISTER
    data[1] = 0x08; // Set to Measure Mode
    [self _writeToKonashi:2 data:data address:ACC_SENSOR_ADDRESS];
    
    data[0] = 0x24; // THRESHOLD ACTIVE : 6.25mg/LSB
    data[1] = 0x20; // 2.0g
    //data[1] = 0x10;   // 1.0g
    //data[1] = 0x08;   // 0.5g
    [self _writeToKonashi:2 data:data address:ACC_SENSOR_ADDRESS];
    
    data[0] = 0x27; // ACTIVE/INACTIVE CONTROL REGISTER
    data[1] = 0xF0; // D7 : 1 : Act AC Coupling
    // D6 : 1 : Act_X Enable
    // D5 : 1 : Act_Y Enable
    // D4 : 1 : Act_Z Enable
    // D3 : 0 : Inact DC Coupling
    // D2 : 0 : Inact_X Disable
    // D1 : 0 : Inact_Y Disable
    // D0 : 0 : Inact_Z Disable
    [self _writeToKonashi:2 data:data address:ACC_SENSOR_ADDRESS];
    
    data[0] = 0x2E; // Int Enable
    data[1] = 0x10; // Enable only Activity
    [self _writeToKonashi:2 data:data address:ACC_SENSOR_ADDRESS];
    
    data[0] = 0x30; // Int Source Register
    //data[0] = 0x32; // data_x lo
    [self _writeAndReadRequestToKonashi:1 data:data address:ACC_SENSOR_ADDRESS readRequest:1];
    
}

+ (double)readRelativeHumidity
{
    [self _readFromKonashi:3];
    
    //NSLog(@"RH:%X,%X", data[0], data[1]);
    
    return (double) ((unsigned short)(data[0] << 8 ^ data[1])) * 125.0 / 65536.0 - 6.0;
    
}


+ (double)readTemperature
{
    [self _readFromKonashi:3];
    
    //NSLog(@"Temp:%X,%X", data[0], data[1]);
    
    return (double) ((unsigned short)(data[0] << 8 ^ data[1])) * 175.72 / 65536.0 - 46.85;
    
}

+ (int)readAmbientLight
{
    [self _readFromKonashi:2];
    
    //NSLog(@"UVI_HL:%X,%X", data[1], data[0]);
    
    return (int) ( (double) ((unsigned short)(data[1] << 8 | data[0])) / 100.0);
    
}


+ (unsigned char *)readAccelerometer
{
    [self _readFromKonashi:1];
    
    //NSLog(@"SHOCKED:%X", data[0]);
    
    return data;
}

#pragma mark -
#pragma mark Utility
+ (int)calculateDiscomfortIndex:(double)temperature relativeHumidity:(double)relativeHumidity
{
    
    // 0.81T+0.01RH(0.99T-14.3)+46.3
    return 0.81 * temperature + 0.01 * relativeHumidity * ( 0.99 * temperature - 14.3 ) + 46.3;

}

#pragma mark -
#pragma mark Private (i2c)
+ (void)_writeToKonashi:(int)length data:(unsigned char*)data address:(unsigned char)address
{
    [Konashi i2cStartCondition];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    [Konashi i2cWrite:length data:data address:address];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    [Konashi i2cStopCondition];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    
}
+ (void)_writeAndReadRequestToKonashi:(int)length data:(unsigned char*)data address:(unsigned char)address readRequest:(int)readLength

{
    [Konashi i2cStartCondition];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    [Konashi i2cWrite:length data:data address:address];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    [Konashi i2cRestartCondition];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    [Konashi i2cReadRequest:readLength address:address];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL_LONG];
    
}

+ (void)_readFromKonashi:(int)length
{
    
    [Konashi i2cRead:3 data:data];
    [NSThread sleepForTimeInterval:I2C_WAIT_INTERVAL];
    [Konashi i2cStopCondition];
    
}




@end
