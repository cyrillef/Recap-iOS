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

#import "AdskObjParser.h"
#import "AdskEAGLView.h"

@interface AdskObjViewerController : AdskObjViewerBaseController {
@private
	//@public
	float _lastScale ;
	CATransform3D _currentCalculatedMatrix ;
	
	UIProgressView *renderingProgressIndicator ;
	UILabel *renderingActivityLabel ;
	
	dispatch_queue_t _objLoaderQueue ;
	dispatch_semaphore_t _objLoaderSemaphore, _objViewerSemaphore ;
}

@property (weak, nonatomic) IBOutlet AdskEAGLView *_eaglView ;
@property (strong, nonatomic) AdskObjParser *_myMesh ;
@property (copy, nonatomic) NSString *_path ;
@property (copy, nonatomic) NSString *_photosceneid ;

- (id)init ;
- (id)initWithObj:(NSString *)path photosceneid:(NSString *)photosceneid ;
- (id)initWithParser:(AdskObjParser *)parser ;
- (void)initialize ;
+ (id)createAdskEAGLView ;
- (void)loadView ;
- (void)viewDidLoad ;
- (void)viewDidAppear:(BOOL)animated ;

- (void)loadObj:(NSString *)path photosceneid:(NSString *)photosceneid ;

- (void)setupView:(AdskEAGLView *)view ;

- (void)drawView:(AdskEAGLView *)view ;

- (void)setupGesture:(AdskEAGLView *)view ;
- (void)stopAnimation:(UITapGestureRecognizer *)sender ;
- (void)scaleMesh:(UIPinchGestureRecognizer *)sender ;
- (void)rotatePanMesh:(UIPanGestureRecognizer *)sender ;
- (void)translatePanMesh:(UIPanGestureRecognizer *)sender ;
- (void)rotateMesh:(UIRotationGestureRecognizer *)sender ;
- (void)screenshot:(UITapGestureRecognizer *)sender ;

- (void)showRenderingIndicator:(NSNotification *)note ;
- (void)updateRenderingIndicator:(NSNotification *)note ;
- (void)hideRenderingIndicator:(NSNotification *)note ;

@end
