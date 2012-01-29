//
//  SKTexture.m
//  spriteKit
//
//  Created by Ulrik Damm on 22/1/12.
//  Copyright (c) 2012 Gereen.dk. All rights reserved.
//

#import "SKTexture.h"
#import <OpenGLES/ES2/gl.h>

@interface SKTexture ()

@property (assign, nonatomic) CGSize size;

- (void)createWithImage:(UIImage*)image;

@end

@implementation SKTexture

@synthesize textureId;
@synthesize size;

- (id)initWithImage:(UIImage*)image {
	if ((self = [super init])) {
		[self createWithImage:image];
	}
	
	return self;
}

- (id)initWithText:(NSString*)text usingFont:(UIFont*)font {
	if (self = [super init]) {
		CGSize _size = CGSizeMake(256, 32);//[text sizeWithFont:font];
		
		if (UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(_size, NO, 0.0);
		else
			UIGraphicsBeginImageContext(_size);
		
		[[UIColor colorWithRed:.5 green:.5 blue:.5 alpha:.5] setFill];
		UIRectFill(CGRectMake(0, 0, _size.width, _size.height));
		[[UIColor colorWithRed:1 green:1 blue:1 alpha:1] setFill];
		[text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
		
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		[self createWithImage:image];
	}
	
	return self;
}

- (void)createWithImage:(UIImage*)image {
	CGImageRef graphic = image.CGImage;
	
	size_t width = CGImageGetWidth(graphic);
	size_t height = CGImageGetHeight(graphic);
	
	size = CGSizeMake(width, height);
	
	GLubyte *data = (GLubyte*)calloc(width * height * 4, sizeof(GLubyte));
	
	CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, CGImageGetColorSpace(graphic), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), graphic);
	CGContextRelease(context);
	
	glGenTextures(1, &textureId);
	glBindTexture(GL_TEXTURE_2D, textureId);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
	
	free(data);
}

- (void)dealloc {
	glDeleteTextures(1, &textureId);
}

@end
