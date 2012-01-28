//
//  Explosion.h
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKSprite.h"

@class Explosion;

@protocol ExplosionDelegate <NSObject>

- (void)explosionDone:(Explosion*)exp;

@end

@interface Explosion : SKSprite

@property (assign, nonatomic) int spritestate;
@property (assign, nonatomic) id<ExplosionDelegate> delegate;

@end
