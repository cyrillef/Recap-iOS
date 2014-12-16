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
#import <UIKit/UIKit.h>

#import <ELCImagePickerController/ELCImagePickerController.h>
#import <ELCImagePickerController/ELCAlbumPickerController.h>
#import <ELCImagePickerController/ELCAssetTablePicker.h>

@class PhotoScenesController ;

//-----------------------------------------------------------------------------
@interface AdskPhotoSceneData : NSObject

@property (strong, nonatomic) NSString *_name ;
@property (strong, nonatomic) UIImage *_thumbnail ;
@property (strong, nonatomic) NSDictionary *_data ;

@end

//-----------------------------------------------------------------------------
@interface PhotoScenesItem : UITableViewCell <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ELCImagePickerControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) PhotoScenesController *_photoscenesController ;

@property (nonatomic, strong) NSTimer *_recapTimer ;
@property (nonatomic, strong) dispatch_queue_t _recapQueue ;
//@property (nonatomic, strong) dispatch_semaphore_t _recapSemaphore ;

@property (retain, nonatomic) IBOutlet UILabel *_nameLabel ;
@property (retain, nonatomic) IBOutlet UILabel *_statusLabel ;
@property (retain, nonatomic) IBOutlet UIImageView *_thumbnailImage ;
@property (retain, nonatomic) IBOutlet UIButton *_refreshButton ;
@property (retain, nonatomic) IBOutlet UIButton *_cameraButton ;
@property (retain, nonatomic) IBOutlet UIButton *_photosButton ;
@property (retain, nonatomic) IBOutlet UIButton *_processButton ;
@property (retain, nonatomic) IBOutlet UIButton *_previewButton ;
@property (retain, nonatomic) IBOutlet UIProgressView *_progressBar ;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier ;
- (void)awakeFromNib ;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated ;

- (IBAction)refresh:(id)sender ;
- (IBAction)selectPhotos:(id)sender ;
- (IBAction)processPhotoscene:(id)sender ;
- (void)processPhotosceneProgress:(NSTimer *)theTimer ;
- (IBAction)preview:(id)sender ;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex ;
- (void)getResultFile:(NSString *)photosceneid ;
+ (NSString *)dlFullFilePathName:(NSString *)filename ;
- (void)downloadResultFile:(NSString *)scenelink photosceneid:(NSString *)photosceneid ;
- (void)doPreview:(NSString *)photosceneid ;

@end
