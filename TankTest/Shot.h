//
//  Shot.h
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKSprite.h"

@class Shot, Tank;

@protocol ShotDelegate <NSObject>

- (void)explode:(Shot*)shot on:(CGPoint)obj;
- (void)shot:(Shot*)shot hitTank:(Tank*)tank;
- (SKSprite*)objectAt:(CGPoint)point;

@end

@interface Shot : SKSprite

@property (assign, nonatomic) CGFloat speed;
@property (strong, nonatomic) NSArray *map;
@property (assign, nonatomic) int mapwidth;
@property (assign, nonatomic) int mapheight;
@property (assign, nonatomic) CGRect bounds;
@property (assign, nonatomic) NSArray *tanks;
@property (assign, nonatomic) Tank *owner;
@property (assign, nonatomic) id<ShotDelegate> delegate;

@end
