//  (C) Copyright 2013 by Autodesk, Inc.
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
//  Created by Cyrille Fauvel on 10/16/13.
//
#pragma once

#import <Foundation/Foundation.h>

@interface NSString (AdskNSStringAdditions)

- (NSString *)RFC3986Encode ;
- (NSString *)RFC3986Decode ;
- (NSString *)Left:(NSUInteger)x ;
- (NSString *)Right:(NSUInteger)x ;

@end
