//
//  Tank.m
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import "Tank.h"

@implementation Tank

@synthesize speed;
@synthesize map;
@synthesize mapwidth;
@synthesize mapheight;
@synthesize bounds;
@synthesize delegate;
@synthesize level;

@synthesize state = _state;

- (void)draw {
	CGFloat speednew = self.speed;
	CGFloat rotationnow = self.rotation;
	
	self.position = CGPointMake(self.position.x + cos(rotationnow) * speednew, self.position.y + sin(rotationnow) * speednew);
	
	int i, j;
	for (i = 0; i < mapwidth; i++) {
		for (j = 0; j < mapheight; j++) {
			if (CGRectIntersectsRect(CGRectMake(self.position.x + self.bounds.origin.x,
												self.position.y + self.bounds.origin.y,
												self.bounds.size.width,
												self.bounds.size.height),
									 CGRectMake(i * 64, j * 64, 64, 64))) {
				int tile = [[map objectAtIndex:i + j * mapwidth] intValue];
				
				if (tile == 1 || tile == 3 || tile == 5) {
					self.position = CGPointMake(self.position.x - cos(rotationnow) * speednew, self.position.y - sin(rotationnow) * speednew);
					goto end;
				}
			}
		}
	}
end:
	
	[self.delegate tankMoved:self];
	
	[super draw];
}

- (void)setLevel:(int)_level {
	level = _level;
	
	if (level == 0) {
		self.textureClip = CGRectMake(64 * 2, 0, 64, 64);
	} else {
		self.textureClip = CGRectMake(64 * ((level - 1) % 4), 64 * ((level - 1) / 4 + 2), 64, 64);
	}
}

@end
