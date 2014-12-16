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
#import "AdskUIImage+Additions.h"

@implementation UIImage (AdskNSStringAdditions)

- (UIImage *)imageRotatedByAngle:(CGFloat)angle {
	// Calculate the size of the rotated view's containing box for our drawing space
	UIView *rotatedViewBox =[[UIView alloc] initWithFrame:CGRectMake (0, 0, self.size.width, self.size.height)] ;
	rotatedViewBox.transform =CGAffineTransformMakeRotation (angle) ;
	CGSize rotatedSize =rotatedViewBox.frame.size ;
	
	// Create the bitmap context
	UIGraphicsBeginImageContext (rotatedSize) ;
	CGContextRef bitmap =UIGraphicsGetCurrentContext () ;
	
	// Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM (bitmap, rotatedSize.width / 2, rotatedSize.height / 2) ;
	
	// Rotate the image context
	CGContextRotateCTM (bitmap, angle) ;
	
	// Now, draw the rotated/scaled image into the context
	CGContextScaleCTM (bitmap, 1.0, -1.0) ;
	CGContextDrawImage (bitmap, CGRectMake (-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]) ;
	
	UIImage *newImage =UIGraphicsGetImageFromCurrentImageContext () ;
	UIGraphicsEndImageContext () ;
	return (newImage) ;
}

@end
