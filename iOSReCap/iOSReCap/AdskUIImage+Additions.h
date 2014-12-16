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

@interface UIImage (AdskNSStringAdditions)

- (UIImage *)imageRotatedByAngle:(CGFloat)angle ;

@end
