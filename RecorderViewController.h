//
//  RecorderViewController.h
//  SpeechDemo
//
//  Created by Mine on 2018/9/3.
//  Copyright © 2018年 Mine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecorderViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *recodeSound;
    
@property (weak, nonatomic) IBOutlet UIButton *playSound;
    
@property (weak, nonatomic) IBOutlet UIButton *speechSound;
    
@property (weak, nonatomic) IBOutlet UILabel *speechContent;
    
@end

