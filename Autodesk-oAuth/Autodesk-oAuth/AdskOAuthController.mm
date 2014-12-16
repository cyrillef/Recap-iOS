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
#import "AdskOAuthController.h"
#import <RestKit/RestKit.h>
#import <AFOAuth1Client/AFOAuth1Client.h>

//- WARNING: Out-of-band authorization is shown here only for educational purposes and should only be used
//- if for some reason you cannot use in-band authorization.
//- In case of out-of-band authorization the web page will provide a PIN that the user will need to paste in
//- the message box of the iOS app

@interface AdskOAuthController ()
@end

@implementation AdskOAuthController

#pragma mark - View Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ( (self =[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
		// Custom initialization
	}
	return (self) ;
}


- (void)viewDidLoad {
	_webView =[[UIWebView alloc] initWithFrame:[self view].bounds] ;
	_webView.delegate =self ;
	_webView.autoresizingMask =(UIViewAutoresizingFlexibleWidth |
								UIViewAutoresizingFlexibleLeftMargin |
								UIViewAutoresizingFlexibleRightMargin) ;
	[self.view addSubview:_webView] ;
	[super viewDidLoad] ;
}

#pragma mark - oAuth Protocol

+ (void)setApplicationKeys:(NSString *)key secret:(NSString *)secret {
	_CONSUMER_KEY =key ;
	_CONSUMER_SECRET =secret ;
}

+ (void)setApplicationPaths:(NSString *)host request:(NSString *)request authorize:(NSString *)authorize access:(NSString *)access invalidate:(NSString *)invalidate allow:(NSString *)allow {
	_OAUTH_HOST =host ;
	_OAUTH_REQUESTTOKEN =request ;
	_OAUTH_AUTHORIZE =authorize ;
	_OAUTH_ACCESSTOKEN =access ;
	_OAUTH_INVALIDATETOKEN =invalidate ;
	_OAUTH_ALLOW =allow ;
}

/*- (IBAction)startLogin:(id)sender {
	if ( !_accessToken ) {
		if ( [self RequestToken] ) // Leg 1
			[self Authorize] ; // Leg 2
		
		// Leg 3
		// If Authorize succeeds, then in case of
		//   out-of-band authorization the /OAuth/AccessToken will be called from UIAlertView:didDismissWithButtonIndex,
		//   in-band authorization it will be called from UIWebView:webViewDidFinishLoad
	} else {
		[self InvalidateToken] ;
	}
}*/

//- First Leg: The first step of authentication is to request a token
- (void)RequestToken:(void (^)())success failure:(void (^)(NSError *error))failure {
	_success =success ;
	_failure =failure ;
	
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	[defaults removeObjectForKey:@"oauth_token"] ;
	[defaults removeObjectForKey:@"oauth_token_secret"] ;
	[defaults removeObjectForKey:@"oauth_session_handle"] ;
	[defaults removeObjectForKey:@"x_oauth_user_name"] ;
	[defaults removeObjectForKey:@"x_oauth_user_guid"] ;
	[defaults synchronize] ;

	AFOAuth1Client *oauthClient =[[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:_OAUTH_HOST] key:_CONSUMER_KEY secret:_CONSUMER_SECRET] ;
	[oauthClient acquireOAuthRequestTokenWithPath:_OAUTH_REQUESTTOKEN callbackURL:nil /*[NSURL URLWithString:_OAUTH_ALLOW]*/ accessMethod:@"POST" scope:nil
		success:^ (AFOAuth1Token *requestToken, id responseObject) {
			NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
			[defaults setObject:requestToken.key forKey:@"oauth_token"] ;
			[defaults setObject:requestToken.secret forKey:@"oauth_token_secret"] ;
			[defaults synchronize] ;

			[self Authorize] ;
		}
		failure:^ (NSError *error) {
			NSLog(@"Failure! Could not get request token! Maybe the credentials are incorrect?") ;
			NSLog(@"Error: %@", error) ;
			if ( _failure )
				_failure (error) ;
		}
	] ;
}

//- Second Leg: The second step is to authorize the user using the Autodesk login server
- (void)Authorize {
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	NSString *path =[NSString stringWithFormat:@"%@%@?oauth_token=%@&viewmode=mobile", _OAUTH_HOST, _OAUTH_AUTHORIZE, [defaults objectForKey:@"oauth_token"]] ;
	
	// In case of out-of-band authorization, let's show the authorization page which will provide the user with a PIN
	// in the default browser. Then here in our app request the user to type in that PIN.
	if ( [self isOOB] ) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:path]] ;
		UIAlertView *alert =[[UIAlertView alloc]
							 initWithTitle:@"Authorization PIN"
							 message:@"Please type here the authorization PIN!"
							 delegate:self
							 cancelButtonTitle:@"Done"
							 otherButtonTitles:nil] ;
		alert.alertViewStyle =UIAlertViewStylePlainTextInput ;
		[alert show] ;
	} else {
		// Otherwise let's load the page in our web viewer so that
		// we can catch the URL that it gets redirected to
		NSURLRequest *req =[NSURLRequest
							requestWithURL:[NSURL URLWithString:path]
							cachePolicy:NSURLRequestUseProtocolCachePolicy
							timeoutInterval:100] ;
		[self->_webView loadRequest:req] ;
	}
}

//- Third leg: The third step is to authenticate using the request tokens
//- Once you get the access token and access token secret you need to use those to make your further REST calls
//- Same in case of refreshing the access tokens or invalidating the current session. To do that we need to pass
//- in the acccess token and access token secret as the accessToken and tokenSecret parameter of the
//- [AdskRESTful URLRequestForPath] function
+ (void)AccessToken:(BOOL)refresh PIN:(NSString *)PIN success:(void (^)())success failure:(void (^)(NSError *error))failure {
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	AFOAuth1Token *tokens =[[AFOAuth1Token alloc] initWithKey:[defaults objectForKey:@"oauth_token"]
															 secret:[defaults objectForKey:@"oauth_token_secret"]
															session:[defaults objectForKey:@"oauth_session_handle"]
														 expiration:nil
														  renewable:YES
	] ;
	
	// If we used out-of-band authorization then we got a PIN that we need now
	if ( PIN != nil )
		tokens.verifier =PIN ;
	
	AFOAuth1Client *oauthClient =[[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:_OAUTH_HOST] key:_CONSUMER_KEY secret:_CONSUMER_SECRET] ;
	[oauthClient acquireOAuthAccessTokenWithPath:_OAUTH_ACCESSTOKEN requestToken:tokens accessMethod:@"POST"
		success:^ (AFOAuth1Token *accessToken, id responseObject) {
			// [@"oauth_token"] [@"oauth_token_secret"] [@"oauth_session_handle"] [@"oauth_expires_in"] [@"oauth_authorization_expires_in"]
			// If session handle is not null then we got the tokens
			if ( accessToken.session != nil ) {
				NSLog(refresh ? @"Success! Managed to refresh token!" : @"Success! Managed to log in and get access token!") ;
				NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
				[defaults setObject:accessToken.key forKey:@"oauth_token"] ;
				[defaults setObject:accessToken.secret forKey:@"oauth_token_secret"] ;
				[defaults setObject:accessToken.session forKey:@"oauth_session_handle"] ;
				[defaults setObject:accessToken.userInfo [@"x_oauth_user_name"] forKey:@"x_oauth_user_name"] ;
				[defaults setObject:accessToken.userInfo [@"x_oauth_user_guid"] forKey:@"x_oauth_user_guid"] ;
				[defaults synchronize] ;
				NSLog(@"Data saved") ;
				if ( success )
					success () ;
			} else if ( failure ) {
				failure (nil) ;
			}
		}
		failure:^ (NSError *error) {
			NSLog (refresh ? @"Failure! Could not refresh token!" : @"Failure! Could not get access token!") ;
			NSLog(@"Error: %@", error) ;
			if ( failure )
				failure (error) ;
		}
	 ] ;
}

//- If we do not want to use the service anymore then
//- the best thing is to log out, i.e. invalidate the tokens we got
+ (void)InvalidateToken:(void (^)())success failure:(void (^)(NSError *error))failure {
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	AFOAuth1Token *_accessToken =[[AFOAuth1Token alloc] initWithKey:[defaults objectForKey:@"oauth_token"]
															 secret:[defaults objectForKey:@"oauth_token_secret"]
															session:[defaults objectForKey:@"oauth_session_handle"]
														 expiration:nil
														  renewable:YES
	] ;
	
	AFOAuth1Client *oauthClient =[[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:_OAUTH_HOST] key:_CONSUMER_KEY secret:_CONSUMER_SECRET] ;
	[oauthClient acquireOAuthAccessTokenWithPath:_OAUTH_INVALIDATETOKEN requestToken:_accessToken accessMethod:@"POST"
		 success:^ (AFOAuth1Token *accessToken, id responseObject) {
			 NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
			 [defaults removeObjectForKey:@"oauth_token"] ;
			 [defaults removeObjectForKey:@"oauth_token_secret"] ;
			 [defaults removeObjectForKey:@"oauth_session_handle"] ;
			 [defaults removeObjectForKey:@"x_oauth_user_name"] ;
			 [defaults removeObjectForKey:@"x_oauth_user_guid"] ;
			 [defaults synchronize] ;
			 NSLog(@"Success! Managed to log out!") ;
			 if ( success )
				 success () ;
		 }
		 failure:^ (NSError *error) {
			 NSLog(@"Failure! Could not log out!") ;
			 NSLog(@"Error: %@", error) ;
			 if ( failure )
				 failure (error) ;
		 }
	 ] ;
}

//- When a new URL is being shown in the browser then we can check the URL
//- This is needed in case of in-band authorization which will redirect us to a given
//- URL (O2_ALLOW) in case of success
- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	// In case of out-of-band login we do not need to check the callback URL
	// Instead we'll need the PIN that the webpage will provide for the user
	if ( [self isOOB] )
		return ;
	// Let's check if we got redirected to the correct page
	if ( [self isAuthorizeCallBack] )
		[AdskOAuthController AccessToken:NO PIN:nil success:_success failure:_failure] ;
}

//- Check if the URL is O2_ALLOW, which means that the user could log in successfully
- (BOOL)isAuthorizeCallBack {
	NSString *fullUrlString =self->_webView.request.URL.absoluteString ;
	if ( !fullUrlString )
		return (NO) ;
	NSArray *arr =[fullUrlString componentsSeparatedByString:@"?"] ;
	if ( !arr || arr.count != 2 )
		return (NO) ;
	// If we were redirected to the O2_ALLOW URL then the user could log in successfully
	if ( [arr [0] isEqualToString:_OAUTH_ALLOW] )
		return (YES) ;
	// If we got to this page then probably there is an issue
	if ( [arr [0] isEqualToString:_OAUTH_AUTHORIZE] ) {
		// If the page contains the word "oauth_problem" then there is clearly a problem
		NSString *content =[self->_webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"] ;
		if ( [content rangeOfString:@"oauth_problem"].location != NSNotFound )
			NSLog(@"Failure! Could not log in! Try again!") ;
	}
	return (NO) ;
}

//- In case of out-of-band authorization this is where we continue once the user got the PIN
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[AdskOAuthController AccessToken:NO PIN:[[alertView textFieldAtIndex:0] text] success:_success failure:_failure] ;
}

//- Checks if we should use out-of-band authorization
- (BOOL)isOOB {
    // Return false always in this example
    return (NO) ;
}

@end
