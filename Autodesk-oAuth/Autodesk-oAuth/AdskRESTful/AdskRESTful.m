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
#import <MobileCoreServices/UTType.h>

#import "AdskRESTful.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation AdskRESTfulPlugin
@end

@implementation AdskOauthPlugin

- (id)initWithTokens:(NSDictionary *)tokens {
	if ( (self =[super init]) ) {
		_tokens =[NSMutableDictionary dictionaryWithDictionary:tokens] ;
		// @"oauth_consumer_key" @"oauth_consumer_secret" @"oauth_token" @"oauth_token_secret"
	}
	return (self) ;
}

// https://dev.twitter.com/docs/auth/creating-signature
//
// These values need to be encoded into a single string which will be used later on. The process to build the string is very specific:
//
// Percent encode every key and value to be signed.
// Sort the list of parameters alphabetically[1] by encoded key[2].
// For each key/value pair:
//    Append the encoded key to the output string
//    Append the '=' character to the output string
//    Append the encoded value to the output string
//  If there are more key/value pairs remaining, append a '&' character to the output string.
//  [1] Note: The Oauth spec says to sort lexigraphically, which is the default alphabetical sort for many libraries
//  [2] Note: In case of two parameters with the same encoded key, the Oauth spec says to continue sorting based on value
//
// To encode the HTTP method, base URL, and parameter string into a single string:
//
// Convert the HTTP method to uppercase
// Append the '&' character
// Append Percent encode the URL
// Append the '&' character
// Append Percent encode the parameter string
- (NSString *)sign:(NSString *)method url:(NSURL *)url parameters:(NSDictionary *)parameters {
	// @"oauth_consumer_secret" @"oauth_token_secret"
	NSString *signatureSecret =[NSString stringWithFormat:@"%@&%@",
								[[_tokens objectForKey:@"oauth_consumer_secret"] RFC3986Encode],
								[_tokens objectForKey:@"oauth_token_secret"] ? [[_tokens objectForKey:@"oauth_token_secret"] RFC3986Encode] : @""] ;
	// Convert to UTF-8 & RFC3986 (urlencode)
	NSMutableDictionary *encodedParameters =[NSMutableDictionary dictionary] ;
	for ( NSString *key in parameters ) {
		NSString *value =[parameters objectForKey:key] ;
		[encodedParameters setObject:[value RFC3986Encode] forKey:[key RFC3986Encode]] ;
	}
	// Sort all parameters
	NSArray *sortedKeys =[[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:(__bridge void *)(encodedParameters)] ;
	NSMutableArray *parametersArray =[NSMutableArray array] ;
	for ( NSString *key in sortedKeys )
		[parametersArray addObject:[NSString stringWithFormat:@"%@=%@", key, [encodedParameters objectForKey:key]]] ;
	// Build string to be signed
	NSString *parametersString =[parametersArray componentsJoinedByString:@"&"] ;
	NSString *urlString =[url absoluteString] ; // =[NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]] ;
	NSString *stringToSign =[NSString stringWithFormat:@"%@&%@&%@",
							 [[method uppercaseString] RFC3986Encode],
							 [urlString RFC3986Encode],
							 [parametersString RFC3986Encode]];
	// Sign it
	NSData *data =[AdskRESTful HMAC_SHA1:stringToSign withKey:signatureSecret] ;
	return ([data base64EncodedString]) ;
}

- (NSString *)authorizationHeader:(NSDictionary *)oauth {
	// Convert to UTF-8 & RFC3986 (urlencode)
	NSMutableDictionary *encodedParameters =[NSMutableDictionary dictionary] ;
	for ( NSString *key in oauth ) {
		NSString *value =[oauth objectForKey:key] ;
		[encodedParameters setObject:[value RFC3986Encode] forKey:[key RFC3986Encode]] ;
	}
	// Sort all parameters
	NSArray *sortedKeys =[[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:(__bridge void *)(encodedParameters)] ;
	NSMutableArray *oauthArray =[NSMutableArray array] ;
	for ( NSString *key in sortedKeys ) {
		if ( ![key isEqual:@"oauth_signature"] )
			[oauthArray addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, [encodedParameters objectForKey:key]]] ;
	}
	[oauthArray addObject:[NSString stringWithFormat:@"%@=\"%@\"", @"oauth_signature", [encodedParameters objectForKey:@"oauth_signature"]]] ;
	NSString *oauthHeader =[oauthArray componentsJoinedByString:@", "] ;
	oauthHeader =[NSString stringWithFormat:@"OAuth %@", oauthHeader] ;
	return (oauthHeader) ;
}

- (NSMutableDictionary *)params {
	NSMutableDictionary *oauth =[[NSMutableDictionary alloc] init] ;
	// @"oauth_consumer_key" @"oauth_nonce" @"oauth_signature_method"
	// @"oauth_timestamp" @"oauth_token" @"oauth_version"
	[oauth setObject:[_tokens objectForKey:@"oauth_consumer_key"] forKey:@"oauth_consumer_key"] ;
	[oauth setObject:[AdskRESTful nonce] forKey:@"oauth_nonce"] ;
	[oauth setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"] ;
	[oauth setObject:[AdskRESTful timestamp] forKey:@"oauth_timestamp"] ;
	if ( [_tokens objectForKey:@"oauth_token"] )
		[oauth setObject:[_tokens objectForKey:@"oauth_token"] forKey:@"oauth_token"] ;
	[oauth setObject:@"1.0" forKey:@"oauth_version"] ;
	if ( [_tokens objectForKey:@"oauth_session_handle"] )
		[oauth setObject:[_tokens objectForKey:@"oauth_session_handle"] forKey:@"oauth_session_handle"] ;
	return (oauth) ;
}

@end

@implementation AdskRESTfulResponse

- (BOOL)isOk {
	if ( error != nil )
		return (NO) ;
	NSString *st =[self string] ;
	return ([st rangeOfString:@"<error>"].length == 0 && [st rangeOfString:@"<Error>"].length == 0) ;
}

- (NSString *)string {
	return ([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]) ;
}

@end

@implementation AdskRESTful

- (id)initWithBaseURL:(NSString *)baseURL options:(NSDictionary *)options {
	if ( (self =[super init]) ) {
		_url =[[NSURL alloc] initWithString:baseURL] ;
		_options =[[NSDictionary alloc] initWithDictionary:options copyItems:YES] ;
	}
	return (self) ;
}

- (void)addSubscriber:(AdskRESTfulPlugin *)plugin {
	_credential =plugin ;
}

- (void)clearParameters {
	_parameters =nil ;
}

- (void)addParameters:(NSDictionary *)ununcodedParameters {
	if ( _parameters == nil )
		_parameters =[NSMutableDictionary dictionaryWithDictionary:ununcodedParameters] ;
	else
		[_parameters addEntriesFromDictionary:ununcodedParameters] ;
}

- (void)clearPostFiles {
	_files =nil ;
}

- (void)addPostFiles:(NSDictionary *)files {
	if ( _files == nil )
		_files =[NSMutableDictionary dictionaryWithDictionary:files] ;
	else
		[_files addEntriesFromDictionary:files] ;
}

- (void)clearAllParameters {
	[self clearParameters] ;
	[self clearPostFiles] ;
}

- (NSURLRequest *)buildRequest:(NSString *)method url:(NSString *)url headers:(NSDictionary *)headers {
	NSURL *rUrl ;
	if ( [[[url Right:4] lowercaseString] isEqual:@"http"] )
		rUrl =[[NSURL alloc] initWithString:url] ;
	else
		rUrl =[[NSURL alloc] initWithString:url relativeToURL:_url] ;
	NSLog(@"%@ url is %@", method, [rUrl absoluteString]) ;
	
	// If default headers are provided, then merge them under any explicitly provided headers for the request
	NSMutableDictionary *reqHeaders =[NSMutableDictionary dictionary] ;
	if ( headers != nil )
		[reqHeaders addEntriesFromDictionary:headers] ;
	
	// Get credential (Oauth) parameters
	// Get query (GET) and/or body (POST) + Credential (Oauth) parameters
	NSMutableDictionary *oauth =[_credential params] ;
	// Combine Oauth & parameters
	NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithDictionary:oauth] ;
	//if ( _files == nil || [_files count] == 0 ) // http://tools.ietf.org/html/rfc5849#section-3.4.1.3 << Oauth 1.0a
		[dict addEntriesFromDictionary:_parameters] ;

	[oauth setObject:[_credential sign:method url:rUrl parameters:dict] forKey:@"oauth_signature"] ;
	[reqHeaders setObject:[_credential authorizationHeader:oauth] forKey:@"Authorization"] ;
	NSLog(@"Authorization: %@", [reqHeaders objectForKey:@"Authorization"]) ;
	[reqHeaders setObject:@"AdskRESTful/1.0" forKey:@"User-Agent"] ;
	//[reqHeaders setObject:nil/*@"gzip, deflate"*/ forKey:@"Accept-Encoding"] ;
	//[reqHeaders setObject:nil forKey:@"Accept-Language"] ;
	//[reqHeaders setObject:nil forKey:@"Accept"] ;
	//[reqHeaders setObject:nil forKey:@"Pragma"] ;
	
	if ( [[method lowercaseString] isEqual:@"get"] ) {
		// Convert to UTF-8 & RFC3986 (urlencode)
		NSMutableArray *encodedParameters =[NSMutableArray array] ;
		for ( NSString *key in _parameters ) {
			NSString *value =[_parameters objectForKey:key] ;
			[encodedParameters addObject:[NSString stringWithFormat:@"%@=%@", [key RFC3986Encode], [value RFC3986Encode]]] ;
		}
		NSString *queryString =[encodedParameters componentsJoinedByString:@"&"] ;
		NSString *st =[[NSString alloc] initWithFormat:@"%@%@%@",
					   [rUrl absoluteString],
					   [[rUrl absoluteString] rangeOfString:@"?"].length > 0 ? @"&" : @"?",
					   queryString] ;
		rUrl =[[NSURL alloc] initWithString:st] ;
	}
    NSMutableURLRequest *req =[NSMutableURLRequest requestWithURL:rUrl
													  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
												  timeoutInterval:100] ;
    [req setHTTPMethod:[method uppercaseString]] ;
	for ( NSString *key in reqHeaders )
		[req setValue:[reqHeaders objectForKey:key] forHTTPHeaderField:key] ;
	req.HTTPShouldHandleCookies =NO ;

	if (   [[method lowercaseString] isEqual:@"post"]
		|| [[method lowercaseString] isEqual:@"put"]
		|| [[method lowercaseString] isEqual:@"delete"]
	) {
		NSMutableData *body =[[NSMutableData alloc] init] ;
		if ( false && (_files == nil || [_files count] == 0) && [_parameters count] ) {
			// Convert to UTF-8 & RFC3986 (urlencode)
			NSMutableArray *encodedParameters =[NSMutableArray array] ;
			for ( NSString *key in _parameters ) {
				NSString *value =[_parameters objectForKey:key] ;
				[encodedParameters addObject:[NSString stringWithFormat:@"%@=%@", [key RFC3986Encode], [value RFC3986Encode]]] ;
			}
			NSString *queryString =[encodedParameters componentsJoinedByString:@"&"] ;
			body =[NSMutableData dataWithData:[queryString dataUsingEncoding:NSUTF8StringEncoding]] ;
			
			[req setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"] ;
			[req setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"] ;
		} else {
			NSString *boundaryCode =[[[AdskRESTful nonce] Right:12] lowercaseString] ;
			NSString *boundary =[NSString stringWithFormat:@"----------------------------%@", boundaryCode] ;
			[req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"] ;
			
			for ( NSString *key in _parameters ) {
				NSString *value =[_parameters objectForKey:key] ;
				[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]] ;
				[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [key RFC3986Encode]] dataUsingEncoding:NSUTF8StringEncoding]] ;
				[body appendData:[[NSString stringWithFormat:@"%@\r\n", [value RFC3986Encode]] dataUsingEncoding:NSUTF8StringEncoding]] ;
			}
			int i =0 ;
			for ( NSString *key in _files ) {
				//NSData *value =[NSData dataWithContentsOfURL:value] ;
				NSData *value =[_files objectForKey:key] ;
				NSString *keyName =[NSString stringWithFormat:@"file[%d]", i] ;
				NSString *contentType =[AdskRESTful fileMIMEType:key] ;
				//NSString *contentType =@"image/jpeg" ;
				[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]] ;
				[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", keyName, [key RFC3986Encode]] dataUsingEncoding:NSUTF8StringEncoding]] ;
				[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]] ;
				//[body appendData:[[NSString stringWithFormat:@"Content-Length: %d\r\n\r\n", data.length] dataUsingEncoding:NSUTF8StringEncoding]] ;
				[body appendData:value] ;
				[body appendData:[[[NSString alloc] initWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]] ;
				i++ ;
			}
			
			[body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]] ;
			[req setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"] ;
		}
		[req setHTTPBody:body] ;
	}
	return (req) ;
}

- (NSURLRequest *)get:(NSString *)url headers:(NSDictionary *)headers {
	return ([self buildRequest:@"GET" url:url headers:headers]) ;
}

- (NSURLRequest *)post:(NSString *)url headers:(NSDictionary *)headers {
	return ([self buildRequest:@"POST" url:url headers:headers]) ;
}

- (NSURLRequest *)put:(NSString *)url headers:(NSDictionary *)headers {
	return ([self buildRequest:@"PUT" url:url headers:headers]) ;
}

- (NSURLRequest *)delete:(NSString *)url headers:(NSDictionary *)headers {
	return ([self buildRequest:@"DELETE" url:url headers:headers]) ;
}

- (AdskRESTfulResponse *)send:(NSURLRequest *)request {
	AdskRESTfulResponse *response =[[AdskRESTfulResponse alloc] init] ;
	response->error =nil ;
	NSURLResponse *urlr =response->urlResponse ;
	NSError *errr =response->error ;
	response->data =[NSURLConnection
					 sendSynchronousRequest:request
					 returningResponse:&urlr
					 error:&errr] ;
	return (response) ;
}

+ (NSString *)timestamp {
	return ([NSString stringWithFormat:@"%lu", (unsigned long)[[NSDate date] timeIntervalSince1970]]) ;
}

+ (NSString *)nonce {
	CFUUIDRef guid =CFUUIDCreate (kCFAllocatorDefault) ;
	CFStringRef st =CFUUIDCreateString (kCFAllocatorDefault, guid) ;
	CFRelease (guid) ;
	return ((__bridge NSString *)st) ;
}

+ (NSData *)HMAC_SHA1:(NSString *)data withKey:(NSString *)key {
    unsigned char buf [CC_SHA1_DIGEST_LENGTH] ;
    CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf) ;
    return ([NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH]) ;
}

+ (NSString *)fileMIMEType:(NSString*)filename {
    CFStringRef UTI =UTTypeCreatePreferredIdentifierForTag (kUTTagClassFilenameExtension, (__bridge CFStringRef)[filename pathExtension], NULL) ;
    CFStringRef MIMEType =UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType) ;
    CFRelease (UTI) ;
    return ((__bridge NSString *)MIMEType) ;
}

+ (NSMutableDictionary *)ParseQueryString:(NSString *)queryString {
	NSMutableDictionary *params =[[NSMutableDictionary alloc] init] ;
	NSArray *split =[queryString componentsSeparatedByString:@"&"] ;
	for ( NSString *str in split ) {
		NSArray *split2 =[str componentsSeparatedByString:@"="] ;
		if ( split.count > 1 )
			[params setObject:[split2 [1] RFC3986Decode] forKey:[split2 [0] RFC3986Decode]] ;
	}
	return (params) ;
}

@end

NSInteger SortParameter (NSString *key1, NSString *key2, void *context) {
    NSComparisonResult result =[key1 compare:key2] ;
    if ( result == NSOrderedSame ) { //- Oauth specification says to compare values in case of duplicated keys
        NSDictionary *dict =(__bridge NSDictionary *)context ;
        NSString *value1 =[dict objectForKey:key1] ;
        NSString *value2 =[dict objectForKey:key2] ;
        return ([value1 compare:value2]) ;
    }
    return (result) ;
}
