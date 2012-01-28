//
//  mainViewController.m
//  TankTest
//
//  Created by Ulrik Damm on 28/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import "mainViewController.h"
#import "SKView.h"
#import "SKSprite.h"
#import "SKTexture.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import "Tank.h"
#import "Shot.h"
#import "Explosion.h"
#import "Pickup.h"

@interface mainViewController () <UIAccelerometerDelegate, TankDelegate>

@property (strong, nonatomic) SKView *skView;
@property (strong, nonatomic) SKShader *shader;
@property (strong, nonatomic) SKTexture *texture;
@property (strong, nonatomic) SKTexture *tileMap;
@property (strong, nonatomic) NSMutableArray *sprites;
@property (strong, nonatomic) Tank *tank;
@property (strong, nonatomic) NSMutableArray *shots;
@property (strong, nonatomic) NSMutableArray *explotions;
@property (strong, nonatomic) NSMutableArray *spritesToChange;
@property (strong, nonatomic) NSMutableArray *map;
@property (assign, nonatomic) CGSize mapSize;
@property (strong, nonatomic) NSMutableArray *tanks;
@property (strong, nonatomic) NSMutableArray *pickups;

@end

@implementation mainViewController

@synthesize skView;
@synthesize shader;
@synthesize texture;
@synthesize sprites;
@synthesize tank;
@synthesize tileMap;
@synthesize shots;
@synthesize explotions;
@synthesize spritesToChange;
@synthesize map;
@synthesize mapSize;
@synthesize tanks;
@synthesize pickups;

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.skView = [[SKView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:self.skView];
	
	self.shader = [[SKShader alloc] init];
	
	NSString *vertexShaderString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vertexShader" ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
	[self.shader addSource:vertexShaderString ofType:GL_VERTEX_SHADER error:nil];
	
	NSString *fragmentShaderString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fragmentShader" ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
	[self.shader addSource:fragmentShaderString ofType:GL_FRAGMENT_SHADER error:nil];
	
	[self.shader linkProgram:nil];
	
	self.skView.shader = self.shader;
	
	self.texture = [[SKTexture alloc] initWithImage:[UIImage imageNamed:@"tileset.png"]];
	self.tileMap = [[SKTexture alloc] initWithImage:[UIImage imageNamed:@"tileset6.png"]];
	
	[self.skView setSpriteGroup:@"sprites"];
	
	NSData *levelData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"testmap40x40" ofType:@"json"] options:0 error:nil];
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:levelData options:0 error:nil];
	NSDictionary *layer = [[dict valueForKey:@"layers"] objectAtIndex:0];
	NSMutableArray *data = [[layer valueForKey:@"data"] mutableCopy];
	self.map = data;
	
	int height = [[layer valueForKey:@"height"] intValue];
	int width = [[layer valueForKey:@"width"] intValue];
	self.mapSize = CGSizeMake(width, height);
	
	self.sprites = [NSMutableArray array];
	
	int i, j;
	for (i = 0; i < width; i++) {
		for (j = 0; j < height; j++) {
			SKSprite *grass = [[SKSprite alloc] initWithTexture:self.tileMap shader:self.shader];
			grass.position = CGPointMake(i * 64, j * 64);
			grass.size = CGSizeMake(64, 64);
			
			int tile = [[data objectAtIndex:i + j * width] intValue] - 1;
			int x = tile % 2;
			int y = tile / 2;
			
			grass.textureClip = CGRectMake(64 * x, 64 * y, 64, 64);
			grass.anchor = CGPointMake(-32, -32);
			grass.alpha = NO;
			
			[self.skView addSprite:grass];
			[self.sprites addObject:grass];
		}
	}
	
	self.tank = [[Tank alloc] initWithTexture:self.texture shader:self.shader];
	self.tank.position = CGPointMake(128, 256);
	self.tank.size = CGSizeMake(64, 64);
	self.tank.textureClip = CGRectMake(64 * 2, 0, 64, 64);
	self.tank.anchor = CGPointMake(-32, -32);
	self.tank.alpha = YES;
	self.tank.zpos = 1;
	self.tank.mapwidth = width;
	self.tank.mapheight = height;
	self.tank.map = data;
	self.tank.bounds = CGRectMake(17, 23, 26, 20);
	self.tank.delegate = self;
	
	[self.skView addSprite:self.tank];
	
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
	accel.delegate = self;
	[accel setUpdateInterval:1.0 / 30.0];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
	[self.view addGestureRecognizer:tap];
	
	self.shots = [NSMutableArray array];
	self.explotions = [NSMutableArray array];
	self.spritesToChange = [NSMutableArray array];
	self.tanks = [NSMutableArray array];
	self.pickups = [NSMutableArray array];
	
	void (^addEnemy)(CGPoint pos) = ^(CGPoint pos) {
		Tank *enemy = [[Tank alloc] initWithTexture:self.texture shader:self.shader];
		enemy.position = pos;
		enemy.size = CGSizeMake(64, 64);
		enemy.textureClip = CGRectMake(64 * 2, 0, 64, 64);
		enemy.anchor = CGPointMake(-32, -32);
		enemy.alpha = YES;
		enemy.bounds = CGRectMake(17, 23, 26, 20);
		[self.skView addSprite:enemy];
		[self.tanks addObject:enemy];
	};
	
	addEnemy(CGPointMake(256, 256 + 64 * 0));
	addEnemy(CGPointMake(256, 256 + 64 * 1));
	addEnemy(CGPointMake(256, 256 + 64 * 2));
	addEnemy(CGPointMake(256, 256 + 64 * 3));
	addEnemy(CGPointMake(256, 256 + 64 * 4));
	addEnemy(CGPointMake(256, 256 + 64 * 5));
	addEnemy(CGPointMake(256, 256 + 64 * 6));
	addEnemy(CGPointMake(256, 256 + 64 * 7));
	addEnemy(CGPointMake(256, 256 + 64 * 8));
	addEnemy(CGPointMake(256, 256 + 64 * 9));
	
	CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	self.tank.rotation += acceleration.y / 2;
	self.tank.speed = -acceleration.z;
}

- (void)update {
	self.skView.viewpos = CGPointMake(self.tank.position.x - 192, self.tank.position.y - 128);
	
	[self.skView render];
	
	for (SKSprite *sprite in self.spritesToChange) {
		if ([self.skView containsSprite:sprite]) {
			[self.skView removeSprite:sprite];
		} else {
			[self.skView addSprite:sprite];
		}
	}
	
	[self.spritesToChange removeAllObjects];
}

- (void)tap {
	Shot *shot = [[Shot alloc] initWithTexture:self.texture shader:self.shader];
	shot.textureClip = CGRectMake(64 * 2, 64, 64, 64);
	shot.bounds = CGRectMake(37, 32, 8, 4);
	shot.size = CGSizeMake(64, 64);
	shot.alpha = YES;
	shot.anchor = CGPointMake(-32, -32);
	shot.rotation = self.tank.rotation;
	shot.position = self.tank.position;
	shot.speed = 3;
	shot.mapwidth = self.tank.mapwidth;
	shot.mapheight = self.tank.mapheight;
	shot.map = self.tank.map;
	shot.delegate = self;
	shot.owner = self.tank;
	shot.tanks = self.tanks;
	
	[self.shots addObject:shot];
	[self.skView addSprite:shot];
	
	SKSprite *muzzle = [[SKSprite alloc] initWithTexture:self.texture shader:self.shader];
	muzzle.position = self.tank.position;
	muzzle.textureClip = CGRectMake(64 * (self.tank.level > 3? 4: 3), 0, 64, 64);
	muzzle.size = CGSizeMake(64, 64);
	muzzle.alpha = YES;
	muzzle.anchor = CGPointMake(-32, -32);
	muzzle.rotation = self.tank.rotation;
	muzzle.zpos = 3;
	
	[self.skView addSprite:muzzle];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.02 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[spritesToChange addObject:muzzle];
	});
}

- (void)explode:(Shot *)shot on:(CGPoint)obj {
	[self.shots removeObject:shot];
	[self.spritesToChange addObject:shot];
	
	void (^expl)(CGPoint pos) = ^(CGPoint pos) {
		Explosion *exp = [[Explosion alloc] initWithTexture:self.texture shader:self.shader];
		exp.position = pos;
		exp.size = CGSizeMake(64, 64);
		exp.alpha = YES;
		exp.anchor = CGPointMake(-32, -32);
		exp.rotation = shot.rotation;
		[self.explotions addObject:exp];
		[self.spritesToChange addObject:exp];
	};
	
	expl(shot.position);
	
	if ([[self.map objectAtIndex:obj.x + obj.y * self.mapSize.width] intValue] == 5) {
		for (SKSprite *sprite in self.sprites) {
			if (sprite.position.x == obj.x * 64 && sprite.position.y == obj.y * 64) {
				sprite.textureClip = CGRectMake(64, 64, 64, 64);
				[self.map removeObjectAtIndex:obj.x + obj.y * self.mapSize.width];
				[self.map insertObject:[NSNumber numberWithInt:4] atIndex:obj.x + obj.y * self.mapSize.width];
				break;
			}
		}
	}
}

- (SKSprite*)objectAt:(CGPoint)point {
	for (SKSprite *sprite in self.sprites) {
		if (sprite.position.x == point.x * 64 && sprite.position.y == point.y * 64) {
			return sprite;
		}
	}
	
	return nil;
}

- (void)shot:(Shot *)shot hitTank:(Tank *)tank_ {
	[self.shots removeObject:shot];
	[self.spritesToChange addObject:shot];
	
	void (^expl)(CGPoint pos) = ^(CGPoint pos) {
		Explosion *exp = [[Explosion alloc] initWithTexture:self.texture shader:self.shader];
		exp.position = pos;
		exp.size = CGSizeMake(128, 128);
		exp.alpha = YES;
		exp.anchor = CGPointMake(-16, -16);
		exp.rotation = shot.rotation;
		exp.zpos = 2;
		[self.explotions addObject:exp];
		[self.spritesToChange addObject:exp];
	};
	
	CGPoint pos = CGPointMake(tank_.position.x + tank_.bounds.origin.x, tank_.position.y + tank_.bounds.origin.y);
	
	expl(CGPointMake(pos.x - 16, pos.y - 16));
	expl(CGPointMake(pos.x - 16, pos.y + 16));
	expl(CGPointMake(pos.x + 16, pos.y - 16));
	expl(CGPointMake(pos.x + 16, pos.y + 16));
	expl(CGPointMake(pos.x, pos.y));
	
	[self.tanks removeObject:tank_];
	[self.spritesToChange addObject:tank_];
	
	Pickup *hitlerkage = [[Pickup alloc] initWithTexture:self.texture shader:self.shader];
	hitlerkage.textureClip = CGRectMake(64 * 3, 64, 64, 64);
	hitlerkage.size = CGSizeMake(64, 64);
	hitlerkage.position = tank_.position;
	hitlerkage.anchor = CGPointMake(-32, -32);
	hitlerkage.alpha = YES;
	
	[self.pickups addObject:hitlerkage];
	[self.spritesToChange addObject:hitlerkage];
}

- (void)tankMoved:(Tank *)tank_ {
	int i;
	for (i = 0; i < [self.pickups count]; i++) {
		Pickup *p = [self.pickups objectAtIndex:i];
		
		if (pow(p.position.x - tank_.position.x, 2) + pow(p.position.y - tank_.position.y, 2) < pow(16, 2)) {
			[self.pickups removeObject:p];
			[self.spritesToChange addObject:p];
			
			tank_.level++;
			break;
		}
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

@end
