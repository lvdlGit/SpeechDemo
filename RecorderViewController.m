//
//  ViewController.m
//  SpeechDemo
//
//  Created by Mine on 2018/9/3.
//  Copyright © 2018年 Mine. All rights reserved.
//

#import "RecorderViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>
#import "APPUtil.h"


@interface RecorderViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
    
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) NSString *filePath;

@end

@implementation RecorderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"录音";
    
    _filePath = [NSString stringWithFormat:@"%@%@", [APPUtil recorderPath], @"record.caf"];

    _session = [AVAudioSession sharedInstance];
    NSError *categoryError = nil;
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:&categoryError];
    if (_session) {
        [_session setActive:YES error:nil];
    }
    else {
        NSLog(@"Error creating session: %@",[categoryError description]);
    }
    
    // 请求语音识别权限
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        NSLog(@"status %@", status == SFSpeechRecognizerAuthorizationStatusAuthorized ? @"语音识别权限授权成功" : @"语音识别权限授权失败");
    }];
    
    [_recodeSound setTitle:@"开始录音" forState:UIControlStateNormal];
    [_recodeSound setTitle:@"开始录音" forState:UIControlStateHighlighted];
    [_recodeSound setTitle:@"停止录音" forState:UIControlStateSelected];
    
    [_playSound setTitle:@"播放录音" forState:UIControlStateNormal];
    [_playSound setTitle:@"播放录音" forState:UIControlStateHighlighted];
    [_playSound setTitle:@"停止播放" forState:UIControlStateSelected];
}
    
- (void)createAudioRecorder
{
    // 实例化录音器对象
    NSError *errorRecord = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_filePath] settings:[self getAudioSetting] error:&errorRecord];
    _recorder.delegate = self;
    _recorder.meteringEnabled = YES; //如果要监控声波则必须设置为YES
    
    // 准备录音
    [_recorder prepareToRecord];
}
    
- (void)createAudioPlayer
{
    // 实例化播放器对象
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:_filePath] error:nil];
    _player.delegate = self;
}
    
- (void)recorderSoundStart:(NSString *)path
{
    // 停止播放
    [self stopPlayRecorderSound];
    
    // 停止之前的录音
    if ([_recorder isRecording]) {
        [_recorder stop];
    }
    
    // 删除旧的录音文件
    [APPUtil deleteFile:path];
    
    if (!_recorder) {
        
        // 实例化录音对象
        [self createAudioRecorder];
    }
    
    if (![_recorder isRecording]){
        
        [_recorder record];
        
        // 设定 录制 最长时间 60s
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self recorderSoundEnd];
        });
    }
}

- (void)recorderSoundEnd
{
    // 停止录音
    if ([_recorder isRecording]) {
        [_recorder stop];
//        [_recorder pause]; // 暂停录制
    }
    
    // 更新UI按钮
    _recodeSound.selected = NO;
}

- (void)recorderSoundPlay:(NSString *)path
{
    // 先停止录音
    if (_recorder) {
        
        [_recorder stop];
    }
    
    if (!_player) {
        // 创建播放器
        [self createAudioPlayer];
    }
    
    [_session setCategory:AVAudioSessionCategoryPlayback error:nil];
    // 播放
    [_player play];
}

- (void)stopPlayRecorderSound
{
    if ([_player isPlaying]) {
        [_player stop];
    }
    
    // 更新UI播放按钮
    _playSound.selected = NO;
}

- (void)speechSoundRecord:(NSString *)path
{
    // 设置语言中文
    NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    SFSpeechRecognizer *localRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    if (!url) return;

    SFSpeechURLRecognitionRequest *res =[[SFSpeechURLRecognitionRequest alloc] initWithURL:url];

    __weak typeof(self) weakSelf = self;
    
    [localRecognizer recognitionTaskWithRequest:res resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {

         __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
            NSLog(@"语音识别解析失败,%@",error);
        }
        else {
            // 显示 识别的内容
            NSString *text = result.bestTranscription.formattedString;

            strongSelf.speechContent.text = text;
        }
    }];
}

- (NSDictionary *)getAudioSetting
{
    //LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
    //通道数 编码时每个通道的比特率
    [recordSettings setValue:[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    
    //录音格式 无法使用
    //    [recordSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    
    //采样率
    [recordSettings setValue:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//44100.0
    //线性采样位数
    [recordSettings setValue:[NSNumber numberWithInt:32] forKey: AVLinearPCMBitDepthKey];
    
    // 编码时的比特率，是每秒传送的比特(bit)数单位为bps(Bit Per Second)，比特率越高传送数据速度越快值是一个整数
    [recordSettings setValue:[NSNumber numberWithInt:128000] forKey:AVEncoderBitRateKey];
    
    return recordSettings;
}

#pragma mark - button click
    
- (IBAction)startRecoderSound:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        
        [self recorderSoundStart:_filePath];
    }
    else {
        [self recorderSoundEnd];
    }
}
    
- (IBAction)playSound:(UIButton *)sender
{
    // 播放的录音文件是否存在
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:_filePath]){
     
        NSLog(@"音频文件不存在");
        return ;
    }
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self recorderSoundPlay:_filePath];
    }
    else {
        [self stopPlayRecorderSound];
    }
}
    
- (IBAction)speechSound:(UIButton *)sender
{
    // 识别的录音文件是否存在
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:_filePath]){
        
        NSLog(@"音频文件不存在");
        return ;
    }
    
    _speechContent.text = @"";
    
    //
    //转化过后的MP3文件位置
//    NSString *mp3Path = [NSString stringWithFormat:@"%@/%@", [APPUtil speechPath], @"lame.mp3"];
//    [APPUtil lameCafToMp3:_filePath mp3:mp3Path];
//    [self speechSoundRecord:mp3Path]; // 语音识别失败
    
    // 不转成mp3也可以 识别成功
    [self speechSoundRecord:_filePath]; // 能识别成功
}
    
#pragma mark - AVAudioRecorderDelegate 录音机代理方法

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"录音完成!");
    
    [self recorderSoundEnd];
}
  
#pragma mark - AVAudioPlayerDelegate 播放器代理方法
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"录音播放完了");
    [self stopPlayRecorderSound];
}
    

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
