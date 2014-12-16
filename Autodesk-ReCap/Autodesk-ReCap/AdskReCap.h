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

#import <Foundation/Foundation.h>

#import <AFNetworking/AFHTTPClient.h>

@class AdskReCapResponse ;

typedef void (^AdskReCapRequestSuccess) (AdskReCapResponse *response) ;
typedef void (^AdskReCapRequestFailure) (NSError *error) ;

//-----------------------------------------------------------------------------
@interface AdskReCapResponse : NSObject

@property (nonatomic, strong) NSString *_resource ;
@property (nonatomic, strong) NSString *_json ;
@property (nonatomic, strong) NSDictionary *_data ;

@end

//-----------------------------------------------------------------------------
@interface AdskReCap : NSObject {
	NSString *_ReCapAPIURL ;
	NSString *_ReCapClientID ;
	AdskReCapRequestSuccess _defaultSuccess ;
	AdskReCapRequestFailure _defaultFailure ;
}

- (id)initWithUrlAndClientID:(NSString *)apiURL clientID:(NSString *)clientID oAuthClient:(AFHTTPClient *)oAuthClient ;
- (void)configureRestKit:(AFHTTPClient *)oAuthClient ;
- (void)configureDefaults:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;

- (void)ServerTime:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
- (void)Version:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
- (void)User:(NSString *)email o2id:(NSString *)o2id json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
//  SetNotificationMessage
- (void)CreateSimplePhotoscene:(NSString *)format meshQuality:(NSString *)meshQuality json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure  ;
//  CreatePhotoscene
- (void)SceneList:(NSString *)attributeName attributeValue:(NSString *)attributeValue json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
- (void)SceneProperties:(NSString *)photosceneid json:(BOOL)json  success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
- (void)UploadFiles:(NSString *)photosceneid files:(NSArray *)files json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress failure:(void (^)(NSError *error))failure ;
- (void)ProcessScene:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
- (void)SceneProgress:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
- (void)ProcessingTime:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
//  FileSize
//  GetFile
- (void)GetPointCloudArchive:(NSString *)photosceneid format:(NSString *)format json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
//  Cancel
//  SetError
- (void)DeleteScene:(NSString *)photosceneid json:(BOOL)json success:(void (^)(AdskReCapResponse *response))success failure:(void (^)(NSError *error))failure ;
	
//- (AdskReCapResponse *)response:(RKObjectRequestOperation *)operation mappingResult:(RKMappingResult *)mappingResult success:(void (^)(AdskReCapResponse *response))success ;
//- (void)responseFailure:(NSError *)error failure:(void (^)(NSError *error))failure ;
+ (BOOL)isOk:(AdskReCapResponse *)response ;

@end
