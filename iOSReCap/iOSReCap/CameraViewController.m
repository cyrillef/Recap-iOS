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

// Code coming from the Apple sample - Rewritten for ARC and iOS 7
// https://developer.apple.com/library/ios/samplecode/SquareCam/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011190

#import "CameraViewController.h"
#import "AdskUIImage+Additions.h"
#import "ALAssetsLibrary+Additions.h"

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

//------------------------------------------------------
// Create a CGImage with provided pixel buffer, pixel buffer must be uncompressed kCVPixelFormatType_32ARGB or kCVPixelFormatType_32BGRA
static void ReleaseCVPixelBuffer (void *pixel, const void *data, size_t size) {
	CVPixelBufferRef pixelBuffer =(CVPixelBufferRef)pixel ;
	CVPixelBufferUnlockBaseAddress (pixelBuffer, 0) ;
	CVPixelBufferRelease (pixelBuffer) ;
}

static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut) {
	OSType sourcePixelFormat =CVPixelBufferGetPixelFormatType (pixelBuffer) ;
	CGBitmapInfo bitmapInfo ;
	if ( kCVPixelFormatType_32ARGB == sourcePixelFormat )
		bitmapInfo =kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst ;
	else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat )
		bitmapInfo =kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst ;
	else
		return -95014 ; // Only uncompressed pixel formats
	
	size_t sourceRowBytes =CVPixelBufferGetBytesPerRow (pixelBuffer) ;
	size_t width =CVPixelBufferGetWidth (pixelBuffer) ;
	size_t height =CVPixelBufferGetHeight (pixelBuffer) ;
	
	CVPixelBufferLockBaseAddress (pixelBuffer, 0) ;
	void *sourceBaseAddr =CVPixelBufferGetBaseAddress (pixelBuffer) ;
	
	CGColorSpaceRef colorspace =CGColorSpaceCreateDeviceRGB () ;
    
	CVPixelBufferRetain (pixelBuffer) ;
	CGDataProviderRef provider =CGDataProviderCreateWithData ((void *)pixelBuffer, sourceBaseAddr, sourceRowBytes * height, ReleaseCVPixelBuffer) ;
	CGImageRef image =CGImageCreate (width, height, 8, 32, sourceRowBytes, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault) ;
	
	if ( provider )
		CGDataProviderRelease (provider) ;
	if ( colorspace )
		CGColorSpaceRelease (colorspace) ;
	*imageOut =image ;
	return (noErr) ;
}

// Utility used by newSquareOverlayedImageForFeatures for
static CGContextRef CreateCGBitmapContextForSize (CGSize size) {
    int bitmapBytesPerRow =(size.width * 4) ;
    CGColorSpaceRef colorSpace =CGColorSpaceCreateDeviceRGB () ;
    CGContextRef context =CGBitmapContextCreate (NULL, size.width, size.height, /*bits per component*/8, bitmapBytesPerRow, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast) ;
	CGContextSetAllowsAntialiasing (context, NO) ;
    CGColorSpaceRelease (colorSpace) ;
    return (context) ;
}

//------------------------------------------------------
@interface CameraViewController ()

@end

@implementation CameraViewController

@synthesize _photosceneid =__photosceneid ;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self =[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ;
    if ( self ) {
    }
    return (self) ;
}

- (void)viewDidLoad {
    [super viewDidLoad] ;
	[self setupAVCapture] ;
	_faceSquare =[UIImage imageNamed:@"faceDetector"] ;
	NSDictionary *detectorOptions =[[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil] ;
	_faceDetector =[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions] ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning] ;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)shouldAutorotate {
    //return ([[self.viewControllers lastObject] shouldAutorotate]) ;
	UIDeviceOrientation orientation =[[UIDevice currentDevice] orientation] ;
	if ( orientation == UIDeviceOrientationPortraitUpsideDown )
		return (NO) ;
	return (YES) ;
}

- (NSUInteger)supportedInterfaceOrientations {
    //return ([[self.viewControllers lastObject] supportedInterfaceOrientations]) ;
	return (UIDeviceOrientationPortrait | /*UIDeviceOrientationPortraitUpsideDown |*/ UIDeviceOrientationLandscapeRight | UIDeviceOrientationLandscapeLeft) ;
}

#pragma mark - Camera

- (void)setupAVCapture {
	NSError *error =nil ;
	
	AVCaptureSession *session =[AVCaptureSession new] ;
	if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
	    [session setSessionPreset:AVCaptureSessionPreset640x480] ;
	else
	    [session setSessionPreset:AVCaptureSessionPresetPhoto] ;
	
    // Select a video device, make an input
	AVCaptureDevice *device =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] ;
	AVCaptureDeviceInput *deviceInput =[AVCaptureDeviceInput deviceInputWithDevice:device error:&error] ;
	if ( error ) {
		UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
														   message:[error localizedDescription]
														  delegate:nil
												 cancelButtonTitle:@"Dismiss"
												 otherButtonTitles:nil] ;
		[alertView show] ;
		return ;
	}
	
    _isUsingFrontFacingCamera =NO ;
	if ( [session canAddInput:deviceInput] )
		[session addInput:deviceInput] ;
	
    // Make a still image output
	_stillImageOutput =[AVCaptureStillImageOutput new] ;
	[_stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)] ;
	if ( [session canAddOutput:_stillImageOutput] )
		[session addOutput:_stillImageOutput] ;
	
    // Make a video data output
	_videoDataOutput =[AVCaptureVideoDataOutput new] ;
	
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings =[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey] ;
	[_videoDataOutput setVideoSettings:rgbOutputSettings] ;
	[_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES] ; // Discard if the data output queue is blocked (as we process the still image)
    
    // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	_videoDataOutputQueue =dispatch_queue_create ("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL) ;
	[_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue] ;
	
    if ( [session canAddOutput:_videoDataOutput] )
		[session addOutput:_videoDataOutput] ;
	[[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO] ;
	
	_effectiveScale =1.0;
	_previewLayer =[[AVCaptureVideoPreviewLayer alloc] initWithSession:session] ;
	[_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]] ;
	[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect] ;
	CALayer *rootLayer =[_previewView layer] ;
	[rootLayer setMasksToBounds:YES] ;
	[_previewLayer setFrame:[rootLayer bounds]] ;
	[rootLayer addSublayer:_previewLayer] ;
	[session startRunning] ;
}

- (void)teardownAVCapture {
	_videoDataOutput =nil ;
	_videoDataOutputQueue =nil ;
	[_stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"] ;
	_stillImageOutput =nil ;
	[_previewLayer removeFromSuperlayer] ;
	_previewLayer =nil ;
}

- (IBAction)switchCameras:(id)sender {
	AVCaptureDevicePosition desiredPosition ;
	if ( _isUsingFrontFacingCamera )
		desiredPosition =AVCaptureDevicePositionBack ;
	else
		desiredPosition =AVCaptureDevicePositionFront ;
	
	for ( AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] ) {
		if ([d position] == desiredPosition) {
			[[_previewLayer session] beginConfiguration] ;
			AVCaptureDeviceInput *input =[AVCaptureDeviceInput deviceInputWithDevice:d error:nil] ;
			for ( AVCaptureInput *oldInput in [[_previewLayer session] inputs] ) {
				[[_previewLayer session] removeInput:oldInput] ;
			}
			[[_previewLayer session] addInput:input] ;
			[[_previewLayer session] commitConfiguration] ;
			break ;
		}
	}
	_isUsingFrontFacingCamera =!_isUsingFrontFacingCamera ;
}

#pragma mark - Shot

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVPixelBufferRef pixelBuffer =CMSampleBufferGetImageBuffer (sampleBuffer) ;
	CFDictionaryRef attachments =CMCopyDictionaryOfAttachments (kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate) ;
	CIImage *ciImage =[[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments] ;
	if ( attachments )
		CFRelease (attachments) ;
	NSDictionary *imageOptions =nil ;
	UIDeviceOrientation curDeviceOrientation =[[UIDevice currentDevice] orientation] ;
	int exifOrientation ;
	
    /* kCGImagePropertyOrientation values
	   The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
	   by the TIFF and EXIF specifications -- see enumeration of integer constants.
	   The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
	 
	   used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
	   If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image.
	*/
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			=1, // 1 = 0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			=2, // 2 = 0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      =3, // 3 = 0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       =4, // 4 = 0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          =5, // 5 = 0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         =6, // 6 = 0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      =7, // 7 = 0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       =8  // 8 = 0th row is on the left, and 0th column is the bottom.
	} ;
	
	switch ( curDeviceOrientation ) {
		case UIDeviceOrientationPortraitUpsideDown: // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM ;
			break ;
		case UIDeviceOrientationLandscapeLeft: // Device oriented horizontally, home button on the right
			if ( _isUsingFrontFacingCamera )
				exifOrientation =PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT ;
			else
				exifOrientation =PHOTOS_EXIF_0ROW_TOP_0COL_LEFT ;
			break ;
		case UIDeviceOrientationLandscapeRight: // Device oriented horizontally, home button on the left
			if ( _isUsingFrontFacingCamera )
				exifOrientation =PHOTOS_EXIF_0ROW_TOP_0COL_LEFT ;
			else
				exifOrientation =PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT ;
			break ;
		case UIDeviceOrientationPortrait: // Device oriented vertically, home button on the bottom
		default:
			exifOrientation =PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP ;
			break ;
	}
	
	imageOptions =[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation] ;
	NSArray *features =[_faceDetector featuresInImage:ciImage options:imageOptions] ;
	
    // Get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc =CMSampleBufferGetFormatDescription(sampleBuffer) ;
	CGRect clap =CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/) ;
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation] ;
	}) ;
}

// Utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
	AVCaptureVideoOrientation result =(AVCaptureVideoOrientation)deviceOrientation ;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result =AVCaptureVideoOrientationLandscapeRight ;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result =AVCaptureVideoOrientationLandscapeLeft ;
	return (result) ;
}

// Utility routine to create a new image with the red square overlay with appropriate orientation
// and return the new composited image which can be saved to the camera roll
- (CGImageRef)newSquareOverlayedImageForFeatures:(NSArray *)features inCGImage:(CGImageRef)backgroundImage withOrientation:(UIDeviceOrientation)orientation frontFacing:(BOOL)isFrontFacing {
	CGRect backgroundImageRect =CGRectMake (0., 0., CGImageGetWidth (backgroundImage), CGImageGetHeight (backgroundImage)) ;
	CGContextRef bitmapContext =CreateCGBitmapContextForSize (backgroundImageRect.size) ;
	CGContextClearRect (bitmapContext, backgroundImageRect) ;
	CGContextDrawImage (bitmapContext, backgroundImageRect, backgroundImage) ;
	CGFloat rotationAngle =0. ;
	
	switch ( orientation ) {
		case UIDeviceOrientationPortrait:
			rotationAngle =-M_PI_2 ;
			break ;
		case UIDeviceOrientationPortraitUpsideDown:
			rotationAngle =M_PI_2 ;
			break ;
		case UIDeviceOrientationLandscapeLeft:
			if ( isFrontFacing )
				rotationAngle =M_PI ;
			else
				rotationAngle =0. ;
			break ;
		case UIDeviceOrientationLandscapeRight:
			if ( isFrontFacing )
				rotationAngle =0. ;
			else
				rotationAngle =M_PI ;
			break ;
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			break ; // Leave the layer in its last known orientation
	}
	UIImage *rotatedSquareImage =[_faceSquare imageRotatedByAngle:rotationAngle] ;
	
    // Features found by the face detector
	for ( CIFaceFeature *ff in features ) {
		CGRect faceRect =[ff bounds] ;
		CGContextDrawImage (bitmapContext, faceRect, [rotatedSquareImage CGImage]) ;
	}
	CGImageRef returnImage =CGBitmapContextCreateImage (bitmapContext) ;
	CGContextRelease (bitmapContext) ;
	
	return (returnImage) ;
}

// Utility routine used after taking a still image to write the resulting image to the camera roll
- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata {
	CFMutableDataRef destinationData =CFDataCreateMutable (kCFAllocatorDefault, 0) ;
	CGImageDestinationRef destination =CGImageDestinationCreateWithData (destinationData, CFSTR("public.jpeg"), 1, NULL) ;
	BOOL success =(destination != NULL) ;
	//require(success, bail) ;
	
	const float JPEGCompQuality =0.85f ; // JPEGHigherQuality
	CFMutableDictionaryRef optionsDict =NULL ;
	CFNumberRef qualityNum =CFNumberCreate (0, kCFNumberFloatType, &JPEGCompQuality) ;
	if ( qualityNum ) {
		optionsDict =CFDictionaryCreateMutable (0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks) ;
		if ( optionsDict )
			CFDictionarySetValue (optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum) ;
		CFRelease (qualityNum) ;
	}
	
	CGImageDestinationAddImage (destination, cgImage, optionsDict) ;
	success =CGImageDestinationFinalize (destination) ;
	
	if ( optionsDict )
		CFRelease (optionsDict) ;
	//require(success, bail) ;
	
	CFRetain (destinationData) ;
	ALAssetsLibrary *library =[ALAssetsLibrary new] ;
	[library writeImageDataToSavedPhotosAlbum:(__bridge id)destinationData metadata:metadata
		completionBlock:^ (NSURL *assetURL, NSError *error) {
			if ( destinationData )
				CFRelease (destinationData) ;
			// Add to our PhotosceneID album
			[library addAsset:assetURL toAlbum:__photosceneid resultBlock:nil failureBlock:nil] ;
		}
	] ;
	library =nil ;

	if ( destinationData )
		CFRelease (destinationData) ;
	if ( destination )
		CFRelease (destination) ;
	return (success) ;
}

// Main action method to take a still image -- if face detection has been turned on and a face has been detected
// the square overlay will be composited on top of the captured image and saved to the camera roll
- (IBAction)takePicture:(id)sender {
	// Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo] ;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation] ;
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation] ;
	[stillImageConnection setVideoOrientation:avcaptureOrientation] ;
	[stillImageConnection setVideoScaleAndCropFactor:_effectiveScale] ;
	
    BOOL doingFaceDetection =_isDetectFaces && (_effectiveScale == 1.0) ;
	
    // Set the appropriate pixel format / image type output setting depending on if we'll need an uncompressed image for
    // the possiblity of drawing the red square over top or if we're just writing a jpeg to the camera roll which is the trival case
    if ( doingFaceDetection )
		[_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]] ;
	else
		[_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey]] ;
	[_stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
		completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
			if ( error ) {
				dispatch_async(dispatch_get_main_queue(), ^(void) {
					UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", @"Take picture failed", (int)[error code]]
																	   message:[error localizedDescription]
																	  delegate:nil
															 cancelButtonTitle:@"Dismiss"
															 otherButtonTitles:nil] ;
					[alertView show] ;
				}) ;
				return ;
			}
			if ( doingFaceDetection ) {
				// Got an image.
				CVPixelBufferRef pixelBuffer =CMSampleBufferGetImageBuffer(imageDataSampleBuffer) ;
				CFDictionaryRef attachments =CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate) ;
				CIImage *ciImage =[[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments] ;
				if ( attachments )
					CFRelease (attachments) ;

				NSDictionary *imageOptions = nil;
				NSNumber *orientation =(__bridge NSNumber *)(CMGetAttachment (imageDataSampleBuffer, kCGImagePropertyOrientation, NULL)) ;
				if ( orientation )
					imageOptions =[NSDictionary dictionaryWithObject:orientation forKey:CIDetectorImageOrientation] ;

				// When processing an existing frame we want any new frames to be automatically dropped
				// queueing this block to execute on the videoDataOutputQueue serial queue ensures this
				// see the header doc for setSampleBufferDelegate:queue: for more information
				dispatch_sync (_videoDataOutputQueue, ^(void) {
					// Get the array of CIFeature instances in the given image with a orientation passed in
					// the detection will be done based on the orientation but the coordinates in the returned features will
					// still be based on those of the image.
					NSArray *features =[_faceDetector featuresInImage:ciImage options:imageOptions] ;
					CGImageRef srcImage =NULL ;
					/*OSStatus err =*/CreateCGImageFromCVPixelBuffer (CMSampleBufferGetImageBuffer (imageDataSampleBuffer), &srcImage) ;
					//check(!err) ;

					CGImageRef cgImageResult =[self newSquareOverlayedImageForFeatures:features
																			 inCGImage:srcImage
																	   withOrientation:curDeviceOrientation
																		   frontFacing:_isUsingFrontFacingCamera] ;
					if ( srcImage )
						CFRelease (srcImage) ;
					CFDictionaryRef attachments =CMCopyDictionaryOfAttachments (kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate) ;
					[self writeCGImageToCameraRoll:cgImageResult withMetadata:(__bridge id)attachments] ;
					if ( attachments )
						CFRelease (attachments) ;
					if ( cgImageResult )
						CFRelease (cgImageResult) ;

				}) ;
				ciImage =nil ;
			} else {
				// Trivial simple JPEG case
				NSData *jpegData =[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer] ;
				CFDictionaryRef attachments =CMCopyDictionaryOfAttachments (kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate) ;
				ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init] ;
				[library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments
					completionBlock:^ (NSURL *assetURL, NSError *error) {
						if ( error ) {
							dispatch_async (dispatch_get_main_queue(), ^(void) {
								UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", @"Save to camera roll failed", (int)[error code]]
																				   message:[error localizedDescription]
																				  delegate:nil
																		 cancelButtonTitle:@"Dismiss"
																		 otherButtonTitles:nil] ;
								[alertView show] ;
							}) ;
							return ;
						}
						// Add to our PhotosceneID album
						[library addAsset:assetURL toAlbum:__photosceneid resultBlock:nil failureBlock:nil] ;
					}
				] ;
				if ( attachments )
					CFRelease (attachments) ;
				library =nil ;
			}
		}
	 ] ;
}

// Perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
		BOOL isCapturingStillImage =[[change objectForKey:NSKeyValueChangeNewKey] boolValue] ;
		if ( isCapturingStillImage ) {
			// Do flash bulb like animation
			_flashView = [[UIView alloc] initWithFrame:[_previewView frame]] ;
			[_flashView setBackgroundColor:[UIColor whiteColor]] ;
			[_flashView setAlpha:0.f] ;
			[[[self view] window] addSubview:_flashView] ;
			[UIView animateWithDuration:.4f
				animations:^ {
					[_flashView setAlpha:1.f] ;
				}
			] ;
		} else {
			[UIView animateWithDuration:.4f
				animations:^ {
					[_flashView setAlpha:0.f] ;
				}
				completion:^ (BOOL finished) {
					[_flashView removeFromSuperview] ;
					_flashView =nil ;
				}
			] ;
		}
	}
}

#pragma mark - Gesture

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] )
		_beginGestureScale =_effectiveScale ;
	return (YES) ;
}

// Scale image depending on users pinch gesture
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
	BOOL allTouchesAreOnThePreviewLayer =YES ;
	NSUInteger numTouches =[recognizer numberOfTouches] ;
	for ( NSUInteger i =0 ; i < numTouches ; ++i ) {
		CGPoint location =[recognizer locationOfTouch:i inView:_previewView] ;
		CGPoint convertedLocation =[_previewLayer convertPoint:location fromLayer:_previewLayer.superlayer] ;
		if ( ! [_previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer =NO ;
			break ;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		_effectiveScale =_beginGestureScale * recognizer.scale ;
		if ( _effectiveScale < 1.0 )
			_effectiveScale = 1.0 ;
		CGFloat maxScaleAndCropFactor =[[_stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor] ;
		if ( _effectiveScale > maxScaleAndCropFactor )
			_effectiveScale = maxScaleAndCropFactor ;
		[CATransaction begin] ;
		[CATransaction setAnimationDuration:.025] ;
		[_previewLayer setAffineTransform:CGAffineTransformMakeScale (_effectiveScale, _effectiveScale)] ;
		[CATransaction commit] ;
	}
}

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)sender {
	[self takePicture:sender] ;
}

- (IBAction)handleSwipeGesture:(UISwipeGestureRecognizer *)sender {
	[self/*.presentedViewController*/ dismissViewControllerAnimated:YES completion:nil] ;
}

#pragma mark - Face detection

// Turn on/off face detection
- (IBAction)toggleFaceDetection:(id)sender {
	_isDetectFaces =[(UISwitch *)sender isOn] ;
	[[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:_isDetectFaces] ;
	if ( !_isDetectFaces ) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			// Clear out any squares currently displaying.
			[self drawFaceBoxesForFeatures:[NSArray array] forVideoBox:CGRectZero orientation:UIDeviceOrientationPortrait] ;
		}) ;
	}
}

// Called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation {
	NSArray *sublayers =[NSArray arrayWithArray : [_previewLayer sublayers]] ;
	NSInteger sublayersCount =[sublayers count], currentSublayer =0 ;
	NSInteger featuresCount =[features count], currentFeature =0 ;
	
	[CATransaction begin] ;
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions] ;
	
	// Hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES] ;
	}
	
	if ( featuresCount ==0 || !_isDetectFaces ) {
		[CATransaction commit] ;
		return ; // Early bail.
	}
	
	CGSize parentFrameSize =[_previewView frame].size ;
	NSString *gravity =[_previewLayer videoGravity] ;
	BOOL isMirrored =[[_previewLayer connection] isVideoMirrored] ;
	CGRect previewBox =[CameraViewController videoPreviewBoxForGravity:gravity
															 frameSize:parentFrameSize
														  apertureSize:clap.size] ;
	
	for ( CIFaceFeature *ff in features ) {
		// Find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect =[ff bounds] ;
		
		// Flip preview width and height
		CGFloat temp =faceRect.size.width ;
		faceRect.size.width =faceRect.size.height ;
		faceRect.size.height =temp ;
		temp =faceRect.origin.x ;
		faceRect.origin.x =faceRect.origin.y ;
		faceRect.origin.y =temp  ;
		// Scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy =previewBox.size.width / clap.size.height ;
		CGFloat heightScaleBy =previewBox.size.height / clap.size.width ;
		faceRect.size.width *=widthScaleBy ;
		faceRect.size.height *=heightScaleBy ;
		faceRect.origin.x *=widthScaleBy ;
		faceRect.origin.y *=heightScaleBy ;
		
		if ( isMirrored )
			faceRect =CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y) ;
		else
			faceRect =CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y) ;
		
		CALayer *featureLayer =nil ;
		// Re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer =[sublayers objectAtIndex:currentSublayer++] ;
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer =currentLayer;
				[currentLayer setHidden:NO] ;
			}
		}
		
		// Create a new one if necessary
		if ( !featureLayer ) {
			featureLayer =[CALayer new] ;
			[featureLayer setContents:(id)[_faceSquare CGImage]] ;
			[featureLayer setName:@"FaceLayer"] ;
			[_previewLayer addSublayer:featureLayer] ;
		}
		[featureLayer setFrame:faceRect] ;
		
		switch ( orientation ) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation (0.)] ;
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation (M_PI)] ;
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation (M_PI_2)] ;
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation (-M_PI_2)] ;
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break ; // Leave the layer in its last known orientation
		}
		currentFeature++ ;
	}
	
	[CATransaction commit] ;
}

// Find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize {
	CGFloat apertureRatio =apertureSize.height / apertureSize.width ;
	CGFloat viewRatio =frameSize.width / frameSize.height ;

	CGSize size =CGSizeZero ;
	if ( [gravity isEqualToString:AVLayerVideoGravityResizeAspectFill] ) {
		if (viewRatio > apertureRatio) {
			size.width =frameSize.width ;
			size.height =apertureSize.width * (frameSize.width / apertureSize.height) ;
		} else {
			size.width =apertureSize.height * (frameSize.height / apertureSize.width) ;
			size.height =frameSize.height ;
		}
	} else if ( [gravity isEqualToString:AVLayerVideoGravityResizeAspect] ) {
		if (viewRatio > apertureRatio) {
			size.width =apertureSize.height * (frameSize.height / apertureSize.width) ;
			size.height =frameSize.height ;
		} else {
			size.width =frameSize.width ;
			size.height =apertureSize.width * (frameSize.width / apertureSize.height) ;
		}
	} else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
		size.width =frameSize.width ;
		size.height =frameSize.height ;
	}

	CGRect videoBox ;
	videoBox.size =size ;
	if (size.width < frameSize.width)
		videoBox.origin.x =(frameSize.width - size.width) / 2 ;
	else
		videoBox.origin.x =(size.width - frameSize.width) / 2 ;

	if ( size.height < frameSize.height )
		videoBox.origin.y =(frameSize.height - size.height) / 2 ;
	else
		videoBox.origin.y =(size.height - frameSize.height) / 2 ;

	return (videoBox) ;
}

@end
