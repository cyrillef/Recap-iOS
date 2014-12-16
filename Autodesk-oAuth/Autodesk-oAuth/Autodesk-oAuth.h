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

#import <Autodesk-oAuth/AdskOAuthController.h>
#import <Autodesk-oAuth/AdskNSString+Additions.h>

// Autodesk Oxygen (oAuth 1.0a) server
#define OAUTH_HOST            @"https://accounts.autodesk.com/"
//#define OAUTH_HOST            @"https://accounts-staging.autodesk.com/"

#define OAUTH_REQUESTTOKEN    @"OAuth/RequestToken"
#define OAUTH_AUTHORIZE       @"OAuth/Authorize" //@"?viewmode=mobile"
#define OAUTH_ACCESSTOKEN     @"OAuth/AccessToken"
#define OAUTH_INVALIDATETOKEN @"OAuth/InvalidateToken"
#define OAUTH_ALLOW           OAUTH_HOST @"OAuth/Allow"
