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
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "AdskEAGLView.h"
#import "AdskObjParser.h"

//-------------------------------------------------------------------
@implementation AdskObjViewerBaseController

//- (void)drawView:(AdskEAGLView *)view ;

@end

//-------------------------------------------------------------------
@implementation AdskEAGLView

@synthesize _context ;
@synthesize _controller ;

+ (Class)layerClass {
	return ([CAEAGLLayer class]) ;
}

#pragma mark - View lifecycle

- (id)init {
	if ( (self =[super init]) ) {
		self =[self initGLES] ;
	}
	return (self) ;
}

- (id)initWithFrame:(CGRect)frame {
	if ( (self =[super initWithFrame:frame]) ) {
		self =[self initGLES] ;
	}
	return (self) ;
}

// Our EAGLView is the view in our MainWindow which will be automatically loaded to be displayed.
// When the EAGLView gets loaded, it will be initialized by calling this method.
- (id)initWithCoder:(NSCoder *)coder {
	if ( (self =[super initWithCoder:coder]) ) {
		self =[self initGLES] ;
	}
	return (self) ;
}

// Stop animating and release resources when they are no longer needed.
- (void)dealloc {
	[self stopAnimation] ;
	[self destroyFramebuffer] ;
	if ( _simpleProgram )
		glDeleteProgram (_simpleProgram) ;
    // Tear down context.
    if ( [EAGLContext currentContext] == _context )
        [EAGLContext setCurrentContext:nil] ;
	_context =nil ;
}

#pragma mark - View Layout

// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
- (void)layoutSubviews {
	[EAGLContext setCurrentContext:_context] ;
	[self destroyFramebuffer] ;
	/*[self performSelectorOnMainThread:@selector(drawView)
	 withObject:nil
	 waitUntilDone:NO] ;
	 */
}

#pragma mark - OpenGL ES

- (id)initGLES {
	CAEAGLLayer *eaglLayer =(CAEAGLLayer *)self.layer ;
	// Configure it so that it is opaque, does not retain the contents of the backbuffer when displayed, and uses RGBA8888 color.
	eaglLayer.opaque =YES ;
	eaglLayer.drawableProperties =[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:YES],
								   kEAGLDrawablePropertyRetainedBacking,
								   kEAGLColorFormatRGBA8,
								   kEAGLDrawablePropertyColorFormat,
								   nil] ;
	// Create our EAGLContext, and if successful make it current and create our framebuffer.
	_context =[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] ;
	if ( !_context )
        _context =[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1] ;
	if ( !_context || ![EAGLContext setCurrentContext:_context] )
		return (nil) ;
	[self createFramebuffer] ;
	
	if ( [_context API] == kEAGLRenderingAPIOpenGLES2 )
        [self loadShaders] ;
	//[EAGLContext setCurrentContext:_context] ;
	
	// Use of CADisplayLink requires iOS version 3.1 or greater.
	// The NSTimer object is used as fallback when it isn't available.
	NSString *reqSysVer =@"3.1" ;
	NSString *currSysVer =[[UIDevice currentDevice] systemVersion] ;
	if ( [currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending )
		_displayLinkSupported =YES ;
	
	// Default the animation interval to 1 per frame with CADisplayLink or 1/60th of a second for NSTimer.
	_animationInterval =1.0 ;
	return (self) ;
}

- (void)loadShaders {
	NSString *fullPath =[[NSBundle mainBundle] pathForResource:@"Autodesk-iOSViewer" ofType:@"bundle" inDirectory:@""] ;
	NSBundle *bundle =[NSBundle bundleWithPath:fullPath] ;
	//[bundle load] ;

	// Create and compile vertex shader.
	NSString *vertShaderPathname =[bundle pathForResource:@"Shader_texture" ofType:@"vsh"] ;
	GLuint vertShader ;
	if ( ![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname] ) {
		NSLog(@"Failed to compile vertex shader") ;
		return ;
	}
	// Create and compile fragment shader.
	NSString *fragShaderPathname =[bundle pathForResource:@"Shader_texture" ofType:@"fsh"] ;
	GLuint fragShader ;
	if ( ![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname] ) {
		vertShader =0 ;
		NSLog(@"Failed to compile fragment shader") ;
		return ;
	}
	
	// Create shader program.
	if ( !vertShader || !fragShader || !(_simpleProgram =glCreateProgram ()) )
		return ;
	// Attach vertex shader to program.
	glAttachShader (_simpleProgram, vertShader) ;
	// Attach fragment shader to program.
	glAttachShader (_simpleProgram, fragShader) ;
	
	// Bind attribute locations.
	// This needs to be done prior to linking.
	glBindAttribLocation (_simpleProgram, ATTRIB_POSITION, "position") ;
	//glBindAttribLocation (_simpleProgram, INDEX_NORMAL, "normal") ;
	//glBindAttribLocation (_simpleProgram, ATTRIB_COLOUR, "colour") ;
	glBindAttribLocation (_simpleProgram, ATTRIB_TEXCOORD, "texcoord") ;
	
	// Link program.
	if ( ![self linkProgram:_simpleProgram] ) {
		NSLog(@"Failed to link program: %d", _simpleProgram) ;
		glDeleteShader (vertShader) ;
		glDeleteShader (fragShader) ;
		glDeleteProgram (_simpleProgram) ;
		_simpleProgram =0 ;
		return ;
	}
	
	// Get uniform locations.
	_uniformMvp =glGetUniformLocation (_simpleProgram, "mvp") ;
	//_uniformColour =glGetUniformLocation (_simpleProgram, "colour") ;
	_uniformTexture =glGetUniformLocation (_simpleProgram, "texture") ;
	_uniformTexture1 =glGetUniformLocation (_simpleProgram, "texture1") ;
	_uniformTexture2 =glGetUniformLocation (_simpleProgram, "texture2") ;
	_uniformTexture3 =glGetUniformLocation (_simpleProgram, "texture3") ;
	_uniformTexture4 =glGetUniformLocation (_simpleProgram, "texture4") ;
	_uniformTexture5 =glGetUniformLocation (_simpleProgram, "texture5") ;
	
	// Release vertex and fragment shaders.
	glDeleteShader (vertShader) ;
	glDeleteShader (fragShader) ;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
	const GLchar *source =(GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String] ;
	if ( !source ) {
		NSLog(@"Failed to load vertex shader") ;
		return (NO) ;
	}
	
	*shader =glCreateShader (type) ;
	glShaderSource (*shader, 1, &source, NULL) ;
	glCompileShader (*shader) ;
	
#if defined(DEBUG)
	GLint logLength ;
	glGetShaderiv (*shader, GL_INFO_LOG_LENGTH, &logLength) ;
	if ( logLength > 0 ) {
		GLchar *log =(GLchar *)malloc(logLength) ;
		glGetShaderInfoLog (*shader, logLength, &logLength, log) ;
		NSLog(@"Shader compile log:\n%s", log) ;
		free (log) ;
	}
#endif
	
	GLint status ;
	glGetShaderiv (*shader, GL_COMPILE_STATUS, &status) ;
	if ( status == 0 ) {
		glDeleteShader (*shader) ;
		return (NO) ;
	}
	return (YES) ;
}

- (BOOL)linkProgram:(GLuint)prog {
	glLinkProgram (prog) ;
	
#if defined(DEBUG)
	GLint logLength ;
	glGetProgramiv (prog, GL_INFO_LOG_LENGTH, &logLength) ;
	if ( logLength > 0 ) {
		GLchar *log =(GLchar *)malloc (logLength) ;
		glGetProgramInfoLog (prog, logLength, &logLength, log) ;
		NSLog(@"Program link log:\n%s", log) ;
		free (log) ;
	}
#endif
	
	GLint status ;
	glGetProgramiv (prog, GL_LINK_STATUS, &status) ;
	if ( status == 0 )
		return (NO) ;
	return (YES) ;
}

- (BOOL)validateProgram:(GLuint)prog {
	glValidateProgram (prog) ;
	
	/*#if defined(DEBUG)
	 GLint logLength ;
	 glGetProgramiv (prog, GL_INFO_LOG_LENGTH, &logLength) ;
	 if ( logLength > 0 ) {
	 GLchar *log =(GLchar *)malloc (logLength) ;
	 glGetProgramInfoLog (prog, logLength, &logLength, log) ;
	 NSLog(@"Program validate log:\n%s", log) ;
	 free (log) ;
	 }
	 #endif
	 */
	GLint status ;
	glGetProgramiv (prog, GL_VALIDATE_STATUS, &status) ;
	return (status != 0) ;
}

#pragma mark - OpenGL ES Framebuffer

- (void)checkFrameBuffer {
	GLuint returned =(glCheckFramebufferStatus (GL_FRAMEBUFFER)) ;
	if ( returned != GL_FRAMEBUFFER_COMPLETE ) {
		NSLog(@"Error code: %x -->", returned) ;
		switch ( returned ) {
			case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
				NSLog(@"  Incomplete: Dimensions") ;
				break ;
			case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE:
				NSLog(@"  Incomplete: MultiSample Apple") ;
				break ;
			case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
				NSLog(@"  Incomplete: Missing Attachment") ;
				break ;
			case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
				NSLog(@"  Incomplete: Attachment") ;
				break ;
			default:
				NSLog(@"  Complete") ;
				break ;
		}
	}
}

- (void)createFramebuffer {
	if ( _viewFramebuffer )
		return ;
	// Generate IDs for a framebuffer object and a color renderbuffer
	[EAGLContext setCurrentContext:_context] ;
	
	// Create default framebuffer object and bind it
	glGenFramebuffers (1, &_viewFramebuffer) ;
	glBindFramebuffer (GL_FRAMEBUFFER, _viewFramebuffer) ;
	
	// Create color render buffer
	glGenRenderbuffers (1, &_viewRenderbuffer) ;
	glBindRenderbuffer (GL_RENDERBUFFER, _viewRenderbuffer) ;
	
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen whereever the layer is
	// (which corresponds with our view).
	// Get the storage from iOS so it can be displayed in the view
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer] ;
	
	// Get the frame's width and height
	glFramebufferRenderbuffer (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderbuffer) ;
	glGetRenderbufferParameteriv (GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth) ;
	glGetRenderbufferParameteriv (GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight) ;
	
	// Attach this color buffer to our framebuffer
	glFramebufferRenderbuffer (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderbuffer) ;
	
	// Create a depth renderbuffer
	glGenRenderbuffers (1, &_depthRenderbuffer) ;
	glBindRenderbuffer (GL_RENDERBUFFER, _depthRenderbuffer) ;
	// Create the storage for the buffer, optimized for depth values, same size as the colorRenderbuffer
	glRenderbufferStorage (GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _backingWidth, _backingHeight) ;
	// Attach the depth buffer to our framebuffer
	glFramebufferRenderbuffer (GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer) ;
	
	if ( glCheckFramebufferStatus (GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE )
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus (GL_FRAMEBUFFER)) ;
}

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer {
	[EAGLContext setCurrentContext:_context] ;
	
	// If the default framebuffer has been set, delete it.
	if ( _viewFramebuffer ) {
		glDeleteFramebuffers (1, &_viewFramebuffer) ;
		_viewFramebuffer =0 ;
	}
	// Same for the renderbuffers, if they are set, delete them
	if ( _viewRenderbuffer ) {
		glDeleteRenderbuffers (1, &_viewRenderbuffer) ;
		_viewRenderbuffer =0 ;
	}
	if ( _depthRenderbuffer ) {
		glDeleteRenderbuffers (1, &_depthRenderbuffer) ;
		_depthRenderbuffer =0 ;
	}
}

#pragma mark - OpenGL ES draw

// Updates the OpenGL view when the timer fires
- (void)drawView {
	// Make it the current context for rendering
	[EAGLContext setCurrentContext:_context] ;
	[self createFramebuffer] ; // If our framebuffers have not been created yet, do that now!
	glBindFramebuffer (GL_FRAMEBUFFER, _viewFramebuffer) ;
	glViewport (0, 0, _backingWidth, _backingHeight) ;
	
	[_controller drawView:self] ;
	
	// Finally, get the color buffer we rendered to, and pass it to iOS
	// so it can display our awesome results!
	[EAGLContext setCurrentContext:_context] ;
	glBindRenderbuffer (GL_RENDERBUFFER, _viewRenderbuffer) ;
	[_context presentRenderbuffer:GL_RENDERBUFFER] ;
}

- (UIImage *)screenShot {
	[EAGLContext setCurrentContext:_context] ;
	[self createFramebuffer] ; // If our framebuffers have not been created yet, do that now!
	glBindFramebuffer (GL_FRAMEBUFFER, _viewFramebuffer) ;
	glViewport (0, 0, _backingWidth, _backingHeight) ;
	
	[_controller drawView:self] ;
	
	// Finally, get the color buffer we rendered to, and pass it to iOS
	// so it can display our awesome results!
	[EAGLContext setCurrentContext:_context] ;
	glBindRenderbuffer (GL_RENDERBUFFER, _viewRenderbuffer) ;
	//[_context presentRenderbuffer:GL_RENDERBUFFER] ; // DO NOT presentRenderBuffer because memory is discarded on iOS
	
	// Bind the color renderbuffer used to render the OpenGL ES view
	// If your application only creates a single color renderbuffer which is already bound at this point,
	// this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
	//glBindRenderbuffer (GL_RENDERBUFFER, _viewRenderbuffer) ;
	//glGetRenderbufferParameteriv (GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth) ;
	//glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
	
	NSInteger x =0, y =0, width =_backingWidth, height =_backingHeight ;
	NSInteger dataLength =width * height * 4 ;
	GLubyte *data =(GLubyte *)malloc (dataLength * sizeof (GLubyte)) ;
	
	// Read pixel data from the framebuffer
	glPixelStorei (GL_PACK_ALIGNMENT, 4) ;
	glReadPixels ((GLint)x, (GLint)y, (GLsizei)width, (GLsizei)height, GL_RGBA, GL_UNSIGNED_BYTE, data) ;
	
	// Create a CGImage with the pixel data
	// If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
	// otherwise, use kCGImageAlphaPremultipliedLast
	CGDataProviderRef ref =CGDataProviderCreateWithData (NULL, data, dataLength, NULL) ;
	CGColorSpaceRef colorspace =CGColorSpaceCreateDeviceRGB () ;
	CGImageRef iref =CGImageCreate (
									width, height, 8, 32, width * 4, colorspace,
									kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
									ref, NULL, true, kCGRenderingIntentDefault) ;
	// OpenGL ES measures data in PIXELS
	// Create a graphics context with the target size measured in POINTS
	NSInteger widthInPoints, heightInPoints ;
	if ( UIGraphicsBeginImageContextWithOptions != NULL ) {
		// On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
		// Set the scale parameter to your OpenGL ES view's contentScaleFactor
		// so that you get a high-resolution snapshot when its value is greater than 1.0
		CGFloat scale =self.contentScaleFactor ;
		widthInPoints =width / scale ;
		heightInPoints =height / scale ;
		UIGraphicsBeginImageContextWithOptions (CGSizeMake (widthInPoints, heightInPoints), NO, scale) ;
	} else {
		// On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
		widthInPoints =width ;
		heightInPoints =height ;
		UIGraphicsBeginImageContext (CGSizeMake (widthInPoints, heightInPoints)) ;
	}
	
	CGContextRef cgcontext =UIGraphicsGetCurrentContext () ;
	// UIKit coordinate system is upside down to GL/Quartz coordinate system
	// Flip the CGImage by rendering it to the flipped bitmap context
	// The size of the destination area is measured in POINTS
	CGContextSetBlendMode (cgcontext, kCGBlendModeCopy) ;
	CGContextDrawImage (cgcontext, CGRectMake (0.0, 0.0, widthInPoints, heightInPoints), iref) ;
	// Retrieve the UIImage from the current context
	UIImage *image =UIGraphicsGetImageFromCurrentImageContext () ;
	UIGraphicsEndImageContext () ;
	
	// Clean up
	free (data) ;
	CFRelease (ref) ;
	CFRelease (colorspace) ;
	CGImageRelease (iref) ;
	
	return (image) ;
}

#pragma mark - Animation

- (void)startAnimation {
	if ( _displayLink || _animationTimer )
		return ;
	if ( _displayLinkSupported ) {
		// CADisplayLink is API new in iOS 3.1. Compiling against earlier versions will result in a warning,
		// but can be dismissed if the system version runtime check for CADisplayLink exists in -awakeFromNib.
		// The runtime check ensures this code will not be called in system versions earlier than 3.1.
		_displayLink =[NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)] ;
		[_displayLink setFrameInterval:_animationInterval] ;
		
		// The run loop will retain the display link on add.
		[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode] ;
	} else {
		_animationTimer =[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(_animationInterval / kRenderingFrequency)
														  target:self
														selector:@selector(drawView)
														userInfo:nil
														 repeats:YES] ;
	}
}

- (BOOL)stopAnimation {
	BOOL bRet =(_displayLink || _animationTimer) ;
	if ( _displayLink )
		[_displayLink invalidate] ;
	_displayLink =nil ;
	if ( _animationTimer )
		[_animationTimer invalidate] ;
	_animationTimer =nil ;
	return (bRet) ;
}

- (void)setAnimationInterval:(NSTimeInterval)interval {
	// Frame interval defines how many display frames must pass between each time the display link fires.
	// The display link will only fire 30 times a second when the frame internal is two on a display that
	// refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second
	// when the display refreshes at 60 times a second. A frame interval setting of less than one results
	// in undefined behavior.
	if ( interval < 1.0 )
		return  ;
	_animationInterval =interval ;
	if ( _displayLink || _animationTimer ) {
		[self stopAnimation] ;
		[self startAnimation] ;
	}
}

- (BOOL)isAnimated {
	return (_displayLink || _animationTimer) ;
}

@end
