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
#import "AdskReCap.h"

#import <RestKit/RestKit.h>

@implementation AdskReCapResponse
@end

@implementation AdskReCap {
	RKObjectManager *_recapClient ;
}

#pragma mark - ReCap API setup

- (id)initWithUrlAndClientID:(NSString *)apiURL clientID:(NSString *)clientID oAuthClient:(AFHTTPClient *)oAuthClient {
	if ( self =[super init] ) {
		_ReCapAPIURL =apiURL ;
		_ReCapClientID =clientID ;
		[self configureRestKit:oAuthClient] ;
	}
	return (self) ;
}

- (void)configureRestKit:(AFHTTPClient *)oAuthClient {
    // Initialize RestKit
	_recapClient =[[RKObjectManager alloc] initWithHTTPClient:oAuthClient /*client*/] ;
	[RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/html"] ;
	//[RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/xml"] ;
	[RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/json"] ;
	[RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/x-json"] ;
	//[RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"application/xml"] ;
	[RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"application/json"] ;
	[_recapClient setAcceptHeaderWithMIMEType:@"text/json"] ;
	[_recapClient setAcceptHeaderWithMIMEType:@"text/x-json"] ;
	[_recapClient setAcceptHeaderWithMIMEType:RKMIMETypeJSON] ; // @"application/json"
    // Setup object mappings
    RKObjectMapping *recapResponseMapping =[RKObjectMapping mappingForClass:[AdskReCapResponse class]] ;
    [recapResponseMapping addAttributeMappingsFromDictionary:@{ @"Resource" : @"_resource" }] ;
    // Register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor =[RKResponseDescriptor responseDescriptorWithMapping:recapResponseMapping
																						   method:RKRequestMethodAny
																					  pathPattern:nil // @"service/date" for example, nil for all
																						  keyPath:nil
																					  statusCodes:[NSIndexSet indexSetWithIndex:200]
											   ] ;
    [_recapClient addResponseDescriptor:responseDescriptor] ;
}

- (void)configureDefaults:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	_defaultSuccess =success ;
	_defaultFailure =failure ;
}

#pragma mark - ReCap API interface

- (void)ServerTime:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *queryParams =@{
								 @"clientID" : _ReCapClientID,
							 (json ? @"json" : @"xml") : @"1"
	} ;
	[_recapClient getObjectsAtPath:@"service/date"
		parameters:queryParams
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"service/date response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on service/date request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	 ] ;
}

- (void)Version:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *queryParams =@{
								 @"clientID" : _ReCapClientID,
							 (json ? @"json" : @"xml") : @"1"
	} ;
	[_recapClient getObjectsAtPath:@"version"
		parameters:queryParams
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"version response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on version request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	 ] ;
}

- (void)User:(NSString *)email o2id:(NSString *)o2id json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *queryParams =@{
								 @"clientID" : _ReCapClientID,
									@"email" : email,
									 @"O2ID" : o2id,
							 (json ? @"json" : @"xml") : @"1"
	} ;
	[_recapClient getObjectsAtPath:@"user"
		parameters:queryParams
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
		   NSLog(@"user response: %@", [operation.HTTPRequestOperation responseString]) ;
		   [self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
		   NSLog(@"Error on user request: %@", error) ;
		   [self responseFailure:error failure:failure] ;
		}
	 ] ;
}

- (void)CreateSimplePhotoscene:(NSString *)format meshQuality:(NSString *)meshQuality json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSString *sceneName =[[NSString alloc] initWithFormat:@"MyPhotoScene%u", arc4random ()] ;
	NSDictionary *params =@{
								 @"clientID" : _ReCapClientID,
								 @"format" : format,
								 @"meshquality" : meshQuality,
								 @"scenename" : sceneName,
								 (json ? @"json" : @"xml") : @"1"
								 } ;
	[_recapClient postObject:nil path:@"photoscene" parameters:params
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"photoscene response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on photoscene request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
}

- (void)SceneList:(NSString *)attributeName attributeValue:(NSString *)attributeValue json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *queryParams =@{
								 @"clientID" : _ReCapClientID,
							@"attributeName" : attributeName,
						   @"attributeValue" : attributeValue,
							 (json ? @"json" : @"xml") : @"1"
	} ;
	[_recapClient getObjectsAtPath:@"photoscene/properties"
		parameters:queryParams
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
		   NSLog(@"photoscene/properties response: %@", [operation.HTTPRequestOperation responseString]) ;
		   [self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
		   NSLog(@"Error on photoscene/properties request: %@", error) ;
		   [self responseFailure:error failure:failure] ;
		}
	 ] ;
}

- (void)SceneProperties:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *queryParams =@{
								  @"clientID" : _ReCapClientID,
							  (json ? @"json" : @"xml") : @"1"
	} ;
	NSString *cmd =[[NSString alloc] initWithFormat:@"photoscene/%@/properties", photosceneid] ;
	[_recapClient getObjectsAtPath:cmd
		parameters:queryParams
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
		   NSLog(@"photoscene/{0}/properties response: %@", [operation.HTTPRequestOperation responseString]) ;
		   [self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
		   NSLog(@"Error on photoscene/{0}/properties request: %@", error) ;
		   [self responseFailure:error failure:failure] ;
		}
	 ] ;
}

// https://github.com/RestKit/RestKit/wiki/Upgrading-from-v0.10.x-to-v0.20.0
- (void)UploadFiles:(NSString *)photosceneid files:(NSArray *)files json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress failure:(void (^)(NSError *error))failure {
	if ( files == nil || [files count] == 0 )
		return ;
	NSDictionary *params =@{
								 @"clientID" : _ReCapClientID,
							 @"photosceneid" : photosceneid,
							 (json ? @"json" : @"xml") : @"1",
									 @"type" : @"image"
								 } ;
    NSMutableURLRequest *request =[_recapClient multipartFormRequestWithObjectAllSigned:files method:RKRequestMethodPOST path:@"file" parameters:params
		constructingBodyWithBlock:^ (id<AFMultipartFormData> formData) {
			int n =0 ;
			for ( id photo in files ) {
				NSString *filename =[[NSString alloc] initWithFormat:@"file%d.jpg", n] ;
				NSString *key =[[NSString alloc] initWithFormat:@"file[%d]", n++] ;
				[formData appendPartWithFileData:UIImageJPEGRepresentation (photo, 0.85)
											name:key
										fileName:filename
										mimeType:@"application/octet-stream"] ; //@"image/jpeg"
			}
		}
	] ;
	//[request setValue:[self authorizationHeaderForMethod:method path:path parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"] ;
    RKObjectRequestOperation *operation =[_recapClient objectRequestOperationWithRequest:request
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"file response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on user request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
	if ( progress )
		[operation.HTTPRequestOperation setUploadProgressBlock:progress]  ;
	[_recapClient enqueueObjectRequestOperation:operation] ;
}

- (void)ProcessScene:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *params =@{
								 @"clientID" : _ReCapClientID,
								 @"photosceneid" : photosceneid,
								 @"forceReprocess" : @"!",
								 (json ? @"json" : @"xml") : @"1"
								 } ;
	NSString *cmd =[[NSString alloc] initWithFormat:@"photoscene/%@", photosceneid] ;
	[_recapClient postObject:nil path:cmd
		parameters:params
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"photoscene/{0} response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on photoscene/{0} request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
}

- (void)SceneProgress:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *params =@{
							@"clientID" : _ReCapClientID,
							@"photosceneid" : photosceneid,
							(json ? @"json" : @"xml") : @"1"
							} ;
	NSString *cmd =[[NSString alloc] initWithFormat:@"photoscene/%@/progress", photosceneid] ;
	[_recapClient getObjectsAtPath:cmd
		parameters:params
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"photoscene/{0}/progress response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on photoscene/{0}/progress request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
}

- (void)ProcessingTime:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *params =@{
							@"clientID" : _ReCapClientID,
							@"photosceneid" : photosceneid,
							(json ? @"json" : @"xml") : @"1"
							} ;
	NSString *cmd =[[NSString alloc] initWithFormat:@"photoscene/%@/processingtime", photosceneid] ;
	[_recapClient getObjectsAtPath:cmd
		parameters:params
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"photoscene/{0}/processingtime response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on photoscene/{0}/processingtime request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
}

- (void)GetPointCloudArchive:(NSString *)photosceneid format:(NSString *)format json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *params =@{
							@"clientID" : _ReCapClientID,
							@"photosceneid" : photosceneid,
							@"format" : format,
							(json ? @"json" : @"xml") : @"1"
							} ;
	NSString *cmd =[[NSString alloc] initWithFormat:@"photoscene/%@", photosceneid] ;
	[_recapClient getObjectsAtPath:cmd
		parameters:params
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"photoscene/{0}/processingtime response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on photoscene/{0}/processingtime request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
}

- (void)DeleteScene:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure {
	NSDictionary *deleteParams =@{
								 @"clientID" : _ReCapClientID,
							 (json ? @"json" : @"xml") : @"1"
	} ;
	NSString *deleteCmd =[[NSString alloc] initWithFormat:@"photoscene/%@", photosceneid] ;
	NSMutableURLRequest *request =[_recapClient multipartFormRequestWithObjectAllSigned:nil method:RKRequestMethodDELETE path:deleteCmd parameters:deleteParams constructingBodyWithBlock:nil] ;
	RKObjectRequestOperation *operation =[_recapClient objectRequestOperationWithRequest:request
		success:^ (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
			NSLog(@"photoscene/{0} delete response: %@", [operation.HTTPRequestOperation responseString]) ;
			[self response:operation mappingResult:mappingResult success:success] ;
		}
		failure:^ (RKObjectRequestOperation *operation, NSError *error) {
			NSLog(@"Error on photoscene/{0} delete request: %@", error) ;
			[self responseFailure:error failure:failure] ;
		}
	] ;
	[_recapClient enqueueObjectRequestOperation:operation] ;
}

#pragma mark - Utilities

- (AdskReCapResponse *)response:(RKObjectRequestOperation *)operation mappingResult:(RKMappingResult *)mappingResult success:(void (^)(AdskReCapResponse *response))success {
	NSString *jsonSt =[operation.HTTPRequestOperation responseString] ;
	
	NSData *jsonData =[jsonSt dataUsingEncoding:NSUTF8StringEncoding] ;
	NSError *error =nil ;
	NSDictionary *dict =[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] ;
	
	((AdskReCapResponse *)[mappingResult firstObject])._json =jsonSt ;
	((AdskReCapResponse *)[mappingResult firstObject])._data =dict ;
	
	if ( success != nil )
		success ((AdskReCapResponse *)[mappingResult firstObject]) ;
	else if ( _defaultSuccess!= nil )
		_defaultSuccess ((AdskReCapResponse *)[mappingResult firstObject]) ;
	
	return ((AdskReCapResponse *)[mappingResult firstObject]) ;
}

- (void)responseFailure:(NSError *)error failure:(void (^)(NSError *error))failure {
	if ( failure != nil )
		failure (error) ;
	else if ( _defaultFailure != nil )
		_defaultFailure (error) ;
}

+ (BOOL)isOk:(AdskReCapResponse *)response {
	return ([response._data valueForKey:@"error"] == nil && [response._data valueForKey:@"Error"] == nil) ;
}

@end
