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
#import <AudioToolbox/AudioToolbox.h>
#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>


typedef enum {
	GameStateStartGame,
	GameStatePicker,
	GameStateMultiplayer,
	GameStateMultiplayerCointoss,
	GameStateMultiplayerReconnect
} GameStates;


typedef enum {
	kServer,
	kClient
} GameNetwork;


typedef enum {
	NETWORK_ACK,					// no packet
	NETWORK_COINTOSS,				// decide who is going to be the server
	NETWORK_MOVE_EVENT,				// send position
	NETWORK_FIRE_EVENT,				// send fire
  NETWORK_TELEPORT_EVENT,				// Dead, teleport
	NETWORK_HEARTBEAT,				// send of entire state at regular intervals
  NETWORK_PICKUP,
  NETWORK_HIT_TANK_EVENT,
} PacketCodes;



#define kTankSessionID @"hitlerTank"

#define kMaxTankPacketSize 1024

const float kHeartbeatTimeMaxDelay = 2.0f;



@interface mainViewController () <GKSessionDelegate, GKPeerPickerControllerDelegate, UIAccelerometerDelegate, TankDelegate, ExplosionDelegate>

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

@property (strong, nonatomic) UIAlertView *connectionAlert;


@property(nonatomic) GameStates gameState;
@property(strong, nonatomic) GKSession *gameSession;
@property(nonatomic) GameNetwork peerStatus;

@property(copy, nonatomic)	 NSString *gamePeerId;
@property(strong, nonatomic) NSDate *lastHeartbeatDate;

@property (nonatomic) NSInteger gameUniqueID;




- (Shot*)shootFromTank:(Tank*)t;


-(void)startPicker;
- (void)invalidateSession:(GKSession *)session;

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context;
- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)reliable;



@end





@implementation mainViewController {
  int gamePacketNumber;
}

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

@synthesize gameState = _gameState;
@synthesize gameSession = _gameSession;

@synthesize peerStatus = _peerStatus;
@synthesize gamePeerId = _gamePeerId;
@synthesize lastHeartbeatDate = _lastHeartbeatDate;

@synthesize gameUniqueID = _gameUniqueID;

@synthesize connectionAlert = _connectionAlert;



- (void)viewDidLoad {
	[super viewDidLoad];
  
  // Game Session
  _peerStatus = kServer;
  gamePacketNumber = 0;
  _gameSession = nil;
  _gamePeerId = nil;
  _lastHeartbeatDate = nil;
  
  
  NSString *uid = [[UIDevice currentDevice] uniqueIdentifier];
  _gameUniqueID = [uid hash];
  
  _gameState = GameStateStartGame;
  
  
  
	
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
	self.tileMap = [[SKTexture alloc] initWithImage:[UIImage imageNamed:@"tilesettest5.png"]];
	
	[self.skView setSpriteGroup:@"sprites"];
	
	NSData *levelData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"arenastyle" ofType:@"json"] options:0 error:nil];
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
			int x = tile % 4;
			int y = tile / 4;
			
			grass.textureClip = CGRectMake(64 * x, 64 * y, 64, 64);
			grass.anchor = CGPointMake(-32, -32);
			grass.alpha = NO;
			
			[self.skView addSprite:grass];
			[self.sprites addObject:grass];
		}
	}
	
	self.tank = [[Tank alloc] initWithTexture:self.texture shader:self.shader];
	self.tank.position = CGPointMake(1024, 1024);
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
//	addEnemy(CGPointMake(256, 256 + 64 * 1));
//	addEnemy(CGPointMake(256, 256 + 64 * 2));
//	addEnemy(CGPointMake(256, 256 + 64 * 3));
//	addEnemy(CGPointMake(256, 256 + 64 * 4));
//	addEnemy(CGPointMake(256, 256 + 64 * 5));
//	addEnemy(CGPointMake(256, 256 + 64 * 6));
//	addEnemy(CGPointMake(256, 256 + 64 * 7));
//	addEnemy(CGPointMake(256, 256 + 64 * 8));
//	addEnemy(CGPointMake(256, 256 + 64 * 9));
	
	CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  
}


- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  [self startPicker];
  
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	self.tank.rotation += acceleration.y / 4;
	self.tank.speed = -acceleration.z * 2;
  
  
  if (_gameState == GameStateMultiplayer) {
    TankState ts = self.tank.state;
    [self sendNetworkPacket:_gameSession packetID:NETWORK_MOVE_EVENT withData:&ts ofLength:sizeof(TankState) reliable: NO];
  }
}

- (void)update {
  
  static int counter = 0;
  
	switch (_gameState) {
		case GameStatePicker:
		case GameStateStartGame:
			break;
		case GameStateMultiplayerCointoss:
			[self sendNetworkPacket:self.gameSession packetID:NETWORK_COINTOSS withData:&_gameUniqueID ofLength:sizeof(int) reliable:YES];
			self.gameState = GameStateMultiplayer; // we only want to be in the cointoss state for one loop
			break;
		case GameStateMultiplayer:
      
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
      
      
			counter++;
			if(!(counter&7)) { // once every 8 updates check if we have a recent heartbeat from the other player, and send a heartbeat packet with current state
				if(_lastHeartbeatDate == nil) {
					// we haven't received a hearbeat yet, so set one (in case we never receive a single heartbeat)
					_lastHeartbeatDate = [NSDate date];
				}
				else if(fabs([self.lastHeartbeatDate timeIntervalSinceNow]) >= kHeartbeatTimeMaxDelay) {
          // see if the last heartbeat is too old
          // seems we've lost connection, notify user that we are trying to reconnect (until GKSession actually disconnects)
          
					NSString *message = [NSString stringWithFormat:@"Trying to reconnect...\nMake sure you are within range of %@.", [self.gameSession displayNameForPeer:self.gamePeerId]];
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
					self.connectionAlert = alert;
					[alert show];
          
					self.gameState = GameStateMultiplayerReconnect;
				}
				
				// send a new heartbeat to other player
				TankState ts = self.tank.state;
				[self sendNetworkPacket:_gameSession packetID:NETWORK_HEARTBEAT withData:&ts ofLength:sizeof(TankState) reliable:NO];
			}
			break;
		case GameStateMultiplayerReconnect:
			// we have lost a heartbeat for too long, so pause game and notify user while we wait for next heartbeat or session disconnect.
			counter++;
			if(!(counter&7)) { // keep sending heartbeats to the other player in case it returns
				TankState ts = self.tank.state;
				[self sendNetworkPacket:_gameSession packetID:NETWORK_HEARTBEAT withData:&ts ofLength:sizeof(TankState) reliable:NO];
			}
			break;
		default:
			break;
	}
}

- (void)tap {
  if (_gameState == GameStateMultiplayer) {
    TankState ts = self.tank.state;
    [self sendNetworkPacket:_gameSession packetID:NETWORK_FIRE_EVENT withData:&ts ofLength:sizeof(TankState) reliable: NO];
  }
  
	[self shootFromTank:self.tank];
}

- (Shot*)shootFromTank:(Tank*)t {
	Shot *shot = [[Shot alloc] initWithTexture:self.texture shader:self.shader];
	shot.textureClip = CGRectMake(64 * 2, 64, 64, 64);
	shot.bounds = CGRectMake(37, 32, 8, 4);
	shot.size = CGSizeMake(64, 64);
	shot.alpha = YES;
	shot.anchor = CGPointMake(-32, -32);
	shot.rotation = t.rotation;
	shot.position = t.position;
	shot.speed = 3;
	shot.mapwidth = self.mapSize.width;
	shot.mapheight = self.mapSize.height;
	shot.map = self.map;
	shot.delegate = self;
	shot.owner = t;
	shot.tanks = self.tanks;
	
	[self.shots addObject:shot];
	[self.skView addSprite:shot];
	
	SKSprite *muzzle = [[SKSprite alloc] initWithTexture:self.texture shader:self.shader];
	muzzle.position = t.position;
	muzzle.textureClip = CGRectMake(64 * (t.level > 3? 4: 3), 0, 64, 64);
	muzzle.size = CGSizeMake(64, 64);
	muzzle.alpha = YES;
	muzzle.anchor = CGPointMake(-32, -32);
	muzzle.rotation = t.rotation;
	muzzle.zpos = 3;
	
	[self.skView addSprite:muzzle];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.02 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[spritesToChange addObject:muzzle];
	});
	
	return shot;
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
		exp.delegate = self;
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
	
	tank_.health--;
  [self sendNetworkPacket:_gameSession packetID:NETWORK_HIT_TANK_EVENT withData:nil ofLength:0 reliable: NO];
	
	Explosion *exp = [[Explosion alloc] initWithTexture:self.texture shader:self.shader];
	exp.position = shot.position;
	exp.size = CGSizeMake(64, 64);
	exp.alpha = YES;
	exp.anchor = CGPointMake(-32, -32);
	exp.rotation = shot.rotation;
	exp.zpos = 2;
	exp.delegate = self;
	[self.explotions addObject:exp];
	[self.spritesToChange addObject:exp];
	
	if (tank_.health <= 0) {
		void (^expl)(CGPoint pos) = ^(CGPoint pos) {
			Explosion *exp = [[Explosion alloc] initWithTexture:self.texture shader:self.shader];
			exp.position = pos;
			exp.size = CGSizeMake(128, 128);
			exp.alpha = YES;
			exp.anchor = CGPointMake(-16, -16);
			exp.rotation = shot.rotation;
			exp.zpos = 2;
			exp.delegate = self;
			[self.explotions addObject:exp];
			[self.spritesToChange addObject:exp];
		};
		
		CGPoint pos = CGPointMake(tank_.position.x + tank_.bounds.origin.x, tank_.position.y + tank_.bounds.origin.y);
		
		expl(CGPointMake(pos.x - 16, pos.y - 16));
		expl(CGPointMake(pos.x - 16, pos.y + 16));
		expl(CGPointMake(pos.x + 16, pos.y - 16));
		expl(CGPointMake(pos.x + 16, pos.y + 16));
		expl(CGPointMake(pos.x, pos.y));
		
    		
		Pickup *hitlerkage = [[Pickup alloc] initWithTexture:self.texture shader:self.shader];
		hitlerkage.textureClip = CGRectMake(64 * 3, 64, 64, 64);
		hitlerkage.size = CGSizeMake(64, 64);
		hitlerkage.position = tank_.position;
		hitlerkage.anchor = CGPointMake(-32, -32);
		hitlerkage.alpha = YES;
		
		[self.pickups addObject:hitlerkage];
		[self.spritesToChange addObject:hitlerkage];
    
    
    // Enemy dead. Teleport
    tank_.position = CGPointMake(1024, 1024);
    tank_.health = 10;
    tank_.level = 0;
    
    TankState ts = tank_.state;
    [self sendNetworkPacket:_gameSession packetID:NETWORK_TELEPORT_EVENT withData:&ts ofLength:sizeof(TankState) reliable: NO];
	}
}

- (void)tankMoved:(Tank *)tank_ {
	int i;
	for (i = 0; i < [self.pickups count]; i++) {
		Pickup *p = [self.pickups objectAtIndex:i];
		
		if (pow(p.position.x - tank_.position.x, 2) + pow(p.position.y - tank_.position.y, 2) < pow(16, 2)) {
      
      TankState ts = tank_.state;
      [self sendNetworkPacket:_gameSession packetID:NETWORK_PICKUP withData:&ts ofLength:sizeof(TankState) reliable: NO];
      
			[self.pickups removeObject:p];
			[self.spritesToChange addObject:p];
			
			tank_.level++;
			break;
		}
	}
}

- (void)explosionDone:(Explosion *)exp {
	[self.spritesToChange addObject:exp];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
	return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}











#pragma mark -
#pragma mark Peer Picker Related Methods

-(void)startPicker {
	_gameState = GameStatePicker;
	
	GKPeerPickerController* picker = [[GKPeerPickerController alloc] init];
  picker.delegate = self;
	[picker show];
}


#pragma mark GKPeerPickerControllerDelegate Methods

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	picker.delegate = nil;
	
	// invalidate and release game session if one is around.
	if(_gameSession != nil)	{
		[self invalidateSession:self.gameSession];
		_gameSession = nil;
	}
	
	// go back to start mode
	_gameState = GameStateStartGame;
} 


- (GKSession *)peerPickerController:(GKPeerPickerController *)picker
           sessionForConnectionType:(GKPeerPickerConnectionType)type {
  
	GKSession *session = [[GKSession alloc] initWithSessionID:kTankSessionID
                                                displayName:@"Mein Panzer"
                                                sessionMode:GKSessionModePeer];
	return session;
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	// Remember the current peer.
	self.gamePeerId = peerID;
  
  NSLog(@"name %@", [session displayNameForPeer:peerID]);
	
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session;
	self.gameSession.delegate = self; 
	[self.gameSession setDataReceiveHandler:self withContext:nil];
	
	// Done with the Peer Picker
	[picker dismiss];
	picker.delegate = nil;
  
	// Start Multiplayer game by entering a cointoss state to determine who is server/client.
	self.gameState = GameStateMultiplayerCointoss;
	
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Allegro" ofType:@"m4a"] options:0 error:nil];
	AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:nil];
	[player play];
  
}


- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}



#pragma mark GKSessionDelegate Methods

- (void)session:(GKSession *)session
           peer:(NSString *)peerID
 didChangeState:(GKPeerConnectionState)state {
  
	if(self.gameState == GameStatePicker) {
		return;
	}
	
	if(state == GKPeerStateDisconnected) {
		NSString *message = [NSString stringWithFormat:@"Could not reconnect with %@.", [session displayNameForPeer:peerID]];
		if((self.gameState == GameStateMultiplayerReconnect) && self.connectionAlert && self.connectionAlert.visible) {
			self.connectionAlert.message = message;
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
			self.connectionAlert = alert;
			[alert show];
		}
		
		// go back to start mode
		_gameState = GameStateStartGame;
	}
} 


- (CGFloat)distanceBetweenPoint:(CGPoint)a andPoint:(CGPoint)b
{
  CGFloat a2 = powf(a.x-b.x, 2.f);
  CGFloat b2 = powf(a.y-b.y, 2.f);
  return sqrtf(a2 + b2);
}


#pragma mark Data Send/Receive Methods

/*
 * Getting a data packet. This is the data receive handler method expected by the GKSession. 
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{ 
	static int lastPacketTime = -1;
	unsigned char *incomingPacket = (unsigned char *)[data bytes];
	int *pIntData = (int *)&incomingPacket[0];
	//
	// developer  check the network time and make sure packers are in order
	//
	int packetTime = pIntData[0];
	int packetID = pIntData[1];
	if(packetTime < lastPacketTime && packetID != NETWORK_COINTOSS) {
		return;	
	}
	
	lastPacketTime = packetTime;
	switch( packetID ) {
		case NETWORK_COINTOSS:
    {
      // coin toss to determine roles of the two players
      int coinToss = pIntData[2];
      // if other player's coin is higher than ours then that player is the server
      if(coinToss > _gameUniqueID) {
        self.peerStatus = kClient;
      }
      
//      // notify user of tank color
//      self.gameLabel.text = (self.peerStatus == kServer) ? kBlueLabel : kRedLabel; // server is the blue tank, client is red
//      self.gameLabel.hidden = NO;
//      // after 1 second fire method to hide the label
//      [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideGameLabel:) userInfo:nil repeats:NO];
    }
			break;
		case NETWORK_MOVE_EVENT:
    {
      // received move event from other player, update other player's position/destination info
      TankState *ts = (TankState *)&incomingPacket[8];

      TankState newState;
      newState.position = ts->position;
      newState.rotation = ts->rotation;
      newState.speed = ts->speed;
      [(Tank *)[self.tanks objectAtIndex:0] setState:newState];
      
    }
			break;
		case NETWORK_FIRE_EVENT:
    {
      // received a missile fire event from other player, update other player's firing status
      TankState *ts = (TankState *)&incomingPacket[8];
      
      TankState newState;
      newState.position = ts->position;
      newState.rotation = ts->rotation;
      newState.speed = ts->speed;
      [(Tank *)[self.tanks objectAtIndex:0] setState:newState];
      
      Shot *shot = [self shootFromTank:[self.tanks objectAtIndex:0]];
      shot.position = newState.position;
      shot.rotation = newState.rotation;
    }
			break;
		case NETWORK_TELEPORT_EVENT:
    {
      TankState *ts = (TankState *)&incomingPacket[8];
      
      TankState newState;
      newState.position = ts->position;
      newState.rotation = ts->rotation;
      newState.speed = ts->speed;
      [self.tank setState:newState];
      self.tank.health = 10;
      self.tank.level = 0;
    }
			break;
    case NETWORK_HEARTBEAT:
    {
      // Received heartbeat data with other player's position, destination, and firing status.
      
      // update the other player's info from the heartbeat
//      TankState *ts = (TankState *)&incomingPacket[8];		// tank data as seen on other client
//      int peer = (self.peerStatus == kServer) ? kClient : kServer;
//      TankState *ds = &tankStates[peer];					// same tank, as we see it on this client
//      memcpy( ds, ts, sizeof(TankState) );
      
      // update heartbeat timestamp
      _lastHeartbeatDate = [NSDate date];
      
      // if we were trying to reconnect, set the state back to multiplayer as the peer is back
      if(self.gameState == GameStateMultiplayerReconnect) {
        if(self.connectionAlert && self.connectionAlert.visible) {
          [self.connectionAlert dismissWithClickedButtonIndex:-1 animated:YES];
        }
        _gameState = GameStateMultiplayer;
      }
    }
			break;
    case NETWORK_PICKUP:
    {
      TankState *ts = (TankState *)&incomingPacket[8];
      CGPoint point = ts->position;
      
      CGFloat distance = FLT_MAX;
      Pickup *pickupTaken = nil;
      
      for (Pickup *pu in self.pickups) {
        CGFloat dist = [self distanceBetweenPoint:pu.position andPoint:point];
        
        if (dist <= distance) {
          pickupTaken = pu;
          distance = dist;
        }
      }
      
      [self.pickups removeObject:pickupTaken];
      [self.skView removeSprite:pickupTaken];
      
      Tank *enemy = [self.tanks objectAtIndex:0];
      enemy.level++;
      
    }
			break;
    case NETWORK_HIT_TANK_EVENT:
    {
      self.tank.health--;
    }
			break;
		default:
			// error
			break;
	}
}

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)reliable
{
	// the packet we'll send is resued
	static unsigned char networkPacket[kMaxTankPacketSize];
	const unsigned int packetHeaderSize = 2 * sizeof(int); // we have two "ints" for our header
	
	if(length < (kMaxTankPacketSize - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
		int *pIntData = (int *)&networkPacket[0];
		// header info
		pIntData[0] = gamePacketNumber++;
		pIntData[1] = packetID;
		// copy data in after the header
		memcpy( &networkPacket[packetHeaderSize], data, length ); 
		
		NSData *packet = [NSData dataWithBytes: networkPacket length: (length+8)];
		if(reliable == YES) { 
			[session sendData:packet
                toPeers:[NSArray arrayWithObject:_gamePeerId]
           withDataMode:GKSendDataReliable
                  error:nil];
		} else {
			[session sendData:packet
                toPeers:[NSArray arrayWithObject:_gamePeerId]
           withDataMode:GKSendDataUnreliable
                  error:nil];
		}
	}
}


@end
