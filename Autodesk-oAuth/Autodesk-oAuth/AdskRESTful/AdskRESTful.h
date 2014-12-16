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
//  Created by Cyrille Fauvel - October 17th, 2013
//
#pragma once

#import "AdskNSString+Additions.h"
#import "NSData+Base64.h"

@interface AdskRESTfulPlugin : NSObject {
	@public
	NSMutableDictionary *_tokens ;
}

- (id)initWithTokens:(NSDictionary *)tokens ;
- (NSString *)sign:(NSString *)method url:(NSURL *)url parameters:(NSDictionary *)parameters ;
- (NSString *)authorizationHeader:(NSDictionary *)oauth ;
- (NSMutableDictionary *)params ;

@end

@interface AdskOauthPlugin : AdskRESTfulPlugin {
}

- (id)initWithTokens:(NSDictionary *)tokens ;
- (NSString *)sign:(NSString *)method url:(NSURL *)url parameters:(NSDictionary *)parameters ;
- (NSString *)authorizationHeader:(NSDictionary *)oauth ;
- (NSMutableDictionary *)params ;

@end

@interface AdskRESTfulResponse : NSObject {
	@public
	NSURLResponse *urlResponse ;
	NSError *error ;
	NSData *data ;
}

- (BOOL)isOk ;
- (NSString *)string ;

@end

@interface AdskRESTful : NSObject {
	NSURL *_url ;
	NSDictionary *_options ;
    NSMutableDictionary *_parameters ;
	NSMutableDictionary *_files ;
	
	AdskRESTfulPlugin *_credential ;
}

- (id)initWithBaseURL:(NSString *)baseURL options:(NSDictionary *)options ;
- (void)addSubscriber:(AdskRESTfulPlugin *)plugin ;
- (void)clearParameters ;
- (void)addParameters:(NSDictionary *)ununcodedParameters ;
- (void)clearPostFiles ;
- (void)addPostFiles:(NSDictionary *)files ;
- (void)clearAllParameters ;

//- (NSURLRequest *)buildRequest:(NSString *)method url:(NSString *)url headers:(NSDictionary *)headers ;
- (NSURLRequest *)get:(NSString *)url headers:(NSDictionary *)headers ;
- (NSURLRequest *)post:(NSString *)url headers:(NSDictionary *)headers ;
- (NSURLRequest *)put:(NSString *)url headers:(NSDictionary *)headers ;
- (NSURLRequest *)delete:(NSString *)url headers:(NSDictionary *)headers ;
- (AdskRESTfulResponse *)send:(NSURLRequest *)request ;

+ (NSString *)timestamp ;
+ (NSString *)nonce ;
+ (NSData *)HMAC_SHA1:(NSString *)data withKey:(NSString *)key ;
+ (NSString *)fileMIMEType:(NSString*)filename ;
+ (NSMutableDictionary *)ParseQueryString:(NSString *)queryString ;

@end

NSInteger SortParameter (NSString *key1, NSString *key2, void *context) ;
