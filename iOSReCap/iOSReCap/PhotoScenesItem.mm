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
#import "PhotoScenesItem.h"
#import "PhotoScenesController.h"

#import <Autodesk-iOSViewer/Autodesk-iOSViewer.h>

@implementation AdskPhotoSceneData

@synthesize _name =__name ;
@synthesize _thumbnail =__thumbnail ;
@synthesize _data =__data ;

@end

@implementation PhotoScenesItem

@synthesize _photoscenesController =__photoscenesController ;

@synthesize _nameLabel =__nameLabel ;
@synthesize _statusLabel =__statusLabel ;
@synthesize _thumbnailImage =__thumbnailImage ;
@synthesize _refreshButton =__refreshButton ;
@synthesize _cameraButton =__cameraButton ;
@synthesize _photosButton =__photosButton ;
@synthesize _processButton =__processButton ;
@synthesize _previewButton =__previewButton ;
@synthesize _progressBar =__progressBar ;

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self =[super initWithStyle:style reuseIdentifier:reuseIdentifier] ;
    if ( self ) {
		__recapQueue =dispatch_queue_create ("com.autodesk.recap", 0) ;
		//__recapSemaphore =dispatch_semaphore_create (1) ;
    }
    return (self) ;
}

- (void)awakeFromNib {
    // Initialization code
	__recapQueue =dispatch_queue_create ("com.autodesk.recap", 0) ;
	//__recapSemaphore =dispatch_semaphore_create (1) ;	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated] ;
    // Configure the view for the selected state
	
}

- (void)waitForReCapToFinish {
    //dispatch_semaphore_wait (__recapSemaphore, DISPATCH_TIME_FOREVER) ;
    //dispatch_semaphore_signal (__recapSemaphore) ;
}

#pragma mark - Commands

- (IBAction)refresh:(id)sender {
	NSLog(@"Refreshing Scene Properties") ;
	
	if ( [__refreshButton.layer animationForKey:@"SpinAnimation"] == nil ) {
		CABasicAnimation *animation =[CABasicAnimation animationWithKeyPath:@"transform.rotation.z"] ;
		animation.fromValue =[NSNumber numberWithFloat:0.0f] ;
		animation.toValue =[NSNumber numberWithFloat:-2 * M_PI] ;
		animation.duration =1.5f ;
		animation.repeatCount =INFINITY ;
		[__refreshButton.layer addAnimation:animation forKey:@"SpinAnimation"] ;
	}

	NSString *photosceneid =self._nameLabel.text ;
	[__photoscenesController->_recap SceneProperties:photosceneid json:YES
		success:^ (AdskReCapResponse *response) {
			NSLog(@"SceneProperties successful") ;
			NSDictionary *dict =[[response._data objectForKey:@"Photoscenes"] objectForKey:@"Photoscene"] ;
			
			AdskPhotoSceneData *photoscene =(AdskPhotoSceneData *)[__photoscenesController._photoscenes objectForKey:photosceneid] ;
			photoscene._data =dict ;
			[__photoscenesController displayProperties:photoscene cell:self] ;
			[__refreshButton.layer removeAnimationForKey:@"SpinAnimation"] ;
		}
		failure:^ (NSError *error) {
			NSLog(@"SceneProperties failed!") ;
			[__refreshButton.layer removeAnimationForKey:@"SpinAnimation"] ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"SceneProperties failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	 ] ;
}

- (IBAction)selectPhotos:(id)sender {
	//if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) {
		ELCImagePickerController *_picker =[[ELCImagePickerController alloc] init] ;
	//}
	_picker.maximumImagesCount =100 ; // Set the maximum number of images to select, defaults to 4
	_picker.imagePickerDelegate =self ;
	[__photoscenesController presentViewController:_picker animated:YES completion:nil] ;
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
	[__photoscenesController dismissViewControllerAnimated:YES completion:nil] ;
}

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
	//selectedImage.image = [info objectForKey:UIImagePickerControllerOriginalImage] ;	
	[__photoscenesController dismissViewControllerAnimated:YES completion:nil] ;
	
	NSMutableArray *images =[NSMutableArray arrayWithCapacity:[info count]] ;
	for ( NSDictionary *dict in info ) {
        UIImage *image =[dict objectForKey:UIImagePickerControllerOriginalImage] ;
        [images addObject:image] ;
	}

	NSString *photosceneid =self._nameLabel.text ;
	[__photoscenesController->_recap UploadFiles:photosceneid files:images json:YES
		success:^ (AdskReCapResponse *response) {
			NSLog(@"UploadFiles successful") ;
			self._progressBar.progress =0. ;
			self._progressBar.hidden =YES ;
			//NSDictionary *dict =[[response._data objectForKey:@"Photoscenes"] objectForKey:@"Photoscene"] ;

			//AdskPhotoSceneData *photoscene =(AdskPhotoSceneData *)[__photoscenesController._photoscenes objectForKey:photosceneid] ;
			//photoscene._data =dict ;
			//[__photoscenesController displayProperties:photoscene cell:self] ;
			//[__refreshButton.layer removeAnimationForKey:@"SpinAnimation"] ;
		}
		progress:^ (NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
			self._progressBar.hidden =NO ;
			float percent =(float)totalBytesWritten / totalBytesExpectedToWrite ;
			self._progressBar.progress =percent ;
		}
		failure:^ (NSError *error) {
			NSLog(@"UploadFiles failed!") ;
			self._progressBar.hidden =YES ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"UploadFiles failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	 ] ;
}

/*-  (IBAction)camera:(id)sender {
	//if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) {
	UIImagePickerController *_picker =[[UIImagePickerController alloc] init] ;
	_picker.delegate =self ;
	if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) {
		_picker.sourceType =UIImagePickerControllerSourceTypeCamera ;
	} else {
		_picker.sourceType =UIImagePickerControllerSourceTypePhotoLibrary ;
	}
	[__photoscenesController presentViewController:_picker animated:YES completion:nil] ;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[__photoscenesController dismissViewControllerAnimated:YES completion:nil] ;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	// Code here to work with media
	[__photoscenesController dismissViewControllerAnimated:YES completion:nil] ;
	
	NSString *mediaType =info [UIImagePickerControllerMediaType] ;
	//if ( [mediaType isEqualToString:(NSString *)kUTTypeImage] ) {
		// Media is an image
		//UIImage *image =info [UIImagePickerControllerOriginalImage] ; // Original image
		UIImage *image =info [UIImagePickerControllerEditedImage] ; // Edited image
	//} //else if ( [mediaType isEqualToString:(NSString *)kUTTypeMovie] ) { Media is a video - NSURL *url =info [UIImagePickerControllerMediaURL] }
}
*/

- (IBAction)processPhotoscene:(id)sender {
	NSLog(@"Refreshing Scene Properties") ;

	if ( [__processButton.layer animationForKey:@"SpinAnimation"] == nil ) {
		CABasicAnimation *animation =[CABasicAnimation animationWithKeyPath:@"transform.rotation.z"] ;
		animation.fromValue =[NSNumber numberWithFloat:0.0f] ;
		animation.toValue =[NSNumber numberWithFloat:-2 * M_PI] ;
		animation.duration =1.5f ;
		animation.repeatCount =INFINITY ;
		[__processButton.layer addAnimation:animation forKey:@"SpinAnimation"] ;
	}

	NSString *photosceneid =self._nameLabel.text ;
	[__photoscenesController->_recap ProcessScene:photosceneid json:YES
		success:^ (AdskReCapResponse *response) {
			NSLog(@"ProcessScene successful") ;
			//[__processButton.layer removeAnimationForKey:@"SpinAnimation"] ; // Stop it only if failed or 100%
			
			NSLog(@"Start Photoscene progress") ;
			self._progressBar.progress =0. ;
			self._progressBar.hidden =NO ;
			
			[__recapTimer invalidate] ;
			__recapTimer =[NSTimer scheduledTimerWithTimeInterval:5 target:self
														 selector:@selector(processPhotosceneProgress:)
														 userInfo:photosceneid repeats:YES] ;
		}
		failure:^ (NSError *error) {
			NSLog(@"ProcessScene failed!") ;
			[__processButton.layer removeAnimationForKey:@"SpinAnimation"] ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"SceneProperties failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	] ;
}

- (void)processPhotosceneProgress:(NSTimer *)theTimer {
	dispatch_async (__recapQueue, ^ {
		NSLog(@"Photoscene progress") ;
		NSString *photosceneid =(NSString *)[theTimer userInfo] ;

		[__photoscenesController->_recap SceneProgress:photosceneid json:YES
			success:^ (AdskReCapResponse *response) {
				NSLog(@"ProcessScene progress successful") ;
				NSString *pct =[[response._data valueForKey:@"Photoscene"] valueForKey:@"progress"] ;
				NSLog(@"progress - %@", pct) ;
				float percentage =[pct floatValue] / 100. ;
				dispatch_async (dispatch_get_main_queue (), ^ {
					self._progressBar.progress =percentage ;
					
					if ( [pct isEqual: @"100"] ) {
						[__recapTimer invalidate] ;
						__recapTimer =nil ;

						[__processButton.layer removeAnimationForKey:@"SpinAnimation"] ;
						self._progressBar.progress =0. ;
						self._progressBar.hidden =YES ;
						__previewButton.hidden =NO ;
						
						[self refresh:nil] ;
					}
				}) ;
			}
			failure:^ (NSError *error) {
				NSLog(@"ProcessScene progress failed!") ;
				[__processButton.layer removeAnimationForKey:@"SpinAnimation"] ;
				UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
																 message:@"SceneProgress failed!"
																delegate:nil
														cancelButtonTitle:@"OK"
														otherButtonTitles:nil] ;
				[message show] ;
				[__recapTimer invalidate] ;
				__recapTimer =nil ;
				dispatch_async (dispatch_get_main_queue (), ^ {
					[__processButton.layer removeAnimationForKey:@"SpinAnimation"] ;
					self._progressBar.progress =0. ;
					self._progressBar.hidden =YES ;
				}) ;
			}
		] ;
	}) ;
}

- (IBAction)preview:(id)sender {
	NSLog(@"Getting the Photoscene result (mesh)") ;
	NSString *photosceneid =self._nameLabel.text ;
	NSString *filePath =[PhotoScenesItem dlFullFilePathName:photosceneid] ;
	if ( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
		UIAlertView *alert =[[UIAlertView alloc]
							 initWithTitle:@"iOS ReCap Sample"
							 message:@"Result file already present on this device, download again?"
							 delegate:self
							 cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] ; // NSLocalizedString(@"Delete",nil)
		[alert show] ;
		return ;
	}
	// else
	[self getResultFile:photosceneid] ;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *photosceneid =self._nameLabel.text ;
    switch ( buttonIndex ) {
        case 0: // No
			[self doPreview:photosceneid] ;
			break ;
        case 1: { // Yes
			NSError *error ;
			NSString *filePath =[PhotoScenesItem dlFullFilePathName:photosceneid] ;
			[[NSFileManager defaultManager] removeItemAtPath:filePath error:&error] ;
			[self getResultFile:photosceneid] ;
			break ;
		}
    }
}

- (void)getResultFile:(NSString *)photosceneid {
	[__photoscenesController->_recap GetPointCloudArchive:photosceneid format:@"obj" json:YES
		success:^ (AdskReCapResponse *response) {
			NSLog(@"GetPointCloudArchive progress successful") ;
			
			NSString *scenelink =[[response._data valueForKey:@"Photoscene"] valueForKey:@"scenelink"] ;
			if ( [scenelink isEqualToString:@""] ) {
				// That means there is a conversion happening and we need to wait
				[self performSelector:@selector(preview:) withObject:self afterDelay:2] ;
				return ;
			}

			//long filesize =[[[response._data valueForKey:@"Photoscene"] valueForKey:@"filesize"] longValue] ;
			[self downloadResultFile:scenelink photosceneid:photosceneid] ;
		}
		failure:^ (NSError *error) {
			NSLog(@"GetPointCloudArchive failed!") ;
			UIAlertView *message =[[UIAlertView alloc] initWithTitle:@"iOS ReCap Sample"
															 message:@"GetPointCloudArchive failed!"
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] ;
			[message show] ;
		}
	] ;
}

+ (NSString *)dlFullFilePathName:(NSString *)photosceneid {
    NSArray *paths =NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) ;
    NSString *filePath =[[paths objectAtIndex:0] stringByAppendingPathComponent:[photosceneid stringByAppendingString:@".zip"]] ;
	return (filePath) ;
}

- (void)downloadResultFile:(NSString *)scenelink photosceneid:(NSString *)photosceneid {
	self._progressBar.progress =0. ;
	self._progressBar.hidden =NO ;

	// Get the web link & download the file (no authentication required)
	NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:scenelink]] ;
    AFURLConnectionOperation *operation =[[AFHTTPRequestOperation alloc] initWithRequest:request] ;
	
    NSString *filePath =[PhotoScenesItem dlFullFilePathName:photosceneid] ;
    operation.outputStream =[NSOutputStream outputStreamToFileAtPath:filePath append:NO] ;
	
    [operation setDownloadProgressBlock:^ (NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        self._progressBar.progress =(float)totalBytesRead / totalBytesExpectedToRead ;
    }] ;
    [operation setCompletionBlock:^ {
        NSLog(@"downloadComplete!") ;
		self._progressBar.progress =0. ;
		self._progressBar.hidden =YES ;
		
		[self doPreview:photosceneid] ;
    }] ;
	
    [operation start] ;
}

- (void)doPreview:(NSString *)photosceneid {
	NSString *filePath =[PhotoScenesItem dlFullFilePathName:photosceneid] ;
	AdskObjViewerController *preview =[[AdskObjViewerController alloc] initWithObj:filePath photosceneid:photosceneid] ;
	[__photoscenesController presentViewController:preview animated:YES completion:nil] ;
}

@end
