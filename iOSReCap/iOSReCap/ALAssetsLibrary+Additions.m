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
#import "ALAssetsLibrary+Additions.h"

@implementation ALAssetsLibrary (AdskALAssetsLibraryAdditions)

- (void)addAsset:(NSURL *)assetURL toAlbum:(NSString *)albumName resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
    __block BOOL albumWasFound =NO ;
    
    // Search all photo albums in the library
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum 
		usingBlock:^ (ALAssetsGroup *group, BOOL *stop) {
			// Compare the names of the albums
			if ( [albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame ) {
				albumWasFound =YES ;
				// Get a hold of the photo's asset instance
				[self assetForURL:assetURL
					resultBlock:^ (ALAsset *asset) {
						[group addAsset:asset] ;
						if ( resultBlock )
							resultBlock (asset) ;
					}
					failureBlock:failureBlock
				] ;
				// Album was found, bail out of the method
				return ;
			}
			if ( group == nil && albumWasFound == NO ) {
				// Photo albums are over, target album does not exist, thus create it
				__weak ALAssetsLibrary *weakSelf =self ;
				// Create new assets album
				[self addAssetsGroupAlbumWithName:albumName 
					resultBlock:^(ALAssetsGroup *group) {
						[weakSelf assetForURL: assetURL
							resultBlock:^ (ALAsset *asset) {
								[group addAsset: asset] ;
								if ( resultBlock )
									resultBlock (asset) ;
								}
								failureBlock:failureBlock
						] ;
					}
					failureBlock:failureBlock
				] ;
				return ;
			}
		}
		failureBlock:failureBlock
	] ;
}

@end
