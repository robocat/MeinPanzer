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

- (BOOL)update {
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
	
	return YES;
}

- (void)setLevel:(int)_level {
	level = _level;
	
	if (level == 0) {
		self.textureClip = CGRectMake(64 * 2, 0, 64, 64);
	} else {
		self.textureClip = CGRectMake(64 * ((level - 1) % 4), 64 * ((level - 1) / 4 + 2), 64, 64);
	}
	
	switch (level) {
		case 0:
			self.bounds = CGRectMake(17, 23, 26, 20);
			break;
		case 1:
			self.bounds = CGRectMake(15, 22, 31, 23);
			break;
		case 2:
			self.bounds = CGRectMake(17, 21, 38, 26);
			break;
		case 3:
			self.bounds = CGRectMake(16, 17, 45, 32);
			break;
		case 4:
			self.bounds = CGRectMake(13, 15, 51, 33);
			break;
		case 5:
			self.bounds = CGRectMake(14, 14, 37, 37);
			break;
		default:
			break;
	}
}

@end
