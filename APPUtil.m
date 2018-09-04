//
//  APPUtil.m
//  SpeechDemo
//
//  Created by Mine on 2018/9/3.
//  Copyright © 2018年 Mine. All rights reserved.
//

#import "APPUtil.h"
#import "lame.h"

@implementation APPUtil
    
+ (void)lameCafToMp3:(NSString *)cafPath mp3:(NSString *)mp3Path
{
    NSString *cafFilePath = cafPath;//原caf文件位置
    NSString *mp3FilePath = mp3Path;//转化过后的MP3文件位置
    @try {
        int read, write;
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        if(pcm == NULL)
        {
            NSLog(@"file not found");
        }
        else
        {
            fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header,跳过头文件 有的文件录制会有音爆，加上此句话去音爆
            FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            lame_t lame = lame_init();
            lame_set_in_samplerate(lame, 44100);//11025.0
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            do {
                read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                fwrite(mp3_buffer, write, 1, mp3);
            } while (read != 0);
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
            return ;
        }
        return ;
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        return ;
    }
    @finally {
        NSData *data= [NSData dataWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"%@.%@", @"bbb",@"mp3"]]];//此处可以打断点看下data文件的大小，如果太小，很可能是个空文件
        NSLog(@"执行完成");
    }
}

// 删除文件
+ (void)deleteFile:(NSString *)path
{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    
    BOOL isHave=[[NSFileManager defaultManager] fileExistsAtPath:path];
    
    if (!isHave) {
        
        NSLog(@"删除的文件不存在");
        return ;
    }
    else {
        
        BOOL isDele = [fileManager removeItemAtPath:path error:nil];
        if (isDele) {
            NSLog(@"文件删除成功");
        }
        else {
            NSLog(@"文件删除失败");
        }
    }
}
    
+ (NSString *)recorderPath
{
    NSString *rootPath = [self libraryCachePath];
    NSString *path = [rootPath stringByAppendingPathComponent:@"Recorder/"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *error;
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return path;
}

+ (NSString *)speechPath
{
    NSString *rootPath = [self libraryCachePath];
    NSString *path = [rootPath stringByAppendingPathComponent:@"Speech/"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *error;
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return path;
}

+ (NSString *)libraryCachePath
{
    return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Caches"];  // 缓存 数据 地址
}
@end
