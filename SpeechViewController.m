//
//  SpeechViewController.m
//  SpeechDemo
//
//  Created by Mine on 2018/9/4.
//  Copyright © 2018年 Mine. All rights reserved.
//

#import "SpeechViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

@interface SpeechViewController ()
    
@property (nonatomic, strong) AVAudioSession *session;

@property (nonatomic, strong) AVAudioEngine *audioEngine;
    
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;

@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest;

@end

@implementation SpeechViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"语音识别";
    
    
    // 请求语音识别权限
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        NSLog(@"status %@", status == SFSpeechRecognizerAuthorizationStatusAuthorized ? @"语音识别权限授权成功" : @"语音识别权限授权失败");
    }];
    
    _session = [AVAudioSession sharedInstance];
    // 3各参数分别是 设置录音, 并且减少系统提供信号对应用程序输入和/或输出音频信号的影响,
    [_session setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [_session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    // 初始化多媒体引擎
    [self createAudioEngine];
}
    
- (void)createAudioEngine
{
    if (!_speechRecognizer) {
        // 设置语言
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-CN"];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    }
    // 初始化引擎
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
}
    
//  创建语音识别请求
- (void)createSpeechRequest
{
    if (_speechRequest) {
        [_speechRequest endAudio];
        _speechRequest = nil;
    }
    
    _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    _speechRequest.shouldReportPartialResults = YES; // 实时翻译
    
    __weak typeof(self) weakSelf = self;
    
    // 建立语音识别任务, 并启动.  block内为语音识别结果回调
    [_speechRecognizer recognitionTaskWithRequest:_speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        
        NSString *text = result.bestTranscription.formattedString;
        
         // 语音识别结果回调
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error) {
            NSLog(@"语音识别解析失败,%@",error);
        }
        else {
            // 识别的内容
            NSString *text = result.bestTranscription.formattedString;
            
            // 实时打印说话的内容
            NSLog(@"is final: %d  result: %@", result.isFinal, result.bestTranscription.formattedString);
            
            if (result.isFinal) { // 结束时 显示内容
                
                // 显示说话的内容
                strongSelf.content.text = text;
                
                // 多次说话的内容拼接到一起显示
//                strongSelf.content.text = [NSString stringWithFormat:@"%@%@", strongSelf.content.text, text];
            }
        }
    }];
}
    
- (void)releaseEngine
{
    // 销毁tap
    [[_audioEngine inputNode] removeTapOnBus:0];
    
    [_audioEngine stop];
    
    [_speechRequest endAudio];
    _speechRequest = nil;
}
    
    
- (IBAction)stardRecorder:(UIButton *)sender
{
    // 开始录音前清空显示的内容, 如果需要拼接多次录音的内容,不要清空,
    _content.text = @"";
    
    // 创建新的语音识别请求
    [self createSpeechRequest];
    
    __weak typeof(self) weakSelf = self;
    
    // 录音格式配置 -- 监听输出流 并拼接流文件
    AVAudioFormat *recordingFormat = [[_audioEngine inputNode] outputFormatForBus:0];
    // 创建一个Tap,(创建前要先删除旧的)
    // 文档注释: Create a "tap" to record/monitor/observe the output of the node.
    [[_audioEngine inputNode] installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
     
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // 拼接流文件
        [strongSelf.speechRequest appendAudioPCMBuffer:buffer];
    }];
    
    // 准备并启动引擎
    [_audioEngine prepare];
    
    NSError *error = nil;
    // 启动引擎
    [_audioEngine startAndReturnError:&error];
    
    [sender setTitle:@"语音识别中..." forState:UIControlStateNormal];
}
    
- (IBAction)recorderComplete:(UIButton *)sender
{
    // 重置引擎
    [self releaseEngine];
    
    [sender setTitle:@"按住说话" forState:UIControlStateNormal];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
