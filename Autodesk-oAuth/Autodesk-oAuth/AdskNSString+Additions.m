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
#import "AdskNSString+Additions.h"

@implementation NSString (AdskNSStringAdditions)

- (NSString *)RFC3986Encode { // UTF-8 encodes prior to URL encoding
    NSMutableString *result =[NSMutableString string] ;
    const char *p =[self UTF8String] ;
    unsigned char c ;
    for ( ; (c =*p) ; p++ ) {
        switch ( c ) {
            case '0' ... '9':
            case 'A' ... 'Z':
            case 'a' ... 'z':
            case '.':
            case '-':
            case '~':
            case '_':
                [result appendFormat:@"%c", c] ;
                break ;
            default:
                [result appendFormat:@"%%%02X", c] ;
				break ;
        }
    }
    return (result) ;
}

- (NSString *)RFC3986Decode {
    NSString *result =[(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "] ;
    result =[result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
    return (result) ;
}

- (NSString *)Left:(NSUInteger)x {
	NSString *substring =self ;
	if ( [self length] > x )
		substring =[self substringWithRange:NSMakeRange (0, x - 1)] ;
	return (substring) ;
}

- (NSString *)Right:(NSUInteger)x {
	NSString *substring =self ;
	if ( [self length] > x )
		substring =[self substringFromIndex:[self length] - x] ;
	return (substring) ;
}

@end
