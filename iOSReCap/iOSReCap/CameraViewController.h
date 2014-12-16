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
//
#pragma once

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// Used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext =@"AVCaptureStillImageIsCapturingStillImageContext" ;

@interface CameraViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
	BOOL _isUsingFrontFacingCamera, _isDetectFaces ;
	CGFloat _effectiveScale, _beginGestureScale ;
	UIImage *_faceSquare ;
	CIDetector *_faceDetector ;
	
	AVCaptureVideoDataOutput *_videoDataOutput ;
	AVCaptureStillImageOutput *_stillImageOutput ;
	AVCaptureVideoPreviewLayer *_previewLayer ;
	
	IBOutlet UIView *_previewView ;
	UIView *_flashView ;

	dispatch_queue_t _videoDataOutputQueue ;
}

@property (strong, nonatomic) NSString *_photosceneid ;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil ;
- (void)viewDidLoad ;
- (void)didReceiveMemoryWarning ;
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender ;
- (BOOL)shouldAutorotate ;
- (NSUInteger)supportedInterfaceOrientations ;

- (void)setupAVCapture ;
- (void)teardownAVCapture ;
- (IBAction)switchCameras:(id)sender ;

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection ;
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation ;
- (CGImageRef)newSquareOverlayedImageForFeatures:(NSArray *)features inCGImage:(CGImageRef)backgroundImage withOrientation:(UIDeviceOrientation)orientation frontFacing:(BOOL)isFrontFacing  ;
- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata ;
- (IBAction)takePicture:(id)sender ;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context ;

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer ;
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)sender ;
- (IBAction)handleTapGesture:(UITapGestureRecognizer *)sender ;
- (IBAction)handleSwipeGesture:(UISwipeGestureRecognizer *)sender ;

- (IBAction)toggleFaceDetection:(id)sender ;
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation ;
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize ;

@end
