//
//  Tank.h
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKSprite.h"
#import "mainViewController.h"


typedef struct {
	CGPoint position;
	CGFloat rotation;
	CGFloat speed;
} TankState;


@class Tank;

@protocol TankDelegate <NSObject>

- (void)tankMoved:(Tank*)tank;

@end

@interface Tank : SKSprite

@property (assign, nonatomic) CGFloat speed;
@property (strong, nonatomic) NSArray *map;
@property (assign, nonatomic) int mapwidth;
@property (assign, nonatomic) int mapheight;
@property (assign, nonatomic) CGRect bounds;
@property (assign, nonatomic) id<TankDelegate> delegate;
@property (assign, nonatomic) int level;
@property (assign, nonatomic) int health;

@property (nonatomic) TankState state;

@end
