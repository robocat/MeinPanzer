//
//  Shot.m
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import "Shot.h"
#import "Tank.h"

@implementation Shot

@synthesize speed;
@synthesize map;
@synthesize mapwidth;
@synthesize mapheight;
@synthesize bounds;
@synthesize delegate;
@synthesize owner;
@synthesize tanks;

- (BOOL)update {
	CGFloat speednew = self.speed;
	CGFloat rotationnow = self.rotation;
	
	self.position = CGPointMake(self.position.x + cos(rotationnow) * speednew, self.position.y + sin(rotationnow) * speednew);
	
	if (self.position.x < 0 || self.position.y < 0 || self.position.x >= mapwidth * 63 || self.position.y >= mapheight * 63) {
		[self.delegate explode:self on:CGPointMake(0, 0)];
		return NO;
	}
	
	int i = (self.position.x + self.bounds.origin.x) / 64, j = (self.position.y + self.bounds.origin.y) / 64;
	
	if (CGRectIntersectsRect(CGRectMake(self.position.x + self.bounds.origin.x,
										self.position.y + self.bounds.origin.y,
										self.bounds.size.width,
										self.bounds.size.height),
							 CGRectMake(i * 64, j * 64, 64, 64))) {
		int tile = [[map objectAtIndex:i + j * mapwidth] intValue];
		
		if (tile == 1 || tile == 5) {
			[self.delegate explode:self on:CGPointMake(i, j)];
			return NO;
		}
	}
	
	for (Tank *tank in self.tanks) {
		if (CGRectIntersectsRect(CGRectMake(self.position.x + self.bounds.origin.x,
											self.position.y + self.bounds.origin.y,
											self.bounds.size.width,
											self.bounds.size.height),
								 CGRectMake(tank.position.x + tank.bounds.origin.x,
											tank.position.y + tank.bounds.origin.y,
											tank.bounds.size.width,
											tank.bounds.size.height))) {
									 [self.delegate shot:self hitTank:tank];
									 return NO;
		}
	}
	
	return YES;
}

@end
