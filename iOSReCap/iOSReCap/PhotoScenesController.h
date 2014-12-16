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

#import <Autodesk-oAuth/Autodesk-oAuth.h>
#import <Autodesk-ReCap/Autodesk-ReCap.h>
#import <RestKit/RestKit.h>
#import <AFOAuth1Client/AFOAuth1Client.h>

// An example of that file is _UserSettings.h (rename it and complete it before compiling and comment out the next line)
//#error An example of that file is _UserSettings.h rename it and complete it before compiling and comment out this line
#include "UserSettings.h"

//-----------------------------------------------------------------------------
#define DefaultCellHeight 100
#define DefaultPadding 7
#define DefaultCellSubviewsNb 4

@class AdskPhotoSceneData ;
@class PhotoScenesItem ;

//-----------------------------------------------------------------------------
@interface PhotoScenesController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource> {
	@public
	AdskReCap *_recap ;
}

@property (strong, nonatomic) NSMutableDictionary *_photoscenes ;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *_logoutButton ;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *_addButton ;

- (void)viewDidLoad ;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender ;

- (void)OxygenSetup ;
- (void)autoLogin ;
- (void)login ;
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex ;
- (void)initialize ;
- (IBAction)logout:(id)sender ;

- (BOOL)ConnectWithReCapServer ;
- (void)TestConnection:(void (^)())success ;
- (void)GetUserID:(void (^)(NSString *userid))success ;
- (IBAction)createPhotoScene:(id)sender ;
- (void)ListPhotoScenes:(void (^)(NSArray *photoscenes))success ;

- (id)AddPhotoSceneItem:(NSString *)name thumbnail:(UIImage *)thumbnail data:(NSDictionary *)dict ;

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView ;
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section ;
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath ;
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath ;

- (void)displayProperties:(AdskPhotoSceneData *)photoscene cell:(PhotoScenesItem *)cell ;
//- (UILabel *)createPropertyText:(UIView *)parent pos:(CGPoint)pos text:(NSString *)text font:(UIFont *)font ;
//- (UILabel *)updatePropertyText:(UIView *)parent pos:(CGPoint)pos text:(NSString *)text at:(int)at ;

@end
