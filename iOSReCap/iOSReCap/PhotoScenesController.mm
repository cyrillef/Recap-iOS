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
#import "PhotoScenesController.h"
#import "PhotoScenesItem.h"
#import "CameraViewController.h"

#import <ZipKit/ZKArchive.h>
#import <ZipKit/ZKFileArchive.h>
#import <ZipKit/ZKDataArchive.h>
#import <ZipKit/ZKCDHeader.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoScenesController () {
	AdskOAuthController *_oauthController ;
	NSIndexPath *_selectedRowIndex ;
	CGFloat _cellMaxHeight ;
}

@end

#include <Autodesk-iOSViewer/AdskObjParser.h>

@implementation PhotoScenesController

@synthesize _photoscenes =__photoscenes ;
@synthesize _logoutButton =__logoutButton ;
@synthesize _addButton =__addButton ;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad] ;
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationController.toolbarHidden =NO ;
	self.tableView.allowsMultipleSelectionDuringEditing =NO ;
	
	//AdskObjParser *test =[[AdskObjParser alloc] initWithPath:@"/Users/cyrille/Library/Application Support/iPhone Simulator/7.1/Applications/2BFEFEBB-7282-4E88-838F-4FBBFB6C78C5/Documents/WSqUlt1GaRNx9KvXI13I9mHwqeI.zip" progress:nil] ;
	[self autoLogin] ;
		
	self.navigationItem.leftBarButtonItem =self._logoutButton ; // todo
	self.navigationItem.rightBarButtonItem =self._addButton ;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ( [segue.identifier isEqualToString:@"Camera"] ) {
		UINavigationController *navigationController = segue.destinationViewController;
        CameraViewController *cameraViewController =(CameraViewController *)navigationController ;
        //cameraViewController.delegate =self ;
		
		UIButton *button =(UIButton *)sender ;
		UILabel *nameLabel =(UILabel *)[[button superview] viewWithTag:100] ;
		NSString *photosceneid =nameLabel.text ;
		cameraViewController._photosceneid =photosceneid ;
	}
}

#pragma mark - oAuth

- (void)OxygenSetup {
	[AdskOAuthController setApplicationKeys:CONSUMER_KEY secret:CONSUMER_SECRET] ;
	[AdskOAuthController setApplicationPaths:OAUTH_HOST request:OAUTH_REQUESTTOKEN authorize:OAUTH_AUTHORIZE access:OAUTH_ACCESSTOKEN invalidate:OAUTH_INVALIDATETOKEN allow:OAUTH_ALLOW] ;
}

- (void)autoLogin {
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	if (   [defaults objectForKey:@"oauth_token"]
		&& [defaults objectForKey:@"oauth_token_secret"]
		&& [defaults objectForKey:@"oauth_session_handle"]
	) {
		[self OxygenSetup] ;
		[AdskOAuthController AccessToken:YES PIN:nil
			success:^ () {
				[self initialize] ;
			}
			failure:^ (NSError * error) {
				[self login] ;
			}
		 ] ;
	} else {
		[self login] ;
	}
}

- (void)login {
	_oauthController =[[AdskOAuthController alloc] initWithNibName:nil bundle:nil] ;
	[self OxygenSetup] ;
	[self presentViewController:_oauthController animated:YES
		completion:^ () {
			[_oauthController RequestToken:^ () {
					[_oauthController dismissViewControllerAnimated:YES completion:nil] ;
					[self initialize] ;
				}
				failure:^ (NSError *error) {
					[_oauthController dismissViewControllerAnimated:YES completion:nil] ;
					UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
																	message:@"Failed to authenticate!"
																	delegate:self
														   cancelButtonTitle:@"OK"
														   otherButtonTitles:nil] ;
					[message show] ;
				}
			] ;
		}
	] ;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //if ( buttonIndex == 0 ) {
		[self login] ;
	//}
}

- (void)initialize {
	[self ConnectWithReCapServer] ;
	[self TestConnection:^ () {
		[self GetUserID:^ (NSString *userid) {
			[self ListPhotoScenes:nil] ;
		}] ;
	}] ;
}

- (IBAction)logout:(id)sender {
	[AdskOAuthController InvalidateToken:^ () {
			[self login] ;
		}
		failure: ^ (NSError *error) {
			[self login] ;
		}
	] ;
}

#pragma mark - ReCap Calls

- (BOOL)ConnectWithReCapServer {
	if ( [RKObjectManager sharedManager] != nil )
		return (YES) ;
	
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	// Initialize AFNetworking HTTPClient
	NSURL *baseURL =[NSURL URLWithString:ReCapAPIURL] ;
	//AFHTTPClient *client =[[AFHTTPClient alloc] initWithBaseURL:baseURL] ;
	AFOAuth1Client *oauth1Client =[[AFOAuth1Client alloc] initWithBaseURL:baseURL key:CONSUMER_KEY secret:CONSUMER_SECRET] ;
	oauth1Client.accessToken =[[AFOAuth1Token alloc] initWithKey:[defaults objectForKey:@"oauth_token"]
														  secret:[defaults objectForKey:@"oauth_token_secret"]
														 session:nil
													  expiration:nil
													   renewable:YES
	] ;
	//[oauth1Client registerHTTPOperationClass:[AFJSONRequestOperation class]] ;
	// Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	//[oauth1Client setDefaultHeader:@"Accept" value:@"application/json"] ;
	[oauth1Client setDefaultHeader:@"Accept" value:@"text/html"] ;

	// Initialize recap client (including RestKit)
	_recap =[[AdskReCap alloc] initWithUrlAndClientID:ReCapAPIURL clientID:ReCapClientID oAuthClient:oauth1Client] ;
	
	return (YES) ;
}

- (void)TestConnection:(void (^)())success {
	NSLog(@"Test Connection") ;
	[_recap ServerTime:YES
		success:^ (AdskReCapResponse *response) {
			if ( [AdskReCap isOk:response] ) {
				NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init] ;
				[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"] ;
				NSDate *dt =[dateFormatter dateFromString:[response._data valueForKey:@"date"]] ;
				
				NSTimeZone *tz =[NSTimeZone defaultTimeZone] ;
				NSInteger seconds =[tz secondsFromGMTForDate:dt] ;
				
				NSLog(@"ReCap Server date: %@", [NSDate dateWithTimeInterval:seconds sinceDate:dt]) ;
				
				if ( success != nil )
					success () ;
			}
		}
		failure:^ (NSError *error ) {
			_recap =nil ;
			NSLog(@"ReCap Error: Connection to ReCap Server failed!") ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"ReCap Error: Connection to ReCap Server failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	 ] ;
}

- (void)GetUserID:(void (^)(NSString *userid))success {
	[self ConnectWithReCapServer] ;
	NSLog(@"Request current UserID") ;
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	[_recap User:[defaults objectForKey:@"x_oauth_user_name"] o2id:[defaults objectForKey:@"x_oauth_user_guid"] json:YES
		 success:^ (AdskReCapResponse *response) {
			 if ( [AdskReCap isOk:response] ) {
				 NSString *userid =[[response._data valueForKey:@"User"] valueForKey:@"userID"] ;
				 NSLog(@"UserID - %@", userid) ;
				 
				 NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
				 [defaults setObject:userid forKey:@"recap_UserID"] ;
				 [defaults synchronize] ;
				 
				 if ( success != nil )
					 success (userid) ;
			 }
		 }
		 failure:^ (NSError *error ) {
			 NSLog(@"Getting UserID failed!") ;
			 UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															  message:@"Getting UserID failed!"
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil] ;
			 [message show] ;
		 }
	] ;
}

- (IBAction)createPhotoScene:(id)sender {
	[self ConnectWithReCapServer] ;
	NSLog(@"Create new Photoscene") ;
	[_recap CreateSimplePhotoscene:@"obj" meshQuality:@"7" json:YES
		success:^ (AdskReCapResponse *response) {
			if ( [AdskReCap isOk:response] ) {
				NSString *photosceneid =[[response._data valueForKey:@"Photoscene"] valueForKey:@"photosceneid"] ;
				NSLog(@"photosceneid - %@", photosceneid) ;
				
				[_recap SceneProperties:photosceneid json:YES
					success:^ (AdskReCapResponse *response) {
						NSDictionary *ps =[[response._data objectForKey:@"Photoscenes"] objectForKey:@"Photoscene"] ;
						//for ( id object in dict )
							[self AddPhotoSceneItem:photosceneid thumbnail:nil data:ps] ;
						// Autoselect
						_selectedRowIndex =[NSIndexPath indexPathForRow:([__photoscenes count] - 1) inSection:0] ;
						[self.tableView reloadData] ;
						[self.tableView scrollToRowAtIndexPath:_selectedRowIndex
											  atScrollPosition:UITableViewScrollPositionTop
													  animated:YES] ;
						
						NSString *msg =[[NSString alloc] initWithFormat:@"A new scene '%@' was created for you and put at the bottom of the list", photosceneid] ;
						UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
																		 message:msg
																		delegate:nil
															   cancelButtonTitle:@"OK"
															   otherButtonTitles:nil] ;
						[message show] ;
					}
					failure:^ (NSError *error) {
						UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
																		 message:@"SceneProperties failed!"
																		delegate:nil
															   cancelButtonTitle:@"OK"
															   otherButtonTitles:nil] ;
						[message show] ;
					}
				] ;
			}
		}
		failure:^ (NSError *error ) {
			NSLog(@"CreateSimplePhotoscene failed!") ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"CreateSimplePhotoscene failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	] ;
}

- (void)ListPhotoScenes:(void (^)(NSArray *photoscenes))success {
	[self ConnectWithReCapServer] ;
	NSLog(@"List Photoscenes") ;
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	[_recap SceneList:@"userID" attributeValue:[defaults objectForKey:@"recap_UserID"] json:YES
		success:^ (AdskReCapResponse *response) {
			NSLog(@"ListPhotoScenes successful") ;
			
			[self ClearPhotoScenes] ;
			NSMutableArray *ps =[[response._data objectForKey:@"Photoscenes"] objectForKey:@"Photoscene"] ;
			for ( id object in ps ) {
				if ( [((NSString *)[object objectForKey:@"deleted"]) isEqual:@"true"] )
					continue ;
				[self AddPhotoSceneItem:[object objectForKey:@"photosceneid"] thumbnail:nil data:object] ;
			}
			[self.tableView reloadData] ;
			
			if ( success != nil )
				success (nil) ;
		}
		failure:^ (NSError *error ) {
			NSLog(@"ListPhotoScenes failed!") ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"ListPhotoScenes failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	] ;
}

#pragma mark - PhotoScene mgt

- (void)ClearPhotoScenes {
	if ( __photoscenes )
		[__photoscenes removeAllObjects] ;
	else
		__photoscenes =[[NSMutableDictionary alloc] init] ;
}

- (id)AddPhotoSceneItem:(NSString *)name thumbnail:(UIImage *)thumbnail data:(NSDictionary *)dict {
	AdskPhotoSceneData *data =[[AdskPhotoSceneData alloc] init] ;
	data._name =name ;
	if ( thumbnail != nil ) {
		data._thumbnail =thumbnail ;
	} else {
		NSString *zipFilePath =[PhotoScenesItem dlFullFilePathName:name] ;
		if ( [[NSFileManager defaultManager] fileExistsAtPath:zipFilePath] ) {
			ZKDataArchive *za =[ZKDataArchive archiveWithArchivePath:zipFilePath] ;
			for ( ZKCDHeader *header in za.centralDirectory ) {
				NSString *name =[header.filename lastPathComponent] ;
				if ( [[name pathExtension] isEqualToString:@"png"] || [[name pathExtension] isEqualToString:@"jpg"] ) {
					NSDictionary *dict =[[NSDictionary alloc] init] ;
					NSData *filedata =[za inflateFile:header attributes:&dict] ;
					data._thumbnail =[UIImage imageWithData:filedata] ;
					break ;
				}
			}
		} else {
			ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init] ;
			// Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
			[library enumerateGroupsWithTypes:ALAssetsGroupAlbum
				usingBlock:^ (ALAssetsGroup *group, BOOL *stop) {
					if ( [[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:data._name] ) {
						data._thumbnail =[UIImage imageWithCGImage:[group posterImage]] ;
						*stop =YES ;
						
						// At this time the table is already loaded, so we need to update the corresponding cell
						NSInteger index =[[__photoscenes allKeys] indexOfObject:data._name] ;
						NSIndexPath *indexPath =[NSIndexPath indexPathForRow:index inSection:0] ;
						[self.tableView beginUpdates] ;
						[self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone] ;
						[self.tableView endUpdates] ;
					}
					// Within the group enumeration block, filter to enumerate just photos.
					//[group setAssetsFilter:[ALAssetsFilter allPhotos]] ;
					// Chooses the first photo
					/*[group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^ (ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
						// The end of the enumeration is signaled by asset == nil.
						ALAssetRepresentation *representation =[alAsset defaultRepresentation] ;
						data._thumbnail =[UIImage imageWithCGImage:[representation fullScreenImage]] ;
						// Stop the enumerations
						*innerStop =YES ;
						*stop =YES ;
					}];*/
				}
				failureBlock:^ (NSError *error) {
					NSLog (@"No groups") ;
				}
			];
		}
	}
	data._data =dict ;
	[__photoscenes setObject:data forKey:name] ;
	return (data) ;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (1) ;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (__photoscenes.count) ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotoScenesItem *cell =(PhotoScenesItem *)[tableView dequeueReusableCellWithIdentifier:@"PhotoScenesItem" forIndexPath:indexPath] ;
	cell._photoscenesController =self ;
	NSString *photosceneid =(NSString *)([__photoscenes allKeys] [indexPath.row]) ;
	AdskPhotoSceneData *scene =(AdskPhotoSceneData *)[__photoscenes objectForKey:photosceneid] ; //__photoscenes [[indexPath row]] ;
	cell._nameLabel.text =scene._name ;
	cell._statusLabel.text =scene._data [@"status"] ;
	cell._thumbnailImage.contentMode =UIViewContentModeScaleAspectFit ;
	UIImage *recapImage =(scene._thumbnail == nil ? [UIImage imageNamed:@"ReCap.jpg"] : scene._thumbnail) ;
	cell._thumbnailImage.image =recapImage ;
	
	//if ( [((UIView *)cell.subviews [0]).subviews count] < DefaultCellSubviewsNb + 1 ) // There is an intermediate scrollview
		[self displayProperties:scene cell:cell] ;
	
    return (cell) ;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( _selectedRowIndex && indexPath.row == _selectedRowIndex.row )
		return (_cellMaxHeight) ;
	return (DefaultCellHeight) ;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( _selectedRowIndex && indexPath.row == _selectedRowIndex.row )
		_selectedRowIndex =nil ;
	else
		_selectedRowIndex =indexPath ;
	[tableView beginUpdates] ;
	[tableView endUpdates] ;
}

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return (YES) ;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
		NSString *photosceneid =(NSString *)([__photoscenes allKeys] [indexPath.row]) ;
		//AdskPhotoSceneData *scene =(AdskPhotoSceneData *)[__photoscenes objectForKey:photosceneid] ; // [[indexPath row]] ;
		//NSString *photosceneid =scene._name ;
		[self ConnectWithReCapServer] ;
		NSLog(@"Delete a Photoscene") ;
		[_recap DeleteScene:photosceneid json:YES
			success:^ (AdskReCapResponse *response) {
				NSLog(@"DeleteScene successful") ;
				// todo: delete the item in the dictionary and table
			}
			failure:^ (NSError *error ) {
				NSLog(@"DeleteScene failed!") ;
				UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
																 message:@"DeleteScene failed!"
																delegate:nil
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil] ;
				[message show] ;
			}
		 ] ;
    }
}

/*- (NSString *)tableView:(UITableView *)tableView titleForSwipeAccessoryButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView swipeAccessoryButtonPushedForRowAtIndexPath:(NSIndexPath *)indexPath {
}
*/

#pragma mark - Photoscene Properties

- (void)displayProperties:(AdskPhotoSceneData *)photoscene cell:(PhotoScenesItem *)cell {
	NSArray *properties =@[
						   @"Photoscene|Photoscene ID|photosceneid", // Internal database ID for the Photoscene
						   @"Photoscene|Scene Name|name", // Name of the scene as it appears in the final filename
						   @"Photoscene|Creation Date|creationDate", // Date/Time when the scene was first created
						   @"Photoscene|Convert Format|convertFormat",
						   @"Photoscene|Deleted|deleted", // If true, the Photoscene and its resources were deleted from the server
						   @"Photoscene|File Size|fileSize", // Size on disc for all documents used to or created by the Photoscene
						   @"Mesh Data|Mesh Quality|meshQuality", // Requested quality for the generated mesh
						   @"Mesh Data|Faces|nbFaces", // Number of faces in the generated mesh
						   @"Mesh Data|Vertices|nbVertices", // Number of vertices in the generated mesh
						   @"Mesh Data|3d Points|nb3dPoints", // Number of 3D points in the generated mesh
						   @"Mesh Data|Scene Link|sceneLink", // Link to download the processed Photoscene
						   @"Photogrammetry|Shots|nbShots", // Number of images loaded in the Photoscene
						   @"Photogrammetry|Stitched Shots|nbStitchedShots", // Number of images used to extract the generated mesh
						   //@"Photogrammetry|Files|Files",
						   @"Misc|Processing Time|processingTime",
						   @"Misc|Progress|progress", // Current progress of a Photoscene (in %)
						   @"Misc|Progress Message|progressMessage",
						   @"Misc|Status|status",
						   @"Misc|Convert Status|convertStatus",
						   @"Misc|User ID|userID", // Internal database User ID of the person who created the Photoscene
						   ] ;
	// Refresh the status now
	cell._statusLabel.text =photoscene._data [@"status"] ;
	cell._previewButton.hidden =![photoscene._data [@"status"] isEqualToString:@"DONE"] ;
	// Refresh generic properties
	CGFloat y =DefaultCellHeight + 2 * DefaultPadding ;
	int i =0, n =DefaultCellSubviewsNb ;
	for ( UIView *p in ((UIView *)cell.subviews [0]).subviews ) {
		if ( [p isKindOfClass:[UILabel class]] ) {
			if ( [((UILabel *)p).text isEqualToString:@"Photoscene"] ) {
				n =i ;
				break ;
			}
		}
		i++ ;
	}
	
	NSMutableString *currentTitle =[[NSMutableString alloc] initWithString:@""] ;
	for ( NSString *desc in properties ) {
		NSArray *items =[desc componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"|"]] ;
		if ( ![items [0] isEqualToString:currentTitle] ) {
			NSString *title =items [0] ;
			UIFont *font =cell._nameLabel.font ;
			UILabel *label =nil ;
			if ( [((UIView *)cell.subviews [0]).subviews count] < n + 1 ) {
				label =[self createPropertyText:cell pos:CGPointMake(DefaultPadding, y) text:title font:font] ;
			} else {
				//label =(UILabel *)((UIView *)cell.subviews [0]).subviews [n] ;
				//label.text =title ;
				label =[self updatePropertyText:cell pos:CGPointMake(DefaultPadding, y) text:title at:n] ;
			}
			currentTitle =items [0] ;
			y +=label.bounds.size.height + DefaultPadding ;
			n++ ;
			//NSLog(@"-> %@ (%d)", currentTitle, n) ;
		}
		
		NSString *text =items [1] ;
		UIFont *font =cell._nameLabel.font ;
		UILabel *label =nil ;
		if ( [((UIView *)cell.subviews [0]).subviews count] < n + 1 ) {
			label =[self createPropertyText:cell pos:CGPointMake(2 * DefaultPadding, y) text:text font:font] ;
		} else {
			//label =(UILabel *)((UIView *)cell.subviews [0]).subviews [n] ;
			//label.text =text ;
			label =[self updatePropertyText:cell pos:CGPointMake(2 * DefaultPadding, y) text:text at:n] ;
		}
		n++ ;
		
		text =(photoscene._data [items [2]] == nil ? @"" : photoscene._data [items [2]]) ;
		text =[text RFC3986Decode] ;
		//font =[cell._nameLabel.font fontWithSize:cell._nameLabel.font.pointSize] ;
		font =[UIFont systemFontOfSize:cell._nameLabel.font.pointSize] ;
		UILabel *property =nil ;
		if ( [((UIView *)cell.subviews [0]).subviews count] < n + 1 ) {
			property =[self createPropertyText:cell pos:CGPointMake(cell.bounds.size.width / 2, y) text:text font:font] ;
		} else {
			//property =(UILabel *)((UIView *)cell.subviews [0]).subviews [n] ;
			//property.text =text ;
			property =[self updatePropertyText:cell pos:CGPointMake(cell.bounds.size.width / 2, y) text:text at:n] ;
		}
		y +=label.bounds.size.height + DefaultPadding ;
		n++ ;
		//NSLog(@"     %@ - %@", label.text, property.text) ;
	}
	_cellMaxHeight =y ;
}

- (UILabel *)createPropertyText:(UIView *)parent pos:(CGPoint)pos text:(NSString *)text font:(UIFont *)font {
	CGSize maxSize =CGSizeMake (parent.bounds.size.width / 2, 0.0) ;
	CGRect textRect =[text boundingRectWithSize:maxSize
										options:NSStringDrawingUsesLineFragmentOrigin
									 attributes:@{NSFontAttributeName:font}
										context:nil] ;
	UILabel *title =[[UILabel alloc] initWithFrame:CGRectMake(pos.x, pos.y, textRect.size.width, textRect.size.height)] ;
	title.font =font ;
	title.text =text ;
	//title.numberOfLines =1 ;
	title.baselineAdjustment =UIBaselineAdjustmentAlignBaselines ; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
																   //title.adjustsFontSizeToFitWidth =YES ;
																   //title.adjustsLetterSpacingToFitWidth =YES ;
																   //title.minimumScaleFactor =10.0f / 12.0f ;
	title.clipsToBounds =NO ;
	//title.backgroundColor =[UIColor clearColor] ;
	//title.textColor =[UIColor blackColor] ;
	title.textAlignment =NSTextAlignmentLeft ;
	[parent addSubview:title] ;
	return (title) ;
}

- (UILabel *)updatePropertyText:(UIView *)parent pos:(CGPoint)pos text:(NSString *)text at:(int)at {
	UILabel *label =(UILabel *)((UIView *)parent.subviews [0]).subviews [at] ;
	
	CGSize maxSize =CGSizeMake (parent.bounds.size.width / 2, 0.0) ;
	CGRect textRect =[text boundingRectWithSize:maxSize
										options:NSStringDrawingUsesLineFragmentOrigin
									 attributes:@{NSFontAttributeName:label.font}
										context:nil] ;
	label.bounds.size =textRect.size ;
	label.text =text ;
	return (label) ;
}

@end
