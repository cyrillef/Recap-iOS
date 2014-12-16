//  (C) Copyright 2014, Autodesk, Inc.
//
// Permission to use, copy, modify, and distribute this software in object code
// form for any purpose and without fee is hereby granted, provided that the above
// copyright notice appears in all copies and that both that copyright notice and
// the limited warranty and restricted rights notice below appear in all supporting
// documentation.
//
// AUTODESK PROVIDES THIS PROGRAM "AS IS" AND WITH ALL FAULTS. AUTODESK SPECIFICALLY
// DISCLAIMS ANY IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
// AUTODESK, INC. DOES NOT WARRANT THAT THE OPERATION OF THE PROGRAM WILL BE UNINTERRUPTED
// OR ERROR FREE.
//
// Created by Cyrille Fauvel - May 23rd, 2014
//
#pragma once

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define kRenderingFrequency 60.0

@class AdskEAGLView ;

//-------------------------------------------------------------------
@interface AdskObjViewerBaseController : UIViewController

- (void)drawView:(AdskEAGLView *)view ;

@end

//-------------------------------------------------------------------
@interface AdskEAGLView : UIView {
@private
	// The pixel dimensions of the backbuffer
	GLint _backingWidth ;
	GLint _backingHeight ;
	
	EAGLContext *_context ;
	// These are the buffers we render to: the _viewRenderbuffer will contain the color that we will
	// finaly see on the screen, the depth renderbuffer has to be used if we want to make sure, that
	// we always see only the closest object and not just the one that has been drawn most recently.
	// The framebuffer is a collection of buffers to use together while rendering, here it is either
	// just the color buffer, or color and depth renderbuffer.
	GLuint _viewFramebuffer, _viewRenderbuffer, _depthRenderbuffer ;
	
	// Use of the CADisplayLink class is the preferred method for controlling your animation timing.
	// CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
	// The NSTimer object is used only as fallback when running on a pre-3.1 device where CADisplayLink
	// isn't available.
	BOOL _displayLinkSupported ;
	id _displayLink ;
	NSTimer *_animationTimer ;
	NSTimeInterval _animationInterval ;
	
@public
	// Shaders
	GLuint _simpleProgram ;
	GLuint _uniformMvp ;
	GLuint _uniformColour ;
	GLuint _uniformTexture, _uniformTexture1, _uniformTexture2, _uniformTexture3, _uniformTexture4, _uniformTexture5 ;
	
	CATransform3D _model ;
	CATransform3D _camera ;
	CATransform3D _projection ;
	CATransform3D _mvp ; // model view projection
}

@property(strong) EAGLContext *_context ;
@property(strong, nonatomic) AdskObjViewerBaseController *_controller ;

//+ (Class)layerClass ;

- (id)init ;
- (id)initWithFrame:(CGRect)frame ;
- (id)initWithCoder:(NSCoder *)coder ;
//- (void)dealloc ;

//- (void)layoutSubviews ;

//- (id)initGLES ;
//- (void)loadShaders ;
//- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file ;
//- (BOOL)linkProgram:(GLuint)prog ;
//- (BOOL)validateProgram:(GLuint)prog ;

//- (void)checkFrameBuffer ;
//- (void)createFramebuffer ;
//- (void)destroyFramebuffer ;
//- (void)destroyTextures ; // Done in the parser object

- (void)drawView ;
- (UIImage *)screenShot ;

- (void)startAnimation ;
- (BOOL)stopAnimation ;
- (void)setAnimationInterval:(NSTimeInterval)interval ;
- (BOOL)isAnimated ;

@end