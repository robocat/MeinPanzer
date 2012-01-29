//
//  mainViewController.h
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shot.h"
#import "SKSprite.h"

@interface mainViewController : UIViewController <ShotDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

- (SKSprite*)objectAt:(CGPoint)point;

@end
