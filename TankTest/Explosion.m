//
//  Explosion.m
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import "Explosion.h"

@interface Explosion () {
	int counter;
}

@end

@implementation Explosion

@synthesize spritestate;

- (BOOL)update {
	if (spritestate >= 4) {
		self.visible = NO;
	}
	
	self.textureClip = CGRectMake((spritestate % 2) * 64, (spritestate / 2) * 64, 64, 64);
	
	[super draw];
	
	if (++counter % 5 == 0) {
		spritestate++;
	}
	
	return YES;
}

@end
