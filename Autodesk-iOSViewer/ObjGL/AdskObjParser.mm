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
#import <GLKit/GLKit.h>

#import "AdskObjParser.h"

#import <ZipKit/ZKArchive.h>
#import <ZipKit/ZKFileArchive.h>
#import <ZipKit/ZKDataArchive.h>
#import <ZipKit/ZKCDHeader.h>

#define MAX_LINE_LENGTH 256
#import <sstream>

@implementation AdskObjGeometry

- (id)init {
	if ( (self =[super init]) ) {
	}
	return (self) ;
}

- (void)AddObjVertex:(GLVector3D)vertex {
	_fileVertices.push_back (vertex) ;
	if ( vertex.x > _maxPoint.x )
		_maxPoint.x =vertex.x ;
	if ( vertex.y > _maxPoint.y )
		_maxPoint.y =vertex.y ;
	if ( vertex.z > _maxPoint.z )
		_maxPoint.z =vertex.z ;
	if ( vertex.x < _minPoint.x )
		_minPoint.x =vertex.x ;
	if ( vertex.y < _minPoint.y )
		_minPoint.y =vertex.y ;
	if ( vertex.z < _minPoint.z )
		_minPoint.z =vertex.z ;
	_center =GLVector3DMake ((_maxPoint.x + _minPoint.x) / 2, (_maxPoint.y + _minPoint.y) / 2, (_maxPoint.z + _minPoint.z) / 2) ;
}

- (void)AddObjNormal:(GLVector3D)vect {
	_fileNormals.push_back (vect) ;
}

- (void)AddObjTexCoords:(GLTexCoords)coords {
	_fileTexCoords.push_back (coords) ;
}

@end

@implementation AdskObjMaterial

- (id)init {
	if ( (self =[super init]) ) {
		_diffuse =GLColor3DMake (0.8, 0.8, 0.8, 1.0) ;
		_ambient =GLColor3DMake (0.2, 0.2, 0.2, 1.0) ;
		_specular =GLColor3DMake (0.0, 0.0, 0.0, 1.0) ;
		_shininess =65.0 ;
		_textureFilepath =nil ;
	}
	return (self) ;
}

@end

@implementation AdskObjGroup

- (id)init {
	if ( (self =[super init]) ) {
	}
	return (self) ;
}

- (void)AddFace:(GLFace)face {
	_faces.push_back (face) ;
}

- (void)SetMaterial:(AdskObjMaterial *)material {
	_material =material ;
}

@end

@implementation AdskObjParser

- (id)initWithPath:(NSString *)path progress:(NSString *)progress {
	if ( (self =[super init]) ) {
		_objFilepath =path ;
		 _currentGroup =_currentMaterial =nil ;
		_geometry =[[AdskObjGeometry alloc] init] ;
		_groups =[[NSMutableDictionary alloc] init] ;
		_materials =[[NSMutableDictionary alloc] init] ;
		[self parseObj:progress] ;
	}
	return (self) ;
}

- (void)dealloc {
	[self destroyTextures] ;
}

- (void)setup:(GLuint)uniformTexture {
	glVertexAttribPointer (ATTRIB_POSITION, 3, GL_FLOAT, false, 0, _geometry->_vertices.data ()) ;
	glEnableVertexAttribArray (ATTRIB_POSITION) ;

	// Set the texture uniform
	int i =0 ;
	NSArray *groups =[_groups allKeys] ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		if ( group->_material == nil || group->_material->_textureId == 0 )
			continue ;

		glActiveTexture (GL_TEXTURE0 + i) ;
		glBindTexture (GL_TEXTURE_2D, group->_material->_textureId) ;
		glUniform1i (uniformTexture, i) ;
	}
	// Set the texture coords
	glVertexAttribPointer (ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, _geometry->_texCoords.data ()) ;
	glEnableVertexAttribArray (ATTRIB_TEXCOORD) ;
}

- (void)draw {
	NSArray *groups =[_groups allKeys] ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		if ( group->_faceVertexIndex.size () )
			glDrawElements (GL_TRIANGLES, (GLsizei)group->_faceVertexIndex.size (), GL_UNSIGNED_INT, group->_faceVertexIndex.data ()) ;
	}
}

- (void)parseProgress:(double)pct progress:(NSString *)progress {
	if ( progress == nil )
		return ;
	/*if ( dispatch_get_current_queue () == dispatch_get_main_queue () ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingUpdateNotification object:[NSNumber numberWithDouble:pct]] ;
		return ;
	}*/
	dispatch_sync (dispatch_get_main_queue (), ^ {
		[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingUpdateNotification object:[NSNumber numberWithDouble:pct]] ;
	}) ;
}

+ (NSMutableDictionary *)unzipProject:(NSString *)zipFilePath {
	NSMutableDictionary *data =[[NSMutableDictionary alloc] init] ;
	ZKDataArchive *za =[ZKDataArchive archiveWithArchivePath:zipFilePath] ;
	for ( ZKCDHeader *header in za.centralDirectory ) {
		NSString *name =[header.filename lastPathComponent] ;
		NSDictionary *dict =[[NSDictionary alloc] init] ;
		NSData *filedata =[za inflateFile:header attributes:&dict] ;
		[data setValue:filedata forKey:name] ;
	}
	return (data) ;
}

+ (NSString *)stringWithContentsOfFile:(NSString *)filepath {
	NSStringEncoding encoding ;
	NSString *data =[[NSString stringWithContentsOfFile:filepath usedEncoding:&encoding error:nil] stringByReplacingOccurrencesOfString:@"\r" withString:@""] ;
	return (data) ;
}

- (BOOL)parseObjInObjc:(NSString *)progress {
	if ( _projectFiles == nil )
		_projectFiles =[AdskObjParser unzipProject:_objFilepath] ;
	
	NSDate *methodStart =[NSDate date] ;
	NSString *objData =[[[NSString alloc] initWithData:[_projectFiles objectForKey:@"mesh.obj"] encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\r" withString:@""] ;
	NSArray *lines =[objData componentsSeparatedByString:@"\n"] ;
	unsigned long v =0, vt =0, f =0, nb =[lines count] + 1 ;
	[self parseProgress:0.05 progress:progress] ;
	// Counting vertex, texture vertex, and faces prior allocating from file does not seems to help on the performance
	for ( NSString *itLine in lines ) {
		NSString *line =[itLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
		if ( [line isEqualToString:@""] || [line hasPrefix:@"#"] )
			continue ;
		NSArray *items =[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ;
		v +=([[items objectAtIndex:0] isEqualToString:@"v"] ? 1 : 0) ;
		vt +=([[items objectAtIndex:0] isEqualToString:@"vt"] ? 1 : 0) ;
		f +=([[items objectAtIndex:0] isEqualToString:@"f"] ? 1 : 0) ;
	}
	_geometry->_fileVertices.reserve (v) ;
	_geometry->_fileNormals.reserve (vt) ;
	_geometry->_fileTexCoords.reserve (f) ;
	NSLog(@"exec time = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;

	[self parseProgress:0.5 progress:progress] ;
	unsigned long i =0 ;
	for ( NSString *itLine in lines ) {
		NSString *line =[itLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
		if ( [line isEqualToString:@""] || [line hasPrefix:@"#"] )
			continue ;
		NSArray *items =[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ;
		NSString *command =[NSString stringWithFormat:@"parseObj_%@:line:", [items objectAtIndex:0]] ;
		SEL cmd =NSSelectorFromString (command) ;
		if ( cmd != nil && [self respondsToSelector:cmd] )
			[self performSelector:cmd withObject:items withObject:line] ;
		[self parseProgress:(0.05 + 0.28 * ((double)i++ / nb)) progress:progress] ;
	}
	NSLog(@"exec time = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;
	NSLog(@"%lu %ld", v, _geometry->_fileVertices.size ()) ;
	
	// Now we parsed the file, we need to process some data like the face' vertices index and textures
	//[self loadTextures] ;
	[self parseProgress:0.33 progress:progress] ;
	
	// Split Quads into triangles and create v/vt uniq pair list
	std::vector<GLFace> newFaces ;
	NSMutableSet *uniqPairs =[NSMutableSet set] ;
	NSArray *groups =[_groups allKeys] ;
	nb =1 ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		nb +=group->_faces.size () ;
	}
	i =0 ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		std::vector<GLFace>::iterator it =group->_faces.begin () ;
		for ( ; it != group->_faces.end () ; it++ ) {
			// Create vertex/tex pairs list
			std::vector<GLFaceEltDef>::iterator itdef =(*it)._def.begin () ;
			for ( ; itdef != (*it)._def.end () ; itdef++ ) {
				NSString *pairName =[NSString stringWithFormat:@"%u/%u",
									 (*itdef)._vertex,
									 ((*itdef)._tex == (GLuint)-1 ? 0 : (*itdef)._tex)] ;
				//NSLog(@"%@", pairName) ;
				[uniqPairs addObject:pairName] ;
			}
			// Split quads into triangles
			if ( (*it)._def.size () == 4 ) { // a quad
				GLFace glface ;
				glface._def.push_back ((*it)._def [0]) ;
				glface._def.push_back ((*it)._def [2]) ;
				glface._def.push_back ((*it)._def [3]) ;
				(*it)._def.pop_back () ;
				//[group AddFace:glface] ; // push_back() invalidates iterators
				newFaces.push_back (glface) ;
			} else if ( (*it)._def.size () > 4 ) {
				NSLog(@"%@", @"Face needs to be triangulated!") ;
			}
		}
		group->_faces.insert (group->_faces.end (), newFaces.begin (), newFaces.end ()) ;
		
		[self parseProgress:(0.33 + 0.18 * ((double)i++ / nb)) progress:progress] ;
	}
	[self parseProgress:0.51 progress:progress] ;

	// Build OpenGL vertex / tex arrays
	GLuint nbPairs =(GLuint)[uniqPairs count] ;
	_geometry->_vertices.reserve (nbPairs) ;
	_geometry->_texCoords.reserve (nbPairs) ;
	NSArray *pairs =[uniqPairs allObjects] ;
	NSMutableDictionary *pairsIndex =[[NSMutableDictionary alloc] init] ;
	for ( GLuint index =0 ; index < nbPairs ; index++ ) {
		NSString *pairName =[pairs objectAtIndex:index] ;
		[pairsIndex setObject:[NSNumber numberWithUnsignedLong:index] forKey:pairName] ;
		NSArray *def =[pairName componentsSeparatedByString:@"/"] ;
		_geometry->_vertices [index] =_geometry->_fileVertices [[[def objectAtIndex:0] unsignedIntValue]] ;
		_geometry->_texCoords [index] =_geometry->_fileTexCoords [[[def objectAtIndex:1] unsignedIntValue]] ;

		[self parseProgress:(0.51 + 0.03 * ((double)index / nbPairs)) progress:progress] ;
	}
	// Build OpenGL face array
	i =0 ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		group->_faceVertexIndex.clear () ;
		// To avoid memory re-allocation at push_back(), alloc the total size now
		group->_faceVertexIndex.reserve (group->_faces.size () * 3) ; // We only have triangles
		std::vector<GLFace>::iterator it =group->_faces.begin () ;
		for ( ; it != group->_faces.end () ; it++ ) {
			std::vector<GLFaceEltDef>::iterator itdef =(*it)._def.begin () ;
			for ( ; itdef != (*it)._def.end () ; itdef++ ) {
				NSString *pairName =[NSString stringWithFormat:@"%u/%u",
									 (*itdef)._vertex,
									 ((*itdef)._tex == (GLuint)-1 ? 0 : (*itdef)._tex)] ;
				//GLuint index =(GLuint)[pairs indexOfObject:pairName] ; // Way too slow
				GLuint index =(GLuint)[[pairsIndex objectForKey:pairName] unsignedLongValue] ;
				group->_faceVertexIndex.push_back (index) ;
			}

			[self parseProgress:(0.54 + 0.31 * ((double)i++ / nb)) progress:progress] ;
		}
		group->_faces.clear () ;
	}
	[self parseProgress:0.85 progress:progress] ;

	_geometry->_fileVertices.clear () ;
	_geometry->_fileNormals.clear () ;
	_geometry->_fileTexCoords.clear () ;
	return (YES) ;
}

- (BOOL)parseObj:(NSString *)progress {
	if ( _projectFiles == nil )
		_projectFiles =[AdskObjParser unzipProject:_objFilepath] ;
	
	NSDate *methodStart =[NSDate date] ;
	[self parseProgress:0.05 progress:progress] ;
	// Counting vertex, texture vertex, and faces prior allocating from file does not seems to help on the performance
	std::stringstream objIn ((char *)((NSData *)[_projectFiles objectForKey:@"mesh.obj"]).bytes) ;
	unsigned long v =0, vt =0, f =0, nb =0 ;
	while ( objIn ) {
        char c =objIn.get () ;
        if ( c == 'v' ) {
            if ( (c =objIn.get ()) == ' ' )
                v++ ;
            else if ( c == 't' )
                vt++ ;
        } else if ( c == 'f' ) {
            if ( (c = objIn.get ()) == ' ' )
                f++ ;
        }
        objIn.ignore (MAX_LINE_LENGTH, '\n') ;
		nb++ ;
    }
	_geometry->_fileVertices.reserve (v) ;
	_geometry->_fileNormals.reserve (vt) ;
	_geometry->_fileTexCoords.reserve (f) ;
	NSLog(@"exec time #1 = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;
	
	[self parseProgress:0.5 progress:progress] ;
	unsigned long i =0 ;
	std::string st ;
	objIn.clear () ;
	objIn.seekg (0, std::ios::beg) ;
	while ( objIn ) {
		//std::string token ;
		//objIn >> token ;
		//objIn.ignore (MAX_LINE_LENGTH, '\n') ;
		//NSLog(@"%s", token.c_str ()) ;
		
		//NSString *command =[NSString stringWithFormat:@"parseObj_%s:line:", token.c_str ()] ;
		//SEL cmd =NSSelectorFromString (command) ;
		//if ( cmd != nil && [self respondsToSelector:cmd] )
		//	[self performSelector:cmd withObject:nil] ;
		
		getline (objIn, st) ;
		st.erase (std::remove (st.begin (), st.end (), '\r'), st.end ()) ;
		if ( st.length () == 0 || st [0] == '#' )
			continue ;
		std::istringstream split (st) ;
		std::vector<std::string> tokens ;
		for ( std::string each ; std::getline (split, each, ' ') ; tokens.push_back (each) ) ;
		
		if ( tokens [0] == "f" ) {
			[self parseObj_f:tokens] ;
		} else if ( tokens [0] == "v" ) {
			[self parseObj_v:tokens] ;
		} else if ( tokens [0] == "vt" ) {
			[self parseObj_vt:tokens] ;
		} else if ( tokens [0] == "vn" ) {
			[self parseObj_vn:tokens] ;
		} else if ( tokens [0] == "vp" ) {
			[self parseObj_vp:tokens] ;
		} else if ( tokens [0] == "g" ) {
			[self parseObj_g:tokens] ;
		} else if ( tokens [0] == "mtllib" ) {
			[self parseObj_mtllib:tokens] ;
		} else if ( tokens [0] == "usemtl" ) {
			[self parseObj_usemtl:tokens] ;
		} else {
			NSMutableArray *tokens =[[NSMutableArray alloc] init] ;
			for ( std::string each ; std::getline (split, each, ' ') ; [tokens addObject:[[NSString alloc] initWithUTF8String:each.c_str ()]]) ;
			
			NSString *command =[NSString stringWithFormat:@"parseObj_%@:line:", [tokens objectAtIndex:0]] ;
			SEL cmd =NSSelectorFromString (command) ;
			if ( cmd != nil && [self respondsToSelector:cmd] )
				[self performSelector:cmd withObject:tokens withObject:nil] ;
		}
		
		[self parseProgress:(0.05 + 0.28 * ((double)i++ / nb)) progress:progress] ;
    }
	NSLog(@"exec time #2 = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;
	NSLog(@"%lu %ld", v, _geometry->_fileVertices.size ()) ; // exec time #2 reference = 0.902266
	
	// Now we parsed the file, we need to process some data like the face' vertices index and textures
	//[self loadTextures] ;
	[self parseProgress:0.33 progress:progress] ;
	
	// Missing normal? todo
	
	// Split Quads into triangles and create v/vt uniq pair list
	std::vector<GLFace> newFaces ;
	NSMutableSet *uniqPairs =[NSMutableSet set] ;
	NSArray *groups =[_groups allKeys] ;
	nb =1 ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		nb +=group->_faces.size () ;
	}
	i =0 ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		std::vector<GLFace>::iterator it =group->_faces.begin () ;
		for ( ; it != group->_faces.end () ; it++ ) {
			// Create vertex/tex pairs list
			std::vector<GLFaceEltDef>::iterator itdef =(*it)._def.begin () ;
			for ( ; itdef != (*it)._def.end () ; itdef++ ) {
				NSString *pairName =[NSString stringWithFormat:@"%u/%u",
									 (*itdef)._vertex,
									 ((*itdef)._tex == (GLuint)-1 ? 0 : (*itdef)._tex)] ;
				//NSLog(@"%@", pairName) ;
				[uniqPairs addObject:pairName] ;
			}
			// Split quads into triangles
			if ( (*it)._def.size () == 4 ) { // a quad
				GLFace glface ;
				glface._def.push_back ((*it)._def [0]) ;
				glface._def.push_back ((*it)._def [2]) ;
				glface._def.push_back ((*it)._def [3]) ;
				(*it)._def.pop_back () ;
				//[group AddFace:glface] ; // push_back() invalidates iterators
				newFaces.push_back (glface) ;
			} else if ( (*it)._def.size () > 4 ) {
				NSLog(@"%@", @"Face needs to be triangulated!") ;
			}
		}
		group->_faces.insert (group->_faces.end (), newFaces.begin (), newFaces.end ()) ;
		
		[self parseProgress:(0.33 + 0.18 * ((double)i++ / nb)) progress:progress] ;
	}
	[self parseProgress:0.51 progress:progress] ;
	NSLog(@"exec time #3 = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;
	
	// Build OpenGL vertex / tex arrays
	GLuint nbPairs =(GLuint)[uniqPairs count] ;
	_geometry->_vertices.reserve (nbPairs) ;
	_geometry->_texCoords.reserve (nbPairs) ;
	NSArray *pairs =[uniqPairs allObjects] ;
	NSMutableDictionary *pairsIndex =[[NSMutableDictionary alloc] init] ;
	for ( GLuint index =0 ; index < nbPairs ; index++ ) {
		NSString *pairName =[pairs objectAtIndex:index] ;
		[pairsIndex setObject:[NSNumber numberWithUnsignedLong:index] forKey:pairName] ;
		NSArray *def =[pairName componentsSeparatedByString:@"/"] ;
		_geometry->_vertices [index] =_geometry->_fileVertices [[[def objectAtIndex:0] unsignedIntValue]] ;
		_geometry->_texCoords [index] =_geometry->_fileTexCoords [[[def objectAtIndex:1] unsignedIntValue]] ;
		
		[self parseProgress:(0.51 + 0.03 * ((double)index / nbPairs)) progress:progress] ;
	}
	NSLog(@"exec time #4 = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;
	// Build OpenGL face array
	i =0 ;
	for ( NSString *grpName in groups ) {
		AdskObjGroup *group =[_groups objectForKey:grpName] ;
		group->_faceVertexIndex.clear () ;
		// To avoid memory re-allocation at push_back(), alloc the total size now
		group->_faceVertexIndex.reserve (group->_faces.size () * 3) ; // We only have triangles
		std::vector<GLFace>::iterator it =group->_faces.begin () ;
		for ( ; it != group->_faces.end () ; it++ ) {
			std::vector<GLFaceEltDef>::iterator itdef =(*it)._def.begin () ;
			for ( ; itdef != (*it)._def.end () ; itdef++ ) {
				NSString *pairName =[NSString stringWithFormat:@"%u/%u",
									 (*itdef)._vertex,
									 ((*itdef)._tex == (GLuint)-1 ? 0 : (*itdef)._tex)] ;
				//GLuint index =(GLuint)[pairs indexOfObject:pairName] ; // Way too slow
				GLuint index =(GLuint)[[pairsIndex objectForKey:pairName] unsignedLongValue] ;
				group->_faceVertexIndex.push_back (index) ;
			}
			
			[self parseProgress:(0.54 + 0.31 * ((double)i++ / nb)) progress:progress] ;
		}
		group->_faces.clear () ;
	}
	NSLog(@"exec time #5 = %f", [[NSDate date] timeIntervalSinceDate:methodStart]) ; methodStart =[NSDate date] ;
	[self parseProgress:0.85 progress:progress] ;
	
	_geometry->_fileVertices.clear () ;
	_geometry->_fileNormals.clear () ;
	_geometry->_fileTexCoords.clear () ;
	return (YES) ;
}

// http://en.wikipedia.org/wiki/Wavefront_.obj_file

- (BOOL)parseObj_g:(NSArray *)items line:(NSString *)line {
	_currentGroup =[NSString stringWithString:[items objectAtIndex:1]] ;
	if ( ![_groups objectForKey:_currentGroup] ) {
		AdskObjGroup *grp =[[AdskObjGroup alloc] init] ;
		[_groups setObject:grp forKey:_currentGroup] ;
		grp =nil ;
	}
	return (YES) ;
}

- (BOOL)parseObj_g:(std::vector<std::string> &)items {
	_currentGroup =[[NSString alloc] initWithUTF8String:items [1].c_str ()] ;
	if ( ![_groups objectForKey:_currentGroup] ) {
		AdskObjGroup *grp =[[AdskObjGroup alloc] init] ;
		[_groups setObject:grp forKey:_currentGroup] ;
		grp =nil ;
	}
	return (YES) ;
}

- (BOOL)parseObj_usemtl:(NSArray *)items line:(NSString *)line {
	if ( _currentGroup == nil || [_currentGroup isEqualToString:@""] )
		[self parseObj_g:[NSArray arrayWithObjects:@"g", @"xx_default_xx", nil] line:@"g xx_default_xx"] ;
	AdskObjGroup *grp =[_groups objectForKey:_currentGroup] ;
	if ( grp->_material != nil ) {
		NSString *grpName =[NSString stringWithFormat:@"xx_default_xx_%lu", (unsigned long)[_materials count]] ;
		NSString *cmd =[NSString stringWithFormat:@"g %@", grpName] ;
		[self parseObj_g:[NSArray arrayWithObjects:@"g", grpName, nil] line:cmd] ;
		grp =[_groups objectForKey:_currentGroup] ;
	}
	_currentMaterial =[NSString stringWithString:[items objectAtIndex:1]] ;
	[grp SetMaterial:[_materials objectForKey:_currentMaterial]] ;
	return (YES) ;
}

- (BOOL)parseObj_usemtl:(std::vector<std::string> &)items {
	if ( _currentGroup == nil || [_currentGroup isEqualToString:@""] )
		[self parseObj_g:[NSArray arrayWithObjects:@"g", @"xx_default_xx", nil] line:@"g xx_default_xx"] ;
	AdskObjGroup *grp =[_groups objectForKey:_currentGroup] ;
	if ( grp->_material != nil ) {
		NSString *grpName =[NSString stringWithFormat:@"xx_default_xx_%lu", (unsigned long)[_materials count]] ;
		NSString *cmd =[NSString stringWithFormat:@"g %@", grpName] ;
		[self parseObj_g:[NSArray arrayWithObjects:@"g", grpName, nil] line:cmd] ;
		grp =[_groups objectForKey:_currentGroup] ;
	}
	_currentMaterial =[[NSString alloc] initWithUTF8String:items [1].c_str ()] ;
	[grp SetMaterial:[_materials objectForKey:_currentMaterial]] ;
	return (YES) ;
}

- (BOOL)parseObj_v:(NSArray *)items line:(NSString *)line {
	// List of Vertices, with (x, y, z[, w]) coordinates, w is optional and defaults to 1.0.
	GLVector3D pt =GLVector3DMake ([[items objectAtIndex:1] floatValue], [[items objectAtIndex:2] floatValue], [[items objectAtIndex:3] floatValue]) ;
	[_geometry AddObjVertex:pt] ;
	return (YES) ;
}

- (BOOL)parseObj_v:(std::vector<std::string> &)items {
	GLVector3D pt =GLVector3DMake (std::stof (items [1]), std::stof (items [2]), std::stof (items [3])) ;
	[_geometry AddObjVertex:pt] ;
	return (YES) ;
}

- (BOOL)parseObj_vn:(NSArray *)items line:(NSString *)line {
	// Normals in (x,y,z) form; normals might not be unit.
	GLVector3D vect =GLVector3DMake ([[items objectAtIndex:1] floatValue], [[items objectAtIndex:2] floatValue], [[items objectAtIndex:3] floatValue]) ;
	// todo normalizeNormals
	[_geometry AddObjNormal:vect] ;
	return (YES) ;
}

- (BOOL)parseObj_vn:(std::vector<std::string> &)items {
	// Normals in (x,y,z) form; normals might not be unit.
	GLVector3D vect =GLVector3DMake (std::stof (items [1]), std::stof (items [2]), std::stof (items [3])) ;
	// todo normalizeNormals
	[_geometry AddObjNormal:vect] ;
	return (YES) ;
}

- (BOOL)parseObj_vt:(NSArray *)items line:(NSString *)line {
	// Texture coordinates, in (u ,v [,w]) coordinates, these will vary between 0 and 1, w is optional and default to 0.
	// In theory, we would need to flip image texture, but instead we flip the Texture V coordinates
	GLTexCoords coords =GLTexCoordsMake ([[items objectAtIndex:1] floatValue], 1.0f - [[items objectAtIndex:2] floatValue]) ;
	[_geometry AddObjTexCoords:coords] ;
	return (YES) ;
}

- (BOOL)parseObj_vt:(std::vector<std::string> &)items {
	// Texture coordinates, in (u ,v [,w]) coordinates, these will vary between 0 and 1, w is optional and default to 0.
	// In theory, we would need to flip image texture, but instead we flip the Texture V coordinates
	GLTexCoords coords =GLTexCoordsMake (std::stof (items [1]), 1.0f - std::stof (items [2])) ;
	[_geometry AddObjTexCoords:coords] ;
	return (YES) ;
}

- (BOOL)parseObj_vp:(NSArray *)items line:(NSString *)line {
	// Parameter space vertices in ( u [,v] [,w] ) form; free form geometry statement
	// todo
	return (YES) ;
}

- (BOOL)parseObj_vp:(std::vector<std::string> &)items {
	// Parameter space vertices in ( u [,v] [,w] ) form; free form geometry statement
	// todo
	return (YES) ;
}

- (BOOL)parseObj_f:(NSArray *)items line:(NSString *)line {
	if ( _currentGroup == nil || [_currentGroup isEqualToString:@""] )
		[self parseObj_g:[NSArray arrayWithObjects:@"g", @"xx_default_xx", nil] line:@"g xx_default_xx"] ;
	// A valid vertex index starts from 1 and matches the corresponding vertex elements of a previously defined vertex list.
	// Each face can contain three or more vertices.
	// Optionally, texture coordinate indices can be used to specify texture coordinates when defining a face.
	// As texture coordinates are optional, one can define geometry without them, but one must put two slashes after the
	// vertex index before putting the normal index.
	// I.e.  f  Vertex/[Texture-Coordinate]/Vertext_Normal
	GLFace glface ;
	unsigned long nb =[items count] ;
	for ( unsigned long i =1 ; i < nb ; i++ ) {
		NSString *face =items [i] ;
		NSArray *def =[face componentsSeparatedByString:@"/"] ;
		GLFaceEltDef glfaceElt ;
		switch ( [def count] ) { // 0 means not defined since indices start at index 1
			case 1:
				glfaceElt =GLFaceEltDefMake ([[def objectAtIndex:0] unsignedIntValue] - 1, -1, -1) ;
				break ;
			case 2:
				glfaceElt =GLFaceEltDefMake ([[def objectAtIndex:0] unsignedIntValue] - 1, [[def objectAtIndex:1] unsignedIntValue] - 1, -1) ;
				break ;
			case 3:
				glfaceElt =GLFaceEltDefMake ([[def objectAtIndex:0] unsignedIntValue] - 1, [[def objectAtIndex:1] unsignedIntValue] - 1, [[def objectAtIndex:2] unsignedIntValue] - 1) ;
				break ;
		}
		glface._def.push_back (glfaceElt) ;
		//NSLog(@"%@ -> %u %u -> ", face, glfaceElt._vertex, glfaceElt._tex) ;
	}
	[[_groups objectForKey:_currentGroup] AddFace:glface] ;
	return (YES) ;
}

- (BOOL)parseObj_f:(std::vector<std::string> &)items {
	if ( _currentGroup == nil || [_currentGroup isEqualToString:@""] )
		[self parseObj_g:[NSArray arrayWithObjects:@"g", @"xx_default_xx", nil] line:@"g xx_default_xx"] ;
	// A valid vertex index starts from 1 and matches the corresponding vertex elements of a previously defined vertex list.
	// Each face can contain three or more vertices.
	// Optionally, texture coordinate indices can be used to specify texture coordinates when defining a face.
	// As texture coordinates are optional, one can define geometry without them, but one must put two slashes after the
	// vertex index before putting the normal index.
	// I.e.  f  Vertex/[Texture-Coordinate]/Vertext_Normal
	GLFace glface ;
	unsigned long nb =items.size () ;
	for ( unsigned long i =1 ; i < nb ; i++ ) {
		std::istringstream split (items [i]) ;
		std::vector<std::string> def ;
		for ( std::string each ; std::getline (split, each, '/') ; def.push_back (each) ) ;
		GLFaceEltDef glfaceElt ;
		switch ( def.size () ) { // 0 means not defined since indices start at index 1
			case 1:
				glfaceElt =GLFaceEltDefMake (std::stoul (def [0]) - 1, -1, -1) ;
				break ;
			case 2:
				glfaceElt =GLFaceEltDefMake (std::stoul (def [0]) - 1, std::stoul (def [1]) - 1, -1) ;
				break ;
			case 3:
				glfaceElt =GLFaceEltDefMake (std::stoul (def [0]) - 1, std::stoul (def [1]) - 1, std::stoul (def [2]) - 1) ;
				break ;
		}
		glface._def.push_back (glfaceElt) ;
		//NSLog(@"%@ -> %u %u -> ", face, glfaceElt._vertex, glfaceElt._tex) ;
	}
	[[_groups objectForKey:_currentGroup] AddFace:glface] ;
	return (YES) ;
}

// http://paulbourke.net/dataformats/mtl/

- (BOOL)parseObj_mtllib:(NSArray *)items line:(NSString *)line {
	[self parseMtl:[items objectAtIndex:1]] ;
	return (YES) ;
}

- (BOOL)parseObj_mtllib:(std::vector<std::string> &)items {
	[self parseMtl:[[NSString alloc] initWithUTF8String:items [1].c_str ()]] ;
	return (YES) ;
}

- (BOOL)parseMtl:(NSString *)mtl {
	NSString *objData =[[[NSString alloc] initWithData:[_projectFiles objectForKey:mtl] encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\r" withString:@""] ;
	NSArray *lines =[objData componentsSeparatedByString:@"\n"] ;
	for ( NSString *itLine in lines ) {
		NSString *line =[itLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
		if ( [line isEqualToString:@""] || [line hasPrefix:@"#"] )
			continue ;
		NSArray *items =[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ;
		NSString *command =[NSString stringWithFormat:@"parseMtl_%@:line:", [items objectAtIndex:0]] ;
		SEL cmd =NSSelectorFromString (command) ;
		if ( cmd != nil && [self respondsToSelector:cmd] )
			[self performSelector:cmd withObject:items withObject:line] ;
	}
	return (YES) ;
}

- (BOOL)parseMtl_newmtl:(NSArray *)items line:(NSString *)line {
	// Define a material
	_currentMaterial =[NSString stringWithString:[items objectAtIndex:1]] ;
	AdskObjMaterial *material =[[AdskObjMaterial alloc] init] ;
	[_materials setObject:material forKey:_currentMaterial] ;
	material =nil ;
	return (YES) ;
}

- (BOOL)parseMtl_Kd:(NSArray *)items line:(NSString *)line {
	// The diffuse color is declared using Kd. Color definitions are in RGB where each channel's value is between 0 and 1.
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_diffuse =GLColor3DMake ([[items objectAtIndex:1] floatValue], [[items objectAtIndex:2] floatValue], [[items objectAtIndex:3] floatValue], 1.0) ;
	return (YES) ;
}

- (BOOL)parseMtl_Ka:(NSArray *)items line:(NSString *)line {
	// The ambient color of the material is declared using Ka. Color definitions are in RGB where each channel's value is between 0 and 1.
	if ( [[items objectAtIndex:1] isEqual:@"spectral"] ) // Ignore (todo)
		return (YES) ;
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_ambient =GLColor3DMake ([[items objectAtIndex:1] floatValue], [[items objectAtIndex:2] floatValue], [[items objectAtIndex:3] floatValue], 1.0) ;
	return (YES) ;
}

- (BOOL)parseMtl_Ks:(NSArray *)items line:(NSString *)line {
	// The specular color is declared using Ks, and weighted using the specular coefficient Ns.
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_specular =GLColor3DMake ([[items objectAtIndex:1] floatValue], [[items objectAtIndex:2] floatValue], [[items objectAtIndex:3] floatValue], 1.0) ;
	return (YES) ;
}

- (BOOL)parseMtl_Ns:(NSArray *)items line:(NSString *)line {
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_shininess =[[items objectAtIndex:1] floatValue] ;
	return (YES) ;
}

- (BOOL)parseMtl_d:(NSArray *)items line:(NSString *)line {
	// Materials can be transparent. This is referred to as being dissolved. Unlike real transparency,
	// the result does not depend upon the thickness of the object.
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_transparency =[[items objectAtIndex:1] floatValue] ;
	return (YES) ;
}

- (BOOL)parseMtl_Tr:(NSArray *)items line:(NSString *)line {
	return ([self parseMtl_d:items line:line]) ;
}

- (BOOL)parseMtl_illum:(NSArray *)items line:(NSString *)line {
	// Multiple illumination models are available, per material. These are enumerated as follows:
	// 0.  Color on and Ambient off
	// 1.  Color on and Ambient on
	// 2.  Highlight on
	// 3.  Reflection on and Ray trace on
	// 4.  Transparency: Glass on, Reflection: Ray trace on
	// 5.  Reflection: Fresnel on and Ray trace on
	// 6.  Transparency: Refraction on, Reflection: Fresnel off and Ray trace on
	// 7.  Transparency: Refraction on, Reflection: Fresnel on and Ray trace on
	// 8.  Reflection on and Ray trace off
	// 9.  Transparency: Glass on, Reflection: Ray trace off
	// 10. Casts shadows onto invisible surfaces
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_illum =[[items objectAtIndex:1] unsignedIntValue] ;
	return (YES) ;
}

- (BOOL)parseMtl_map_Kd:(NSArray *)items line:(NSString *)line {
	AdskObjMaterial *material =[_materials objectForKey:_currentMaterial] ;
	material->_textureFilepath =[items objectAtIndex:1] ;
	//material->_textureId =[self loadTexture:material->_textureFilepath width:-1 height:-1] ;
	return (YES) ;
}

+ (UIImage *)flipImageVertically:(UIImage *)originalImage {
/*	UIImageView *tempImageView =[[UIImageView alloc] initWithImage:originalImage] ;
	UIGraphicsBeginImageContext (tempImageView.frame.size) ;
	CGContextRef context =UIGraphicsGetCurrentContext () ;
	CGAffineTransform flipVertical =CGAffineTransformMake (1, 0, 0, -1, 0, tempImageView.frame.size.height) ;
	CGContextConcatCTM (context, flipVertical) ;
	[tempImageView.layer renderInContext:context] ;
	UIImage *flippedImage =UIGraphicsGetImageFromCurrentImageContext () ; // is autoreleased
	UIGraphicsEndImageContext () ;
	return (flippedImage) ;
*/
    CGSize size = originalImage.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[originalImage CGImage] scale:1.0 orientation:YES ? UIImageOrientationRight : UIImageOrientationLeft] drawInRect:CGRectMake(0,0,size.height ,size.width)];
    UIImage* flippedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return flippedImage;
}

- (BOOL)loadTexture:(GLuint)texture texFileName:(NSString *)texFileName width:(int)width height:(int)height {
	NSString *extension =[texFileName pathExtension] ;
	NSData *texData =[_projectFiles objectForKey:texFileName] ;
	
	// Assumes pvr4 is RGB not RGBA, which is how texturetool generates them
	if ( [extension isEqualToString:@"pvr4"] ) {
		glCompressedTexImage2D (GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, width, height, 0, (width * height) / 2, [texData bytes]) ;
		return (YES) ;
	}
	if ( [extension isEqualToString:@"pvr2"] ) {
		glCompressedTexImage2D (GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG, width, height, 0, (width * height) / 2, [texData bytes]) ;
		return (YES) ;
	}
	//if ( ![extension isEqualToString:@"png"] ) {
	//	UIImage *image =[[UIImage alloc] initWithData:texData] ;
	//	if ( image == nil )
	//		return (NO) ;
	//	//texData =UIImagePNGRepresentation (image) ;
	//}

	// .png or other like jpg
	UIImage *image =[[UIImage alloc] initWithData:texData] ;
	if ( image == nil )
		return (NO) ;
	// In theory, we should flip the image for OpenGL, but instead we flipped the texture V coordinates
	//image =[AdskObjParser flipImageVertically:image] ;
	
	width =(int)CGImageGetWidth (image.CGImage) ;
	height =(int)CGImageGetHeight (image.CGImage) ;
	CGColorSpaceRef colorSpace =CGColorSpaceCreateDeviceRGB () ;
	void *imageData =malloc (height * width * 4) ;
	CGContextRef context =CGBitmapContextCreate (imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big) ;
	CGColorSpaceRelease (colorSpace) ;
	CGContextClearRect (context, CGRectMake (0, 0, width, height)) ;
	CGContextDrawImage (context, CGRectMake (0, 0, width, height), image.CGImage) ;
	
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData) ;
	//glGenerateMipmapEXT (GL_TEXTURE_2D) ; //Generate mipmaps now!!!
	//GLuint errorcode =glGetError () ;
	CGContextRelease (context) ;
	
	free(imageData) ;
	return (YES) ;
}

- (void)loadTextures {
	int count =0, count2 =0 ;
	NSArray *materials =[_materials allKeys] ;
	for ( NSString *matName in materials ) {
		AdskObjMaterial *material =[_materials objectForKey:matName] ;
		if ( material->_textureFilepath != nil && ![material->_textureFilepath isEqualToString:@""] ) {
			count +=(material->_textureId == 0 ? 1 : 0) ;
			count2++ ;
		}
	}
	if ( count == 0 )
		return ;
	count =count2 ;
	
	[self destroyTextures] ;
	
	glEnable (GL_TEXTURE_2D) ;
	//glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) ;
	GLuint *textures =new GLuint [count] ;
	glGenTextures (count, textures) ;
	
	count =0 ;
	for ( NSString *matName in materials ) {
		AdskObjMaterial *material =[_materials objectForKey:matName] ;
		if ( material->_textureFilepath != nil && ![material->_textureFilepath isEqualToString:@""] ) {
			glBindTexture (GL_TEXTURE_2D, textures [count]) ;
			
			//glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT_OES) ;
			//glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT_OES) ;
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR) ;
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR) ;
			glBlendFunc (GL_ONE, GL_SRC_COLOR) ;
			
			material->_textureId =textures [count] ;
			[self loadTexture:material->_textureId texFileName:material->_textureFilepath width:-1 height:-1] ;
			
			count++ ;
		}
	}
	
	delete [] textures ;
}

- (void)destroyTextures {
	std::vector<GLuint> textures ;
	NSArray *materials =[_materials allKeys] ;
	for ( NSString *matName in materials ) {
		AdskObjMaterial *material =[_materials objectForKey:matName] ;
		if ( material->_textureId )
			textures.push_back (material->_textureId) ;
		material->_textureId =0 ;
	}
	if ( textures.size () == 0 )
		return ;
	glDeleteTextures ((GLsizei)textures.size (), textures.data ()) ;
}

@end
