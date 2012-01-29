//
//  Tank.m
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import "Tank.h"

@interface Tank ()

@property (strong, nonatomic) SKSprite *healthbar;
@property (strong, nonatomic) SKSprite *healthbarback;

@end

@implementation Tank

@synthesize speed;
@synthesize map;
@synthesize mapwidth;
@synthesize mapheight;
@synthesize bounds;
@synthesize delegate;
@synthesize level;
@synthesize health;
@synthesize healthbar;
@synthesize healthbarback;
@synthesize maxhealth;
@synthesize timeInZone;
@synthesize state = _state;

- (id)initWithTexture:(SKTexture *)texture shader:(SKShader *)shader {
	if (self = [super initWithTexture:texture shader:shader]) {
		health = 10;
		
		self.healthbar = [[SKSprite alloc] initWithTexture:texture shader:shader];
		healthbar.textureClip = CGRectMake(4 * 64, 64, 1, 5);
		healthbar.size = CGSizeMake(32, 5);
		healthbar.position = CGPointMake(self.position.x + 32, self.position.y + 16);
		healthbar.anchor = CGPointMake(-16, -2);
		healthbar.alpha = YES;
		healthbar.zpos = 10;
		
		self.healthbarback = [[SKSprite alloc] initWithTexture:texture shader:shader];
		healthbarback.textureClip = CGRectMake(4 * 64 + 1, 64, 1, 5);
		healthbarback.size = CGSizeMake(32, 5);
		healthbarback.position = CGPointMake(self.position.x + 32, self.position.y + 16);
		healthbarback.anchor = CGPointMake(-16, -2);
		healthbarback.alpha = YES;
		healthbarback.zpos = 10;
		
		[self.subsprites addObject:healthbarback];
		[self.subsprites addObject:healthbar];
		
		self.level = 0;
	}
	
	return self;
}

- (BOOL)update {
	CGFloat speednew = self.speed;
	CGFloat rotationnow = self.rotation;
	
	self.position = CGPointMake(self.position.x + cos(rotationnow) * speednew, self.position.y + sin(rotationnow) * speednew);
	
	BOOL pushedBack = NO;
	BOOL timeCount = NO;
	
	int i, j;
	for (i = 0; i < mapwidth; i++) {
		for (j = 0; j < mapheight; j++) {
			if (CGRectIntersectsRect(CGRectMake(self.position.x + self.bounds.origin.x,
												self.position.y + self.bounds.origin.y,
												self.bounds.size.width,
												self.bounds.size.height),
									 CGRectMake(i * 64, j * 64, 64, 64))) {
				int tile = [[map objectAtIndex:i + j * mapwidth] intValue];
				
				if ((tile == 29 || tile == 1 || tile == 15) && !pushedBack) {
					pushedBack = YES;
					self.position = CGPointMake(self.position.x - cos(rotationnow) * speednew, self.position.y - sin(rotationnow) * speednew);
				}
				
				if (tile == 31 && !timeCount) {
					self.timeInZone++;
					[self.delegate tank:self hasBeenInZoneFor:self.timeInZone];
					timeCount = YES;
				}
			}
		}
	}
	
	if (!timeCount) {
		self.timeInZone = 0;
	}
	
	[self.delegate tankMoved:self];
	
	self.healthbar.size = CGSizeMake(((CGFloat)health) / (((CGFloat)maxhealth) / 32), 5);
	self.healthbar.position = CGPointMake(self.position.x + 32, self.position.y + 16);
	self.healthbarback.position = CGPointMake(self.position.x + 32, self.position.y + 16);
	
	return YES;
}

- (void)setLevel:(int)_level {
	if (_level > 5) {
		_level = 5;
	}
	
	level = _level;
	
	if (level == 0) {
		self.textureClip = CGRectMake(64 * 2, 0, 64, 64);
	} else {
		self.textureClip = CGRectMake(64 * ((level - 1) % 4), 64 * ((level - 1) / 4 + 2), 64, 64);
	}
	
	switch (level) {
		case 0:
			self.bounds = CGRectMake(17, 23, 26, 20);
			self.health = self.maxhealth = 5;
			break;
		case 1:
			self.bounds = CGRectMake(15, 22, 31, 23);
			self.health = self.maxhealth = 10;
			break;
		case 2:
			self.bounds = CGRectMake(17, 21, 38, 26);
			self.health = self.maxhealth = 20;
			break;
		case 3:
			self.bounds = CGRectMake(16, 17, 45, 32);
			self.health = self.maxhealth = 30;
			break;
		case 4:
			self.bounds = CGRectMake(13, 15, 51, 33);
			self.health = self.maxhealth = 40;
			break;
		case 5:
			self.bounds = CGRectMake(14, 14, 37, 37);
			self.health = self.maxhealth = 50;
			break;
		default:
			break;
	}
}


#pragma mark - Overwrite

- (TankState)state
{
  TankState st;
  st.position = self.position;
  st.rotation = self.rotation;
  st.speed = self.speed;
  
  return st;
}

- (void)setState:(TankState)state
{
  self.position = state.position;
  self.rotation = state.rotation;
  self.speed = state.speed;
}



@end
