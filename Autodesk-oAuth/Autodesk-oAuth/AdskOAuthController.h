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

static NSString *_OAUTH_HOST ;
static NSString *_OAUTH_REQUESTTOKEN ;
static NSString *_OAUTH_AUTHORIZE ;
static NSString *_OAUTH_ACCESSTOKEN ;
static NSString *_OAUTH_INVALIDATETOKEN ;
static NSString *_OAUTH_ALLOW ;

static NSString *_CONSUMER_KEY ;
static NSString *_CONSUMER_SECRET ;

typedef void (^AdskOAuthControllerSuccess) () ;
typedef void (^AdskOAuthControllerError) (NSError *error) ;

@interface AdskOAuthController : UIViewController<UIWebViewDelegate> {
	UIWebView *_webView ;
	AdskOAuthControllerSuccess _success ;
	AdskOAuthControllerError _failure ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil ;
//- (void)viewDidLoad ;

+ (void)setApplicationKeys:(NSString *)key secret:(NSString *)secret ;
+ (void)setApplicationPaths:(NSString *)host request:(NSString *)request authorize:(NSString *)authorize access:(NSString *)access invalidate:(NSString *)invalidate allow:(NSString *)allow ;
//- (IBAction)startLogin:(id)sender ;
//- (IBAction)refreshToken:(id)sender ;

- (void)RequestToken:(void (^)())success failure:(void (^)(NSError *error))failure ;
- (void)Authorize ;
+ (void)AccessToken:(BOOL)refresh PIN:(NSString *)PIN success:(void (^)())success failure:(void (^)(NSError *error))failure ;
+ (void)InvalidateToken:(void (^)())success failure:(void (^)(NSError *error))failure ;
//- (void)webViewDidFinishLoad:(UIWebView *)aWebView ;
//- (BOOL)isAuthorizeCallBack ;
//- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex ;
//- (BOOL)isOOB ;

@end
