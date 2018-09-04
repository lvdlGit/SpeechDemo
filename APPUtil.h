//
//  APPUtil.h
//  SpeechDemo
//
//  Created by Mine on 2018/9/3.
//  Copyright © 2018年 Mine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPUtil : NSObject

/**
 * caf音频文件转化成mp3文件
 */
+ (void)lameCafToMp3:(NSString *)cafPath mp3:(NSString *)mp3Path;
    
/**
 * 删除文件
 */
+ (void)deleteFile:(NSString *)path;


+ (NSString *)recorderPath;
    
+ (NSString *)speechPath;

@end
