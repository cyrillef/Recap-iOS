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
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <vector>

#define kRenderingStartedNotification @"ReCapRenderingStarted"
#define kRenderingUpdateNotification @"ReCapRenderingUpdate"
#define kRenderingEndedNotification @"ReCapRenderingEnded"

enum {
    ATTRIB_POSITION,
	ATTRIB_COLOUR,
	ATTRIB_TEXCOORD
} ;

typedef struct {
	GLfloat	x ;
	GLfloat y ;
	GLfloat z ;
	//GLfloat w ; // if a point always 1.0 by default, if a vector 0.0 by default
} GLVector3D ;

typedef struct {
	GLfloat	u ;
	GLfloat v ;
	//GLfloat w ; // always 0.0 by default
} GLTexCoords ;

typedef struct {
	GLuint _vertex ;
	GLuint _tex ; // (optional)
	GLuint _normal ;
} GLFaceEltDef ;

typedef struct {
	std::vector<GLFaceEltDef> _def ;
} GLFace ;

typedef struct {
	GLfloat red ;
	GLfloat green ;
	GLfloat blue ;
	GLfloat alpha ;
} GLColor3D ;

/*typedef struct {
	GLVector3D position [3] ;
	GLColor3D color [4] ;
} GLvertex ;*/

/*typedef struct {
	GLVector3D position [3] ;
	GLColor3D color [4] ;
	GLTexCoords texCoord [2] ;
} GLTexVertex ;*/

@interface AdskObjGeometry : NSObject {
	@public
	std::vector<GLVector3D> _fileVertices ;
	std::vector<GLVector3D> _fileNormals ;
	std::vector<GLTexCoords> _fileTexCoords ;

	std::vector<GLVector3D> _vertices ;
	std::vector<GLVector3D> _normals ;
	std::vector<GLTexCoords> _texCoords ;
	GLVector3D _minPoint, _maxPoint ; // bounding box
	GLVector3D _center ;
}

- (id)init ;
- (void)AddObjVertex:(GLVector3D)vertex ;
- (void)AddObjNormal:(GLVector3D)vect ;
- (void)AddObjTexCoords:(GLTexCoords)coords ;

@end

@interface AdskObjMaterial : NSObject {
	@public
	GLColor3D _diffuse ; // Kd
	GLColor3D _ambient ; // Ka
	GLColor3D _specular ; // Ks
	GLfloat _shininess ; // Ns
	GLfloat _transparency ; // d / Tr
	GLuint _illum ;
	NSString *_textureFilepath ;
	GLuint _textureId ;
}

- (id)init ;

@end

@interface AdskObjGroup : NSObject {
	@public
	std::vector<GLFace> _faces ;
	std::vector<GLuint> _faceVertexIndex ;
	AdskObjMaterial *_material ;
}

- (id)init ;
- (void)AddFace:(GLFace)face ;
- (void)SetMaterial:(AdskObjMaterial *)material ;

@end

@interface AdskObjParser : NSObject {
	@public
	NSString *_objFilepath ;
	NSMutableDictionary *_projectFiles ;
	
	AdskObjGeometry *_geometry ;
	NSString *_currentGroup ;
	NSMutableDictionary *_groups ;
	NSString *_currentMaterial ;
	NSMutableDictionary *_materials ;
}

- (id)initWithPath:(NSString *)path progress:(NSString *)progress ;
- (void)setup:(GLuint)uniformTexture ;
- (void)draw ;
- (void)parseProgress:(double)pct progress:(NSString *)progress ;
- (BOOL)parseObj:(NSString *)progress ;

//- (BOOL)parseObj_g:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_usemtl:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_v:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_vn:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_vt:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_vp:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_f:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseObj_mtllib:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl ;
//- (BOOL)parseMtl_newmtl:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_Kd:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_Ka:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_Ks:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_Ns:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_d:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_Tr:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_illum:(NSArray *)items line:(NSString *)line ;
//- (BOOL)parseMtl_map_Kd:(NSArray *)items line:(NSString *)line ;
+ (UIImage *)flipImageVertically:(UIImage *)originalImage ;
//- (BOOL)loadTexture:(GLuint)texture texFileName:(NSString *)texFileName width:(int)width height:(int)height ;
- (void)loadTextures ;
//- (void)destroyTextures ;

@end

static inline GLVector3D GLVector3DMake (GLfloat X, GLfloat Y, GLfloat Z/*, GLfloat W*/) {
	GLVector3D ret ;
	ret.x =X ;
	ret.y =Y ;
	ret.z =Z ;
	return (ret) ;
}

static inline GLTexCoords GLTexCoordsMake (GLfloat U, GLfloat V/*, GLfloat W*/) {
	GLTexCoords ret ;
	ret.u =U ;
	ret.v =V ;
	return (ret) ;
}

static inline GLFaceEltDef GLFaceEltDefMake (GLuint vertex, GLuint tex, GLuint normal) {
	GLFaceEltDef ret ;
	ret._vertex =vertex ;
	ret._tex =tex ;
	ret._normal =normal ;
	return (ret) ;
}

static inline GLColor3D GLColor3DMake (GLfloat Red, GLfloat Green, GLfloat Blue, GLfloat Alpha) {
	GLColor3D ret ;
	ret.red =Red ;
	ret.green =Green ;
	ret.blue =Blue ;
	ret.alpha =Alpha ; // 0=transparent, 1=opaque
	return (ret) ;
}
